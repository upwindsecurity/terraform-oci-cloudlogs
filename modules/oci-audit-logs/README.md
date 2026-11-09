# oci-audit-logs

Terraform module that lets Upwind ingest OCI Audit logs from an Oracle Cloud Infrastructure (OCI) tenancy. Call it once
per region: it creates that region's pipeline and grants the log-reader group from OCI onboarding read access to it.

## Architecture

```text
  OCI Audit
       |
       v
  Audit connector  (enable_audit_logs / enable_identity_logs)
       |
       v
  bucket upwind-audit-logs  (gzip objects, deleted after 2 days)
       |  createobject event
       v
  Events rule  -->  stream upwind-audit-logs-stream  (one pointer per object)

  In the home region: one IAM policy per region granting the log-reader group this bucket and stream
```

Upwind reads the pointers from the stream and fetches the objects from the bucket as the log-reader group. The module
creates no identity and stores no credential; destroying it revokes the access.

## Log types

| Toggle | Source | Cost |
|---|---|---|
| `enable_audit_logs` | OCI Audit, apart from identity events | Free |
| `enable_identity_logs` | OCI Audit sign-on and IAM change events | Free |

At least one must be on. Kubernetes API-server audit events from OKE are always dropped. `log_filter_exclusions` adds
[Connector Hub conditions](https://docs.oracle.com/en-us/iaas/Content/connector-hub/queryreference.htm) of your own.

## Scope

| `scope_type` | `included_compartment_ids` | `..._without_subcompartments` | Collected |
|---|---|---|---|
| `TENANCY` | none | none | The whole tenancy |
| `TENANCY` | `[A]` | none | The tenancy root's own events and A's subtree |
| `TENANCY` | none | `[A]` | The tenancy root's own events and A alone |
| `COMPARTMENT` | `[A]` | none | A's subtree only: no sign-on events |
| `COMPARTMENT` | none | `[A]` | A alone |
| `TENANCY` or `COMPARTMENT` | none | `[tenancy]` | The tenancy root's own events only |

Sign-on events and changes to IAM users and groups are recorded at the tenancy root, so `COMPARTMENT` does not get them.
To leave a subtree out, list its siblings.

## Resource names

`<suffix>` is `-<resource_suffix>` when set. It is appended to custom names too.

| Resource | Default name | Override |
|---|---|---|
| Bucket | `upwind-audit-logs<suffix>` | `bucket_name` |
| Pointer stream | `upwind-audit-logs-stream<suffix>` | `stream_name` |
| Audit connector | `upwind-audit-logs-connector<suffix>` | `connector_name` |
| Events rule | `upwind-audit-logs-new-file<suffix>` | `events_rule_name` |
| Bucket vault and key | `upwind-audit-logs-bucket-vault<suffix>`, `upwind-audit-logs-bucket-key<suffix>` | `bucket_vault_name`, `bucket_key_name` |
| IAM policy | `upwind-audit-logs-<region><suffix>` | `identity_policy_name` |

## Usage

```hcl
provider "oci" {
  region = "us-ashburn-1"
}

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

For another region, call the module again with that region's provider as `oci` and keep `oci.home_region` on the home
region. The module takes the region from the provider. See [examples/oci-audit-logs-multi-region](https://github.com/upwindsecurity/terraform-oci-cloudlogs/tree/main/examples/oci-audit-logs-multi-region).

## Prerequisites

- OCI onboarding v1.13.0 or later, applied with `enable_cloudlogs = true`. Pass the `ocid` of its `federated_cloudlogs_group` output as
  `upwind_cloudlogs_group_id`.
- The applying user can manage policies, streams, buckets, objects, service connectors and events rules in the
  tenancy, and vaults and keys with `enable_bucket_cmk`. `manage all-resources in tenancy` covers this.

## Security

- The log-reader group gets `use stream-pull` on this region's stream and `read objects` in this region's bucket. It
  gets nothing else, also with `enable_bucket_cmk`: Object Storage decrypts the objects for it.
- Connector Hub can create, list and overwrite objects in this bucket only.
- With `enable_bucket_object_lifecycle`, Object Storage gets `manage object-family` on this bucket only, which a
  lifecycle rule needs.
- The bucket uses Oracle-managed encryption unless `enable_bucket_cmk` is set.

## Destroy

OCI does not delete a bucket that still has objects, so `terraform destroy` can stop at the bucket. If it does, empty
the bucket and run `terraform destroy` again:

```sh
oci os object bulk-delete --region <region> --bucket-name <bucket_name> --force
```

<!-- BEGIN_TF_DOCS -->

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.0 |
| <a name="requirement_oci"></a> [oci](#requirement\_oci) | >= 8.22.0, < 9.0.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.10.0, < 1.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_oci"></a> [oci](#provider\_oci) | 8.29.0 |
| <a name="provider_oci.home_region"></a> [oci.home\_region](#provider\_oci.home\_region) | 8.29.0 |
| <a name="provider_time"></a> [time](#provider\_time) | 0.14.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [oci_events_rule.new_object](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/events_rule) | resource |
| [oci_identity_policy.this](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/identity_policy) | resource |
| [oci_kms_key.bucket](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/kms_key) | resource |
| [oci_kms_vault.bucket](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/kms_vault) | resource |
| [oci_objectstorage_bucket.this](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/objectstorage_bucket) | resource |
| [oci_objectstorage_object_lifecycle_policy.this](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/objectstorage_object_lifecycle_policy) | resource |
| [oci_sch_service_connector.audit](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/sch_service_connector) | resource |
| [oci_streaming_stream.pointers](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/streaming_stream) | resource |
| [time_sleep.wait_for_bucket_vault](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.wait_for_policy](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [oci_identity_compartments.all](https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/identity_compartments) | data source |
| [oci_identity_regions.all](https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/identity_regions) | data source |
| [oci_objectstorage_namespace.default](https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/objectstorage_namespace) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bucket_cmk_key_compartment_id"></a> [bucket\_cmk\_key\_compartment\_id](#input\_bucket\_cmk\_key\_compartment\_id) | Optional OCID of the compartment that holds `bucket_cmk_key_id`. Empty means `oci_compartment_id`. It must be `oci_compartment_id` or a compartment under it: the `use keys` statement is in the policy attached to `oci_compartment_id`, and a policy cannot name a compartment outside its own subtree. | `string` | `""` | no |
| <a name="input_bucket_cmk_key_id"></a> [bucket\_cmk\_key\_id](#input\_bucket\_cmk\_key\_id) | Optional OCID of an existing key, in this region and in `bucket_cmk_key_compartment_id`, to encrypt the log bucket with. | `string` | `""` | no |
| <a name="input_bucket_key_name"></a> [bucket\_key\_name](#input\_bucket\_key\_name) | Optional name of the key the module creates for bucket encryption. Empty means `upwind-audit-logs-bucket-key`. `resource_suffix` is appended either way. | `string` | `""` | no |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Optional name of this region's log bucket. Empty means `upwind-audit-logs`. `resource_suffix` is appended either way. | `string` | `""` | no |
| <a name="input_bucket_object_lifecycle_days"></a> [bucket\_object\_lifecycle\_days](#input\_bucket\_object\_lifecycle\_days) | Number of days to retain log objects in the bucket. | `number` | `2` | no |
| <a name="input_bucket_vault_name"></a> [bucket\_vault\_name](#input\_bucket\_vault\_name) | Optional name of the vault the module creates for bucket encryption. Empty means `upwind-audit-logs-bucket-vault`. `resource_suffix` is appended either way. | `string` | `""` | no |
| <a name="input_connector_name"></a> [connector\_name](#input\_connector\_name) | Optional base name of the Connector Hub connectors this module creates in this region. Empty means `upwind-audit-logs-connector`. `resource_suffix` is appended either way. | `string` | `""` | no |
| <a name="input_create_timeout"></a> [create\_timeout](#input\_create\_timeout) | Create timeout of the bucket encryption vault and key, as a Terraform duration string (e.g. "30m", "1h"). | `string` | `"30m"` | no |
| <a name="input_defined_tags"></a> [defined\_tags](#input\_defined\_tags) | Defined tags (`namespace.key`) to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_enable_audit_logs"></a> [enable\_audit\_logs](#input\_enable\_audit\_logs) | Collect OCI Audit events, apart from identity events. | `bool` | `false` | no |
| <a name="input_enable_bucket_cmk"></a> [enable\_bucket\_cmk](#input\_enable\_bucket\_cmk) | Encrypt the log bucket with a customer-managed key: `bucket_cmk_key_id`, or a vault and key the module creates. | `bool` | `false` | no |
| <a name="input_enable_bucket_object_lifecycle"></a> [enable\_bucket\_object\_lifecycle](#input\_enable\_bucket\_object\_lifecycle) | Delete log objects from the bucket automatically after `bucket_object_lifecycle_days`. | `bool` | `true` | no |
| <a name="input_enable_identity_logs"></a> [enable\_identity\_logs](#input\_enable\_identity\_logs) | Collect identity sign-on and IAM change events. | `bool` | `false` | no |
| <a name="input_events_rule_name"></a> [events\_rule\_name](#input\_events\_rule\_name) | Optional name of this region's events rule. Empty means `upwind-audit-logs-new-file`. `resource_suffix` is appended either way. | `string` | `""` | no |
| <a name="input_identity_policy_name"></a> [identity\_policy\_name](#input\_identity\_policy\_name) | Optional base name of this region's IAM policy, named `<name>-<region>`. Empty means `upwind-audit-logs`. `resource_suffix` is appended either way. | `string` | `""` | no |
| <a name="input_included_compartment_ids"></a> [included\_compartment\_ids](#input\_included\_compartment\_ids) | Compartments to collect from, with every compartment under them. | `list(string)` | `[]` | no |
| <a name="input_included_compartment_ids_without_subcompartments"></a> [included\_compartment\_ids\_without\_subcompartments](#input\_included\_compartment\_ids\_without\_subcompartments) | Compartments to collect from, without the compartments under them. The tenancy OCID collects the events recorded at the tenancy root alone; listed alone, it collects the tenancy root only. | `list(string)` | `[]` | no |
| <a name="input_log_filter_exclusions"></a> [log\_filter\_exclusions](#input\_log\_filter\_exclusions) | Extra Connector Hub filter conditions, ANDed to the module's own. Example: "not (type = 'com.oraclecloud.identitycontrolplane.listapikeys')". | `list(string)` | `[]` | no |
| <a name="input_oci_compartment_id"></a> [oci\_compartment\_id](#input\_oci\_compartment\_id) | The OCID of the compartment (or tenancy) the module creates its resources in. | `string` | n/a | yes |
| <a name="input_oci_tenancy_id"></a> [oci\_tenancy\_id](#input\_oci\_tenancy\_id) | The OCID of the OCI tenancy. | `string` | n/a | yes |
| <a name="input_policy_propagation_wait"></a> [policy\_propagation\_wait](#input\_policy\_propagation\_wait) | How long to wait for the IAM policy to propagate before creating the resources that depend on it. | `string` | `"60s"` | no |
| <a name="input_resource_suffix"></a> [resource\_suffix](#input\_resource\_suffix) | Optional suffix appended as `-<suffix>` to every resource name. | `string` | `""` | no |
| <a name="input_scope_type"></a> [scope\_type](#input\_scope\_type) | TENANCY: the whole tenancy when no compartment is listed, otherwise the tenancy root's own events and the listed compartments. COMPARTMENT: the listed compartments only. | `string` | `"TENANCY"` | no |
| <a name="input_service_connector_target_batch_size_in_mbs"></a> [service\_connector\_target\_batch\_size\_in\_mbs](#input\_service\_connector\_target\_batch\_size\_in\_mbs) | Batch rollover size in MB for the Connector Hub Object Storage target. | `number` | `2` | no |
| <a name="input_service_connector_target_batch_time_in_ms"></a> [service\_connector\_target\_batch\_time\_in\_ms](#input\_service\_connector\_target\_batch\_time\_in\_ms) | Batch rollover time in milliseconds for the Connector Hub Object Storage target. | `number` | `120000` | no |
| <a name="input_stream_name"></a> [stream\_name](#input\_stream\_name) | Optional name of this region's pointer stream. Empty means `upwind-audit-logs-stream`. `resource_suffix` is appended either way. | `string` | `""` | no |
| <a name="input_stream_partitions"></a> [stream\_partitions](#input\_stream\_partitions) | Number of partitions of the pointer stream. Changing it replaces the stream. | `number` | `8` | no |
| <a name="input_stream_retention_in_hours"></a> [stream\_retention\_in\_hours](#input\_stream\_retention\_in\_hours) | Retention of pointer messages on the stream, in hours (24-168). | `number` | `24` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Freeform tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_upwind_cloudlogs_group_id"></a> [upwind\_cloudlogs\_group\_id](#input\_upwind\_cloudlogs\_group\_id) | The OCID of the log-reader group that OCI onboarding creates with `enable_cloudlogs = true`: the `ocid` of its `federated_cloudlogs_group` output. | `string` | n/a | yes |
| <a name="input_vault_endpoint_wait"></a> [vault\_endpoint\_wait](#input\_vault\_endpoint\_wait) | How long to wait after the module creates the bucket vault before it creates the key, so the vault's management endpoint resolves in DNS. Only used when the module creates the vault. | `string` | `"6m"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | Name of the bucket receiving the log objects. |
| <a name="output_enabled_log_types"></a> [enabled\_log\_types](#output\_enabled\_log\_types) | The enabled log types: AUDIT, IDENTITY. |
| <a name="output_pointer_stream_id"></a> [pointer\_stream\_id](#output\_pointer\_stream\_id) | OCID of the pointer stream. |
| <a name="output_pointer_stream_name"></a> [pointer\_stream\_name](#output\_pointer\_stream\_name) | Name of the stream carrying one pointer per new log object. |
| <a name="output_policy_id"></a> [policy\_id](#output\_policy\_id) | OCID of this region's IAM policy. |
<!-- END_TF_DOCS -->
