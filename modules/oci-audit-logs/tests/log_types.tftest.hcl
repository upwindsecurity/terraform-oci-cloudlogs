# Plan-only checks that every combination of log types gets the connector filter it needs.

mock_provider "oci" {}

mock_provider "oci" {
  alias = "home_region"
}

mock_provider "time" {}

override_data {
  target = data.oci_objectstorage_namespace.default
  values = {
    namespace = "ns"
  }
}

override_data {
  target = data.oci_identity_regions.all
  values = {
    regions = [
      { key = "IAD", name = "us-ashburn-1" },
      { key = "FRA", name = "eu-frankfurt-1" },
    ]
  }
}

override_resource {
  target = oci_streaming_stream.pointers
  values = {
    id = "ocid1.stream.oc1.iad.s"
  }
}

variables {
  oci_tenancy_id            = "ocid1.tenancy.oc1..t"
  oci_compartment_id        = "ocid1.compartment.oc1..b"
  resource_suffix           = "test01"
  upwind_cloudlogs_group_id = "ocid1.group.oc1..g"
}

run "audit_only" {
  command = plan

  variables {
    enable_audit_logs = true
  }

  assert {
    condition     = oci_sch_service_connector.audit[0].tasks[0].condition == "type = 'com.oraclecloud.*' and not (type = 'com.oraclecloud.identitysignon.*' or type = 'com.oraclecloud.identitycontrolplane.*')"
    error_message = "Audit alone drops identity event types."
  }

  assert {
    condition     = oci_sch_service_connector.audit[0].display_name == "upwind-audit-logs-connector-test01"
    error_message = "The connector carries the suffix."
  }

  assert {
    condition     = output.enabled_log_types == tolist(["AUDIT"])
    error_message = "enabled_log_types lists audit alone."
  }
}

run "identity_only" {
  command = plan

  variables {
    enable_identity_logs = true
  }

  assert {
    condition     = oci_sch_service_connector.audit[0].tasks[0].condition == "type = 'com.oraclecloud.*' and (type = 'com.oraclecloud.identitysignon.*' or type = 'com.oraclecloud.identitycontrolplane.*')"
    error_message = "Identity alone keeps identity event types only."
  }

  assert {
    condition     = output.enabled_log_types == tolist(["IDENTITY"])
    error_message = "enabled_log_types lists identity alone."
  }
}

run "audit_and_identity_with_exclusions" {
  command = plan

  variables {
    enable_audit_logs     = true
    enable_identity_logs  = true
    log_filter_exclusions = ["not (type = 'com.oraclecloud.identitycontrolplane.listapikeys')"]
  }

  assert {
    condition     = oci_sch_service_connector.audit[0].tasks[0].condition == "type = 'com.oraclecloud.*' and not (type = 'com.oraclecloud.identitycontrolplane.listapikeys')"
    error_message = "Audit with identity keeps every OCI event except the exclusions."
  }

  assert {
    condition     = output.enabled_log_types == tolist(["AUDIT", "IDENTITY"])
    error_message = "enabled_log_types lists both."
  }
}

run "no_log_type" {
  command = plan

  expect_failures = [oci_objectstorage_bucket.this]
}

run "compartment_identity_only" {
  command = plan

  variables {
    enable_identity_logs     = true
    scope_type               = "COMPARTMENT"
    included_compartment_ids = ["ocid1.compartment.oc1..b"]
  }

  assert {
    condition = [for s in oci_sch_service_connector.audit[0].source[0].log_sources : { compartment_id = s.compartment_id, log_group_id = s.log_group_id }] == [
      { compartment_id = "ocid1.compartment.oc1..b", log_group_id = "_Audit_Include_Subcompartment" },
    ]
    error_message = "A compartment scope reads its compartments' identity events, never the tenancy root."
  }

  assert {
    condition     = strcontains(oci_sch_service_connector.audit[0].tasks[0].condition, " and (type = 'com.oraclecloud.identitysignon.*'")
    error_message = "The Audit connector keeps identity event types only."
  }
}
