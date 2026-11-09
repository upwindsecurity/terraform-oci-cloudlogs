# Multi-Region Example

Creates one pipeline per region. Both calls take the same inputs apart from the region, create their own policy in the
home region, and grant the same log-reader group from OCI onboarding. Each region yields its own stream: one pipeline of
the same Upwind integration.

```hcl
module "home" {
  source    = "upwindsecurity/cloudlogs/oci//modules/oci-audit-logs"
  version   = "~> 1.0"
  providers = { oci = oci, oci.home_region = oci }
  # ...
}

module "secondary" {
  source    = "upwindsecurity/cloudlogs/oci//modules/oci-audit-logs"
  version   = "~> 1.0"
  providers = { oci = oci.secondary, oci.home_region = oci }
  # ...
}
```

<!-- BEGIN_TF_DOCS -->

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.0 |
| <a name="requirement_oci"></a> [oci](#requirement\_oci) | >= 8.22.0, < 9.0.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.10.0, < 1.0.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_home"></a> [home](#module\_home) | ../.. | n/a |
| <a name="module_secondary"></a> [secondary](#module\_secondary) | ../.. | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_oci_home_region"></a> [oci\_home\_region](#input\_oci\_home\_region) | The OCI home region of the tenancy. | `string` | `"us-ashburn-1"` | no |
| <a name="input_oci_secondary_region"></a> [oci\_secondary\_region](#input\_oci\_secondary\_region) | A second subscribed OCI region to collect logs from. | `string` | `"eu-frankfurt-1"` | no |
| <a name="input_oci_tenancy_id"></a> [oci\_tenancy\_id](#input\_oci\_tenancy\_id) | The OCI tenancy OCID. | `string` | n/a | yes |
| <a name="input_resource_suffix"></a> [resource\_suffix](#input\_resource\_suffix) | Optional suffix, up to 10 alphanumeric characters, appended to resource names. | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of freeform tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_upwind_cloudlogs_group_id"></a> [upwind\_cloudlogs\_group\_id](#input\_upwind\_cloudlogs\_group\_id) | The OCID of the log-reader group that OCI onboarding creates: the ocid of its federated\_cloudlogs\_group output. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_home_pointer_stream_name"></a> [home\_pointer\_stream\_name](#output\_home\_pointer\_stream\_name) | Name of the home-region pointer stream. |
| <a name="output_secondary_pointer_stream_name"></a> [secondary\_pointer\_stream\_name](#output\_secondary\_pointer\_stream\_name) | Name of the secondary-region pointer stream. |
<!-- END_TF_DOCS -->
