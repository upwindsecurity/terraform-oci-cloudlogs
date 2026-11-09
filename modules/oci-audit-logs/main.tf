# Routes OCI Audit events into a bucket, publishes a pointer per new object onto a stream, and grants the log-reader
# group from OCI onboarding read access to both. One call per region.

# region locals

locals {
  # Optional token appended to every resource name. Names already carry the
  # region where one is needed for uniqueness, so the suffix only matters when
  # a second independent installation has to coexist in the same tenancy.
  name_suffix = var.resource_suffix == "" ? "" : format("-%s", var.resource_suffix)

  # Freeform tags on every resource this module creates. The two markers are
  # merged last so a caller cannot drop them.
  common_tags = merge(var.tags, {
    managed_by = "terraform"
    component  = "upwind-oci-cloudlogs"
  })

  namespace = data.oci_objectstorage_namespace.default.namespace

  create_bucket_cmk_key = var.enable_bucket_cmk && var.bucket_cmk_key_id == ""
  bucket_cmk_key_id = !var.enable_bucket_cmk ? null : (
    var.bucket_cmk_key_id != "" ? var.bucket_cmk_key_id : oci_kms_key.bucket[0].id
  )

  # Resource names: the caller's base name when given, otherwise the default; the suffix is always appended.
  bucket_name       = format("%s%s", coalesce(var.bucket_name, "upwind-audit-logs"), local.name_suffix)
  connector_name    = format("%s%s", coalesce(var.connector_name, "upwind-audit-logs-connector"), local.name_suffix)
  events_rule_name  = format("%s%s", coalesce(var.events_rule_name, "upwind-audit-logs-new-file"), local.name_suffix)
  stream_name       = format("%s%s", coalesce(var.stream_name, "upwind-audit-logs-stream"), local.name_suffix)
  bucket_vault_name = format("%s%s", coalesce(var.bucket_vault_name, "upwind-audit-logs-bucket-vault"), local.name_suffix)
  bucket_key_name   = format("%s%s", coalesce(var.bucket_key_name, "upwind-audit-logs-bucket-key"), local.name_suffix)

  # Policy names are tenancy-wide, so the policy carries its region to stay apart from the other regions' ones.
  policy_name = format("%s-%s%s", coalesce(var.identity_policy_name, "upwind-audit-logs"), local.oci_region, local.name_suffix)

  # A stream OCID carries its region, as the short key (`iad`) or the full name: ocid1.stream.oc1.<region>.<id>.
  stream_ocid_region = lower(split(".", oci_streaming_stream.pointers.id)[3])
  stream_regions = [
    for r in data.oci_identity_regions.all.regions : r.name if lower(r.key) == local.stream_ocid_region || r.name == local.stream_ocid_region
  ]
  # Empty when no region matches; the policy's precondition reports it.
  oci_region = length(local.stream_regions) == 1 ? local.stream_regions[0] : ""

  audit_events_enabled = var.enable_audit_logs || var.enable_identity_logs

  log_types = compact([
    var.enable_audit_logs ? "AUDIT" : "",
    var.enable_identity_logs ? "IDENTITY" : "",
  ])

  # Keeps OCI service events only, which drops the Kubernetes API-server audit events that OCI Audit records for OKE
  # (`core.v1.*`, `io.k8s.*`, CRD groups).
  oci_service_events_only = "type = 'com.oraclecloud.*'"

  identity_event_types = "(type = 'com.oraclecloud.identitysignon.*' or type = 'com.oraclecloud.identitycontrolplane.*')"

  audit_event_types_filter = (
    var.enable_audit_logs && var.enable_identity_logs ? "" :
    var.enable_identity_logs ? local.identity_event_types :
    "not ${local.identity_event_types}"
  )

  audit_filter_condition = join(" and ", compact(concat(
    [local.oci_service_events_only, local.audit_event_types_filter],
    var.log_filter_exclusions,
  )))

  events_rule_condition = jsonencode({
    eventType = "com.oraclecloud.objectstorage.createobject"
    data = {
      additionalDetails = {
        bucketName = oci_objectstorage_bucket.this.name
      }
    }
  })
}

# endregion locals

# region data sources

data "oci_identity_regions" "all" {}

data "oci_objectstorage_namespace" "default" {
  compartment_id = var.oci_tenancy_id
}

# endregion data sources

# region bucket encryption key

