# Complete example: Audit and identity events, the customer's own bucket key,
# a compartment scope and custom tags.

# The home region is also the region of the pipeline in this example, so the
# same provider configuration serves both `oci` and `oci.home_region`.
provider "oci" {
  region = var.oci_region
}

module "oci_audit_logs" {
  source = "../../modules/oci-audit-logs"

  providers = {
    oci             = oci
    oci.home_region = oci
  }

  oci_tenancy_id            = var.oci_tenancy_id
  oci_compartment_id        = var.oci_tenancy_id
  upwind_cloudlogs_group_id = var.upwind_cloudlogs_group_id
  resource_suffix           = var.resource_suffix

  # Log types and scope
  enable_audit_logs                                = true
  enable_identity_logs                             = true
  scope_type                                       = var.scope_type
  included_compartment_ids                         = var.included_compartment_ids
  included_compartment_ids_without_subcompartments = var.included_compartment_ids_without_subcompartments

  # Bucket and stream tuning
  enable_bucket_cmk            = true
  bucket_cmk_key_id            = var.bucket_cmk_key_id
  bucket_object_lifecycle_days = 3
  stream_retention_in_hours    = 48

  # Tags
  tags         = var.tags
  defined_tags = var.defined_tags
}
