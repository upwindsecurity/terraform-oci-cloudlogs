# Basic Example

Collects OCI Audit logs and identity sign-on events from the tenancy home region and grants Upwind read access to the
region's bucket and stream.

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
| <a name="module_oci_audit_logs"></a> [oci\_audit\_logs](#module\_oci\_audit\_logs) | ../.. | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_oci_region"></a> [oci\_region](#input\_oci\_region) | The OCI home region, where the pipeline is created. | `string` | `"us-ashburn-1"` | no |
| <a name="input_oci_tenancy_id"></a> [oci\_tenancy\_id](#input\_oci\_tenancy\_id) | The OCI tenancy OCID. | `string` | n/a | yes |
| <a name="input_resource_suffix"></a> [resource\_suffix](#input\_resource\_suffix) | Optional suffix, up to 10 alphanumeric characters, appended to resource names. | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of freeform tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_upwind_cloudlogs_group_id"></a> [upwind\_cloudlogs\_group\_id](#input\_upwind\_cloudlogs\_group\_id) | The OCID of the log-reader group that OCI onboarding creates: the ocid of its federated\_cloudlogs\_group output. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | Name of the log bucket. |
| <a name="output_pointer_stream_name"></a> [pointer\_stream\_name](#output\_pointer\_stream\_name) | Name of the pointer stream. |
<!-- END_TF_DOCS -->
