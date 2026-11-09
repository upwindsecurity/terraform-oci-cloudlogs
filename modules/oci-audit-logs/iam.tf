# region iam

locals {
  # The log-reader group can pull from this stream and list and read the objects of this bucket only.
  logs_reader_permissions_list = [
    "Allow group id ${var.upwind_cloudlogs_group_id} to use stream-pull in compartment id ${var.oci_compartment_id} where target.stream.id = '${oci_streaming_stream.pointers.id}'",
    "Allow group id ${var.upwind_cloudlogs_group_id} to read objects in compartment id ${var.oci_compartment_id} where target.bucket.name = '${local.bucket_name}'",
  ]

  # Narrower than the Oracle Connector Hub reference's `manage objects`: the connector only writes new objects.
  connector_bucket_permissions_list = [
    "Allow any-user to {OBJECT_CREATE, OBJECT_INSPECT, OBJECT_OVERWRITE} in compartment id ${var.oci_compartment_id} where all {request.principal.type='serviceconnector', target.bucket.name='${local.bucket_name}', request.principal.compartment.id='${var.oci_compartment_id}'}",
  ]

  # The Object Storage service principal is regional.
  bucket_lifecycle_permissions_list = var.enable_bucket_object_lifecycle ? [
    "Allow service objectstorage-${local.oci_region} to manage object-family in compartment id ${var.oci_compartment_id} where target.bucket.name='${local.bucket_name}'",
  ] : []

  bucket_cmk_key_compartment_id = coalesce(var.bucket_cmk_key_compartment_id, var.oci_compartment_id)

  # Object Storage decrypts on GetObject, so the log-reader group needs no grant on the key.
  bucket_cmk_permissions_list = var.enable_bucket_cmk ? [
    "Allow service objectstorage-${local.oci_region} to use keys in compartment id ${local.bucket_cmk_key_compartment_id} where target.key.id = '${local.bucket_cmk_key_id}'",
  ] : []

  policy_statements = concat(
    local.logs_reader_permissions_list,
    local.connector_bucket_permissions_list,
    local.bucket_lifecycle_permissions_list,
    local.bucket_cmk_permissions_list,
  )
}

# IAM resources can only be created in the home region. One policy per region, so each region adds one policy.
resource "oci_identity_policy" "this" {
  provider = oci.home_region

  compartment_id = var.oci_compartment_id
  name           = local.policy_name
  description    = "Allow Upwind to read the ${local.oci_region} logs bucket and stream, and OCI services to fill and expire the bucket"
  statements     = local.policy_statements
  freeform_tags  = local.common_tags
  defined_tags   = var.defined_tags

  lifecycle {
    # OCI's tag defaults add these after create; without this every plan would strip them.
    ignore_changes = [defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"]]

    precondition {
      condition     = local.oci_region != ""
      error_message = "Cannot find the region of pointer stream ${oci_streaming_stream.pointers.id} among the OCI regions."
    }
  }
}

# Recreated whenever the statements change, so a resource that needs a newly added statement, such as the bucket
# switching to a customer-managed key, waits for it too and not only on the first apply.
resource "time_sleep" "wait_for_policy" {
  create_duration = var.policy_propagation_wait

  triggers = {
    statements = sha1(join("\n", oci_identity_policy.this.statements))
  }
}

# endregion iam
