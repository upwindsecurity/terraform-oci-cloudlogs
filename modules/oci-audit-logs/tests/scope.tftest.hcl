# Plan-only checks of scope_type, included_compartment_ids and included_compartment_ids_without_subcompartments against a
# mocked tree:
#
#   tenancy
#   ├── a
#   │   ├── a1
#   │   │   └── a1x
#   │   └── a2
#   └── b

mock_provider "oci" {}

mock_provider "oci" {
  alias = "home_region"
}

mock_provider "time" {}

override_data {
  target = data.oci_identity_compartments.all
  values = {
    compartments = [
      { id = "ocid1.compartment.oc1..a", compartment_id = "ocid1.tenancy.oc1..t" },
      { id = "ocid1.compartment.oc1..a1", compartment_id = "ocid1.compartment.oc1..a" },
      { id = "ocid1.compartment.oc1..a1x", compartment_id = "ocid1.compartment.oc1..a1" },
      { id = "ocid1.compartment.oc1..a2", compartment_id = "ocid1.compartment.oc1..a" },
      { id = "ocid1.compartment.oc1..b", compartment_id = "ocid1.tenancy.oc1..t" },
    ]
  }
}

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
  enable_audit_logs         = true
}

run "tenancy_whole" {
  command = plan

  variables {
    enable_identity_logs = true
  }

  assert {
    condition = [for s in oci_sch_service_connector.audit[0].source[0].log_sources : { compartment_id = s.compartment_id, log_group_id = s.log_group_id }] == [
      { compartment_id = "ocid1.tenancy.oc1..t", log_group_id = "_Audit_Include_Subcompartment" },
    ]
    error_message = "TENANCY without listed compartments reads the whole tenancy."
  }

  assert {
    condition     = oci_sch_service_connector.audit[0].tasks[0].condition == "type = 'com.oraclecloud.*'"
    error_message = "With audit and identity logs, the filter only drops Kubernetes API-server events."
  }
}

run "tenancy_with_subcompartments" {
  command = plan

  variables {
    included_compartment_ids = ["ocid1.compartment.oc1..a"]
  }

  assert {
    condition = [for s in oci_sch_service_connector.audit[0].source[0].log_sources : { compartment_id = s.compartment_id, log_group_id = s.log_group_id }] == [
      { compartment_id = "ocid1.tenancy.oc1..t", log_group_id = "_Audit" },
      { compartment_id = "ocid1.compartment.oc1..a", log_group_id = "_Audit_Include_Subcompartment" },
    ]
    error_message = "TENANCY with listed compartments reads the root alone plus each subtree."
  }
}

run "tenancy_without_subcompartments" {
  command = plan

  variables {
    included_compartment_ids_without_subcompartments = ["ocid1.compartment.oc1..a"]
  }

  assert {
    condition = [for s in oci_sch_service_connector.audit[0].source[0].log_sources : { compartment_id = s.compartment_id, log_group_id = s.log_group_id }] == [
      { compartment_id = "ocid1.tenancy.oc1..t", log_group_id = "_Audit" },
      { compartment_id = "ocid1.compartment.oc1..a", log_group_id = "_Audit" },
    ]
    error_message = "A compartment without children is read alone."
  }
}

run "tenancy_identity_only" {
  command = plan

  variables {
    enable_audit_logs    = false
    enable_identity_logs = true
  }

  assert {
    condition = [for s in oci_sch_service_connector.audit[0].source[0].log_sources : { compartment_id = s.compartment_id, log_group_id = s.log_group_id }] == [
      { compartment_id = "ocid1.tenancy.oc1..t", log_group_id = "_Audit_Include_Subcompartment" },
    ]
    error_message = "Identity-only still reads the scope's Audit."
  }

  assert {
    condition     = oci_sch_service_connector.audit[0].tasks[0].condition == "type = 'com.oraclecloud.*' and (type = 'com.oraclecloud.identitysignon.*' or type = 'com.oraclecloud.identitycontrolplane.*')"
    error_message = "Identity-only keeps identity event types only."
  }
}

