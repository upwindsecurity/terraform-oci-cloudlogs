# Multi-region example: one pipeline, with its own policy, per region.

# Home region: the IAM policies of every region are created here.
provider "oci" {
  region = var.oci_home_region
}

# Second region: another pipeline, granted to the same log-reader group.
provider "oci" {
  alias  = "secondary"
  region = var.oci_secondary_region
}

module "home" {
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

module "secondary" {
  source = "../../modules/oci-audit-logs"

  providers = {
    oci             = oci.secondary
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
