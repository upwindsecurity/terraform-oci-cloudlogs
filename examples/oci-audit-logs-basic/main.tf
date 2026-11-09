# Basic example: OCI Audit and identity events from one region.

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
  tags                      = var.tags

  enable_audit_logs    = true
  enable_identity_logs = true
}
