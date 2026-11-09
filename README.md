# Upwind OCI Cloud Logs

[![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![GitHub Actions](https://img.shields.io/badge/github%20actions-%232671E5.svg?style=for-the-badge&logo=githubactions&logoColor=white)](https://github.com/features/actions)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg?style=for-the-badge)](https://opensource.org/licenses/Apache-2.0)

Terraform modules that send logs from an Oracle Cloud Infrastructure (OCI) tenancy to
[Upwind](https://www.upwind.io).

## Modules

- [modules/oci-audit-logs](./modules/oci-audit-logs/): OCI Audit logs, one pipeline per region. Upwind reads them as
  the log-reader group that [OCI onboarding](https://github.com/upwindsecurity/terraform-oci-onboarding) creates with
  `enable_cloudlogs = true`.

## Usage

```hcl
module "oci_audit_logs" {
  source  = "upwindsecurity/cloudlogs/oci//modules/oci-audit-logs"
  version = "~> 1.0"

  providers = {
    oci             = oci
    oci.home_region = oci
  }

  oci_tenancy_id            = "ocid1.tenancy.oc1..xxxx"
  oci_compartment_id        = "ocid1.tenancy.oc1..xxxx"
  upwind_cloudlogs_group_id = "ocid1.group.oc1..xxxx"

  enable_audit_logs    = true
  enable_identity_logs = true
}
```

See the [module README](./modules/oci-audit-logs/README.md) for prerequisites, inputs and outputs.

## Examples

- [examples/oci-audit-logs-basic](./examples/oci-audit-logs-basic/): one region with the defaults
- [examples/oci-audit-logs-complete](./examples/oci-audit-logs-complete/): selected compartments, a customer-managed key and tags
- [examples/oci-audit-logs-multi-region](./examples/oci-audit-logs-multi-region/): two regions sharing one home region

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md). For bug reports and feature requests, use
[GitHub Issues](https://github.com/upwindsecurity/terraform-oci-cloudlogs/issues).

## Versioning

Releases follow [Semantic Versioning](https://semver.org/). See the
[tags on this repository](https://github.com/upwindsecurity/terraform-oci-cloudlogs/tags).

## License

Apache License 2.0. See [LICENSE](LICENSE).
