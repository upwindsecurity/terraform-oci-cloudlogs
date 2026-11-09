# Checks of the per-region IAM policy, applied against mocked providers: no tag, and every statement scoped to this
# region's resources.

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
  enable_audit_logs         = true
}

run "one_policy_per_region" {
  command = apply

  assert {
    condition     = oci_identity_policy.this.name == "upwind-audit-logs-us-ashburn-1-test01"
    error_message = "The policy is named after its region and suffix."
  }

  assert {
    condition     = oci_identity_policy.this.compartment_id == "ocid1.compartment.oc1..b"
    error_message = "The policy lives in the pipeline compartment."
  }

  assert {
    condition = slice(oci_identity_policy.this.statements, 0, 2) == tolist([
      "Allow group id ocid1.group.oc1..g to use stream-pull in compartment id ocid1.compartment.oc1..b where target.stream.id = 'ocid1.stream.oc1.iad.s'",
      "Allow group id ocid1.group.oc1..g to read objects in compartment id ocid1.compartment.oc1..b where target.bucket.name = 'upwind-audit-logs-test01'",
    ])
    error_message = "The log-reader group reads only this region's stream and bucket."
  }

  assert {
    condition     = contains(oci_identity_policy.this.statements, "Allow any-user to {OBJECT_CREATE, OBJECT_INSPECT, OBJECT_OVERWRITE} in compartment id ocid1.compartment.oc1..b where all {request.principal.type='serviceconnector', target.bucket.name='upwind-audit-logs-test01', request.principal.compartment.id='ocid1.compartment.oc1..b'}")
    error_message = "Connector Hub can only write objects to this bucket."
  }

  assert {
    condition     = length(oci_identity_policy.this.statements) == 4
    error_message = "Reader, connector and lifecycle statements share the one policy."
  }

  assert {
    condition     = alltrue([for s in oci_identity_policy.this.statements : !strcontains(s, "tag.")])
    error_message = "No statement matches on a tag."
  }
}

run "customer_managed_key" {
  command = apply

  variables {
    enable_bucket_cmk = true
    bucket_cmk_key_id = "ocid1.key.oc1.iad.k"
  }

  assert {
    condition     = length(oci_identity_policy.this.statements) == 5
    error_message = "The key statement joins the same policy."
  }

  assert {
    condition     = alltrue([for s in oci_identity_policy.this.statements : !(strcontains(s, "Allow group") && strcontains(s, "use keys"))])
    error_message = "The log-reader group gets no grant on the key."
  }
}

run "region_from_a_full_name_ocid" {
  command   = apply
  state_key = "full_name_ocid"

  override_resource {
    target = oci_streaming_stream.pointers
    values = {
      id = "ocid1.stream.oc1.eu-frankfurt-1.s"
    }
  }

  assert {
    condition     = oci_identity_policy.this.name == "upwind-audit-logs-eu-frankfurt-1-test01"
    error_message = "The region comes from the stream OCID, by name as well as by key."
  }

  assert {
    condition     = contains(oci_identity_policy.this.statements, "Allow service objectstorage-eu-frankfurt-1 to manage object-family in compartment id ocid1.compartment.oc1..b where target.bucket.name='upwind-audit-logs-test01'")
    error_message = "The lifecycle statement names the stream's region."
  }
}

run "customer_managed_key_in_another_compartment" {
  command   = apply
  state_key = "key_compartment"

  variables {
    enable_bucket_cmk             = true
    bucket_cmk_key_id             = "ocid1.key.oc1.iad.k"
    bucket_cmk_key_compartment_id = "ocid1.compartment.oc1..k"
  }

  assert {
    condition = length([
      for s in oci_identity_policy.this.statements : s if strcontains(s, "use keys in compartment id ocid1.compartment.oc1..k ")
    ]) == 1
    error_message = "The key statement names the key's compartment."
  }

  assert {
    condition     = contains(oci_identity_policy.this.statements, "Allow group id ocid1.group.oc1..g to read objects in compartment id ocid1.compartment.oc1..b where target.bucket.name = 'upwind-audit-logs-test01'")
    error_message = "The other statements keep the pipeline compartment."
  }
}

run "key_compartment_requires_a_key" {
  command = plan

  variables {
    bucket_cmk_key_compartment_id = "ocid1.compartment.oc1..k"
  }

  expect_failures = [var.bucket_cmk_key_compartment_id]
}

run "unknown_stream_region" {
  command   = apply
  state_key = "unknown_region"

  override_resource {
    target = oci_streaming_stream.pointers
    values = {
      id = "ocid1.stream.oc1.xyz.s"
    }
  }

  expect_failures = [oci_identity_policy.this]
}