# Optional, in the `oci` provider region: keys are regional, so each region that turns on bucket encryption has its own.
resource "oci_kms_vault" "bucket" {
  count = local.create_bucket_cmk_key ? 1 : 0

  compartment_id = var.oci_compartment_id
  display_name   = local.bucket_vault_name
  # Required for software-only keys
  vault_type    = "DEFAULT"
  freeform_tags = local.common_tags
  defined_tags  = var.defined_tags

  lifecycle {
    # OCI's tag defaults add these after create; without this every plan would strip them.
    ignore_changes = [defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"]]
  }

  timeouts {
    create = var.create_timeout
  }
}

# A new vault's management endpoint takes a while to appear in DNS, and
# creating the key against it too early fails with "no such host".
resource "time_sleep" "wait_for_bucket_vault" {
  count = local.create_bucket_cmk_key ? 1 : 0

  create_duration = var.vault_endpoint_wait

  depends_on = [oci_kms_vault.bucket]
}

resource "oci_kms_key" "bucket" {
  count = local.create_bucket_cmk_key ? 1 : 0

  compartment_id      = var.oci_compartment_id
  display_name        = local.bucket_key_name
  management_endpoint = oci_kms_vault.bucket[0].management_endpoint
  key_shape {
    algorithm = "AES"
    length    = 32
  }
  # Required for software-only keys
  protection_mode = "SOFTWARE"
  freeform_tags   = local.common_tags
  defined_tags    = var.defined_tags

  lifecycle {
    # OCI's tag defaults add these after create; without this every plan would strip them.
    ignore_changes = [defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"]]
  }

  timeouts {
    create = var.create_timeout
  }

  depends_on = [time_sleep.wait_for_bucket_vault]
}

# endregion bucket encryption key

# region bucket

resource "oci_objectstorage_bucket" "this" {
  compartment_id = var.oci_compartment_id
  namespace      = local.namespace
  name           = local.bucket_name

  access_type           = "NoPublicAccess"
  storage_tier          = "Standard"
  versioning            = "Disabled"
  object_events_enabled = true
  kms_key_id            = local.bucket_cmk_key_id

  freeform_tags = local.common_tags
  defined_tags  = var.defined_tags

  lifecycle {
    # OCI's tag defaults add these after create; without this every plan would strip them.
    ignore_changes = [defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"]]

    precondition {
      condition     = var.enable_audit_logs || var.enable_identity_logs
      error_message = "Enable at least one log type: enable_audit_logs or enable_identity_logs."
    }
  }

  depends_on = [time_sleep.wait_for_policy]
}

resource "oci_objectstorage_object_lifecycle_policy" "this" {
  count = var.enable_bucket_object_lifecycle ? 1 : 0

  namespace = local.namespace
  bucket    = oci_objectstorage_bucket.this.name

  rules {
    name        = "upwind-audit-logs-delete"
    action      = "DELETE"
    is_enabled  = true
    time_amount = var.bucket_object_lifecycle_days
    time_unit   = "DAYS"
  }

  depends_on = [time_sleep.wait_for_policy]
}

# endregion bucket

# region pointer stream

# No explicit stream pool: the stream uses the compartment's default pool.
resource "oci_streaming_stream" "pointers" {
  name           = local.stream_name
  compartment_id = var.oci_compartment_id

  partitions         = var.stream_partitions
  retention_in_hours = var.stream_retention_in_hours

  freeform_tags = local.common_tags
  defined_tags  = var.defined_tags

  lifecycle {
    # OCI's tag defaults add these after create; without this every plan would strip them.
    ignore_changes = [defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"]]
  }
}

# endregion pointer stream

# region connector hub

resource "oci_sch_service_connector" "audit" {
  count = local.audit_events_enabled ? 1 : 0

  compartment_id = var.oci_compartment_id
  display_name   = local.connector_name
  description    = "Routes OCI Audit events into the Upwind logs bucket"

  source {
    kind = "logging"

    dynamic "log_sources" {
      for_each = local.audit_log_sources
      content {
        compartment_id = log_sources.value.compartment_id
        log_group_id   = log_sources.value.log_group_id
      }
    }
  }

  # One log filter per connector, so every condition is joined into it.
  tasks {
    kind      = "logRule"
    condition = local.audit_filter_condition
  }

  target {
    kind = "objectStorage"

    namespace                  = local.namespace
    bucket                     = oci_objectstorage_bucket.this.name
    batch_rollover_size_in_mbs = var.service_connector_target_batch_size_in_mbs
    batch_rollover_time_in_ms  = var.service_connector_target_batch_time_in_ms
  }

  freeform_tags = local.common_tags
  defined_tags  = var.defined_tags

  lifecycle {
    # OCI's tag defaults add these after create; without this every plan would strip them.
    ignore_changes = [defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"]]
  }

  depends_on = [time_sleep.wait_for_policy]
}

# endregion connector hub

# region events rule

# One pointer message per object the connector writes.
resource "oci_events_rule" "new_object" {
  compartment_id = var.oci_compartment_id
  display_name   = local.events_rule_name
  description    = "Publishes a pointer onto the Upwind stream for every new log object"
  is_enabled     = true
  condition      = local.events_rule_condition

  actions {
    action {
      action_type = "OSS"
      is_enabled  = true
      description = "Route object creation to the Upwind pointer stream"
      stream_id   = oci_streaming_stream.pointers.id
    }
  }

  freeform_tags = local.common_tags
  defined_tags  = var.defined_tags

  lifecycle {
    # OCI's tag defaults add these after create; without this every plan would strip them.
    ignore_changes = [defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"]]
  }

  depends_on = [time_sleep.wait_for_policy]
}

# endregion events rule