run "compartment_mixed" {
  command = plan

  variables {
    scope_type                                       = "COMPARTMENT"
    included_compartment_ids                         = ["ocid1.compartment.oc1..a2", "ocid1.compartment.oc1..b"]
    included_compartment_ids_without_subcompartments = ["ocid1.compartment.oc1..a"]
  }

  assert {
    condition = [for s in oci_sch_service_connector.audit[0].source[0].log_sources : { compartment_id = s.compartment_id, log_group_id = s.log_group_id }] == [
      { compartment_id = "ocid1.compartment.oc1..a2", log_group_id = "_Audit_Include_Subcompartment" },
      { compartment_id = "ocid1.compartment.oc1..b", log_group_id = "_Audit_Include_Subcompartment" },
      { compartment_id = "ocid1.compartment.oc1..a", log_group_id = "_Audit" },
    ]
    error_message = "COMPARTMENT mixes subtrees and single compartments, without the root."
  }

  assert {
    condition     = strcontains(oci_sch_service_connector.audit[0].tasks[0].condition, " and not (type = 'com.oraclecloud.identitysignon.*'")
    error_message = "Audit without identity logs drops identity event types."
  }
}

run "duplicates_dropped" {
  command = plan

  variables {
    scope_type                                       = "COMPARTMENT"
    included_compartment_ids                         = ["ocid1.compartment.oc1..a", "ocid1.compartment.oc1..a1"]
    included_compartment_ids_without_subcompartments = ["ocid1.compartment.oc1..a1x"]
  }

  assert {
    condition = [for s in oci_sch_service_connector.audit[0].source[0].log_sources : { compartment_id = s.compartment_id, log_group_id = s.log_group_id }] == [
      { compartment_id = "ocid1.compartment.oc1..a", log_group_id = "_Audit_Include_Subcompartment" },
    ]
    error_message = "Compartments already under a listed subtree add no source."
  }
}

run "compartment_requires_a_list" {
  command = plan

  variables {
    scope_type = "COMPARTMENT"
  }

  expect_failures = [var.scope_type]
}

run "tenancy_not_includable_with_subcompartments" {
  command = plan

  variables {
    included_compartment_ids = ["ocid1.tenancy.oc1..t"]
  }

  expect_failures = [var.included_compartment_ids]
}

run "tenancy_only" {
  command = plan

  variables {
    included_compartment_ids_without_subcompartments = ["ocid1.tenancy.oc1..t"]
  }

  assert {
    condition = [for s in oci_sch_service_connector.audit[0].source[0].log_sources : { compartment_id = s.compartment_id, log_group_id = s.log_group_id }] == [
      { compartment_id = "ocid1.tenancy.oc1..t", log_group_id = "_Audit" },
    ]
    error_message = "The tenancy listed alone reads the root alone, once."
  }
}

run "tenancy_only_compartment_scope" {
  command = plan

  variables {
    scope_type                                       = "COMPARTMENT"
    included_compartment_ids_without_subcompartments = ["ocid1.tenancy.oc1..t"]
  }

  assert {
    condition = [for s in oci_sch_service_connector.audit[0].source[0].log_sources : { compartment_id = s.compartment_id, log_group_id = s.log_group_id }] == [
      { compartment_id = "ocid1.tenancy.oc1..t", log_group_id = "_Audit" },
    ]
    error_message = "COMPARTMENT with the tenancy listed reads the root alone."
  }
}

run "tenancy_and_a_compartment_without_subcompartments" {
  command = plan

  variables {
    included_compartment_ids_without_subcompartments = ["ocid1.tenancy.oc1..t", "ocid1.compartment.oc1..a"]
  }

  assert {
    condition = [for s in oci_sch_service_connector.audit[0].source[0].log_sources : { compartment_id = s.compartment_id, log_group_id = s.log_group_id }] == [
      { compartment_id = "ocid1.tenancy.oc1..t", log_group_id = "_Audit" },
      { compartment_id = "ocid1.compartment.oc1..a", log_group_id = "_Audit" },
    ]
    error_message = "The tenancy and a compartment read the root and the compartment alone, each once."
  }
}

run "another_tenancy_not_listable" {
  command = plan

  variables {
    included_compartment_ids_without_subcompartments = ["ocid1.tenancy.oc1..other"]
  }

  expect_failures = [var.included_compartment_ids_without_subcompartments]
}

run "same_compartment_in_both_lists" {
  command = plan

  variables {
    included_compartment_ids                         = ["ocid1.compartment.oc1..a"]
    included_compartment_ids_without_subcompartments = ["ocid1.compartment.oc1..a"]
  }

  expect_failures = [var.included_compartment_ids_without_subcompartments]
}
