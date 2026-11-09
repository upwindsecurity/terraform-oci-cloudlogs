# region upwind

variable "resource_suffix" {
  description = "Optional suffix appended as `-<suffix>` to every resource name."
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^[a-zA-Z0-9]{0,10}$", var.resource_suffix))
    error_message = "The resource suffix must be alphanumeric and cannot exceed 10 characters."
  }
}

# endregion upwind

# region oci

variable "oci_tenancy_id" {
  description = "The OCID of the OCI tenancy."
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.tenancy\\..*", var.oci_tenancy_id))
    error_message = "The OCI tenancy ID must be a valid OCI tenancy OCID (starts with ocid1.tenancy)."
  }
}

variable "oci_compartment_id" {
  description = "The OCID of the compartment (or tenancy) the module creates its resources in."
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.(tenancy|compartment)\\..*", var.oci_compartment_id))
    error_message = "The OCI compartment ID must be a valid OCI tenancy or compartment OCID."
  }
}

variable "upwind_cloudlogs_group_id" {
  description = "The OCID of the log-reader group that OCI onboarding creates with `enable_cloudlogs = true`: the `ocid` of its `federated_cloudlogs_group` output."
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.group\\..*", var.upwind_cloudlogs_group_id))
    error_message = "upwind_cloudlogs_group_id must be a group OCID (starts with ocid1.group)."
  }
}

# endregion oci

# region names

variable "bucket_name" {
  description = "Optional name of this region's log bucket. Empty means `upwind-audit-logs`. `resource_suffix` is appended either way."
  type        = string
  default     = ""

  validation {
    condition     = var.bucket_name == "" || can(regex("^[a-zA-Z0-9_.-]+$", var.bucket_name))
    error_message = "bucket_name may only contain a-zA-Z0-9_.- characters."
  }

  validation {
    condition     = length(var.bucket_name) + (var.resource_suffix == "" ? 0 : length(var.resource_suffix) + 1) <= 255
    error_message = "bucket_name plus `-<resource_suffix>` cannot exceed 255 characters."
  }
}

variable "stream_name" {
  description = "Optional name of this region's pointer stream. Empty means `upwind-audit-logs-stream`. `resource_suffix` is appended either way."
  type        = string
  default     = ""

  validation {
    condition     = var.stream_name == "" || can(regex("^[a-zA-Z0-9_.-]+$", var.stream_name))
    error_message = "stream_name may only contain a-zA-Z0-9_.- characters."
  }

  validation {
    condition     = length(var.stream_name) + (var.resource_suffix == "" ? 0 : length(var.resource_suffix) + 1) <= 256
    error_message = "stream_name plus `-<resource_suffix>` cannot exceed 256 characters."
  }
}

variable "connector_name" {
  description = "Optional base name of the Connector Hub connectors this module creates in this region. Empty means `upwind-audit-logs-connector`. `resource_suffix` is appended either way."
  type        = string
  default     = ""

  validation {
    condition     = var.connector_name == "" || can(regex("^[a-zA-Z0-9_.-]+$", var.connector_name))
    error_message = "connector_name may only contain a-zA-Z0-9_.- characters."
  }

  validation {
    condition     = length(var.connector_name) + (var.resource_suffix == "" ? 0 : length(var.resource_suffix) + 1) <= 255
    error_message = "connector_name plus `-<resource_suffix>` cannot exceed 255 characters."
  }
}

variable "events_rule_name" {
  description = "Optional name of this region's events rule. Empty means `upwind-audit-logs-new-file`. `resource_suffix` is appended either way."
  type        = string
  default     = ""

  validation {
    condition     = var.events_rule_name == "" || can(regex("^[a-zA-Z0-9_.-]+$", var.events_rule_name))
    error_message = "events_rule_name may only contain a-zA-Z0-9_.- characters."
  }

  validation {
    condition     = length(var.events_rule_name) + (var.resource_suffix == "" ? 0 : length(var.resource_suffix) + 1) <= 255
    error_message = "events_rule_name plus `-<resource_suffix>` cannot exceed 255 characters."
  }
}

variable "bucket_vault_name" {
  description = "Optional name of the vault the module creates for bucket encryption. Empty means `upwind-audit-logs-bucket-vault`. `resource_suffix` is appended either way."
  type        = string
  default     = ""

  validation {
    condition     = var.bucket_vault_name == "" || can(regex("^[a-zA-Z0-9_.-]+$", var.bucket_vault_name))
    error_message = "bucket_vault_name may only contain a-zA-Z0-9_.- characters."
  }

  validation {
    condition     = length(var.bucket_vault_name) + (var.resource_suffix == "" ? 0 : length(var.resource_suffix) + 1) <= 255
    error_message = "bucket_vault_name plus `-<resource_suffix>` cannot exceed 255 characters."
  }
}

variable "bucket_key_name" {
  description = "Optional name of the key the module creates for bucket encryption. Empty means `upwind-audit-logs-bucket-key`. `resource_suffix` is appended either way."
  type        = string
  default     = ""

  validation {
    condition     = var.bucket_key_name == "" || can(regex("^[a-zA-Z0-9_.-]+$", var.bucket_key_name))
    error_message = "bucket_key_name may only contain a-zA-Z0-9_.- characters."
  }

  validation {
    condition     = length(var.bucket_key_name) + (var.resource_suffix == "" ? 0 : length(var.resource_suffix) + 1) <= 255
    error_message = "bucket_key_name plus `-<resource_suffix>` cannot exceed 255 characters."
  }
}

variable "identity_policy_name" {
  description = "Optional base name of this region's IAM policy, named `<name>-<region>`. Empty means `upwind-audit-logs`. `resource_suffix` is appended either way."
  type        = string
  default     = ""

  validation {
    condition     = var.identity_policy_name == "" || can(regex("^[a-zA-Z0-9_.-]+$", var.identity_policy_name))
    error_message = "identity_policy_name may only contain a-zA-Z0-9_.- characters."
  }

  # Leaves room for `-<region>` and `-<resource_suffix>` within OCI's policy name limit.
  validation {
    condition     = length(var.identity_policy_name) <= 50
    error_message = "identity_policy_name cannot exceed 50 characters."
  }
}

# endregion names

# region tagging

variable "tags" {
  description = "Freeform tags to apply to all resources."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for k, v in var.tags : can(regex("^[a-zA-Z0-9_.-]{1,100}$", k)) && length(v) <= 256
    ])
    error_message = "Tag keys may only contain a-zA-Z0-9_.- characters (1-100), and values cannot exceed 256 characters."
  }
}

variable "defined_tags" {
  description = "Defined tags (`namespace.key`) to apply to all resources."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for k, v in var.defined_tags : can(regex("^[a-zA-Z0-9_.-]{1,100}\\.[a-zA-Z0-9_.-]{1,100}$", k)) && length(v) <= 256
    ])
    error_message = "Defined tag keys must be \"namespace.key\" using a-zA-Z0-9_.- characters, and values cannot exceed 256 characters."
  }
}

# endregion tagging

# region bucket

variable "enable_bucket_cmk" {
  description = "Encrypt the log bucket with a customer-managed key: `bucket_cmk_key_id`, or a vault and key the module creates."
  type        = bool
  default     = false
}

variable "bucket_cmk_key_id" {
  description = "Optional OCID of an existing key, in this region and in `bucket_cmk_key_compartment_id`, to encrypt the log bucket with."
  type        = string
  default     = ""

  validation {
    condition     = var.bucket_cmk_key_id == "" || can(regex("^ocid1\\.key\\..*", var.bucket_cmk_key_id))
    error_message = "The bucket CMK key ID must be a valid OCI key OCID (starts with ocid1.key)."
  }

  validation {
    condition     = var.bucket_cmk_key_id == "" || var.enable_bucket_cmk
    error_message = "bucket_cmk_key_id requires enable_bucket_cmk = true."
  }
}

variable "bucket_cmk_key_compartment_id" {
  description = "Optional OCID of the compartment that holds `bucket_cmk_key_id`. Empty means `oci_compartment_id`. It must be `oci_compartment_id` or a compartment under it: the `use keys` statement is in the policy attached to `oci_compartment_id`, and a policy cannot name a compartment outside its own subtree."
  type        = string
  default     = ""

  validation {
    condition     = var.bucket_cmk_key_compartment_id == "" || can(regex("^ocid1\\.(tenancy|compartment)\\..*", var.bucket_cmk_key_compartment_id))
    error_message = "The bucket CMK key compartment ID must be a valid OCI tenancy or compartment OCID."
  }

  validation {
    condition     = var.bucket_cmk_key_compartment_id == "" || var.bucket_cmk_key_id != ""
    error_message = "bucket_cmk_key_compartment_id requires bucket_cmk_key_id."
  }
}

variable "enable_bucket_object_lifecycle" {
  description = "Delete log objects from the bucket automatically after `bucket_object_lifecycle_days`."
  type        = bool
  default     = true
}

variable "bucket_object_lifecycle_days" {
  description = "Number of days to retain log objects in the bucket."
  type        = number
  default     = 2

  validation {
    condition     = var.bucket_object_lifecycle_days >= 1
    error_message = "bucket_object_lifecycle_days must be at least 1."
  }
}

variable "service_connector_target_batch_size_in_mbs" {
  description = "Batch rollover size in MB for the Connector Hub Object Storage target."
  type        = number
  default     = 2

  validation {
    condition     = var.service_connector_target_batch_size_in_mbs >= 1 && var.service_connector_target_batch_size_in_mbs <= 100
    error_message = "service_connector_target_batch_size_in_mbs must be between 1 and 100."
  }
}

variable "service_connector_target_batch_time_in_ms" {
  description = "Batch rollover time in milliseconds for the Connector Hub Object Storage target."
  type        = number
  default     = 120000

  validation {
    condition     = var.service_connector_target_batch_time_in_ms >= 60000 && var.service_connector_target_batch_time_in_ms <= 420000
    error_message = "service_connector_target_batch_time_in_ms must be between 60000 (1 minute) and 420000 (7 minutes)."
  }
}

# endregion bucket

# region stream

variable "stream_partitions" {
  description = "Number of partitions of the pointer stream. Changing it replaces the stream."
  type        = number
  default     = 8

  validation {
    condition     = var.stream_partitions >= 1
    error_message = "stream_partitions must be at least 1."
  }
}

variable "stream_retention_in_hours" {
  description = "Retention of pointer messages on the stream, in hours (24-168)."
  type        = number
  default     = 24

  validation {
    condition     = var.stream_retention_in_hours >= 24 && var.stream_retention_in_hours <= 168
    error_message = "stream_retention_in_hours must be between 24 and 168."
  }
}

# endregion stream

# region log types

variable "enable_audit_logs" {
  description = "Collect OCI Audit events, apart from identity events."
  type        = bool
  default     = false
}

variable "enable_identity_logs" {
  description = "Collect identity sign-on and IAM change events."
  type        = bool
  default     = false
}

variable "scope_type" {
  description = "TENANCY: the whole tenancy when no compartment is listed, otherwise the tenancy root's own events and the listed compartments. COMPARTMENT: the listed compartments only."
  type        = string
  default     = "TENANCY"

  validation {
    condition     = contains(["TENANCY", "COMPARTMENT"], var.scope_type)
    error_message = "scope_type must be TENANCY or COMPARTMENT."
  }

  validation {
    condition     = var.scope_type != "COMPARTMENT" || length(var.included_compartment_ids) > 0 || length(var.included_compartment_ids_without_subcompartments) > 0
    error_message = "scope_type COMPARTMENT requires included_compartment_ids or included_compartment_ids_without_subcompartments."
  }
}

variable "included_compartment_ids" {
  description = "Compartments to collect from, with every compartment under them."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for id in var.included_compartment_ids : can(regex("^ocid1\\.compartment\\..*", id))])
    error_message = "Every entry of included_compartment_ids must be a compartment OCID (starts with ocid1.compartment)."
  }
}

variable "included_compartment_ids_without_subcompartments" {
  description = "Compartments to collect from, without the compartments under them. The tenancy OCID collects the events recorded at the tenancy root alone; listed alone, it collects the tenancy root only."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for id in var.included_compartment_ids_without_subcompartments : can(regex("^ocid1\\.compartment\\..*", id)) || id == var.oci_tenancy_id])
    error_message = "Every entry of included_compartment_ids_without_subcompartments must be a compartment OCID (starts with ocid1.compartment) or oci_tenancy_id."
  }

  validation {
    condition     = length(setintersection(var.included_compartment_ids_without_subcompartments, var.included_compartment_ids)) == 0
    error_message = "A compartment cannot be in both included_compartment_ids and included_compartment_ids_without_subcompartments."
  }
}

variable "log_filter_exclusions" {
  description = "Extra Connector Hub filter conditions, ANDed to the module's own. Example: \"not (type = 'com.oraclecloud.identitycontrolplane.listapikeys')\"."
  type        = list(string)
  default     = []
}

# endregion log types

# region timeouts

variable "create_timeout" {
  description = "Create timeout of the bucket encryption vault and key, as a Terraform duration string (e.g. \"30m\", \"1h\")."
  type        = string
  default     = "30m"

  validation {
    condition     = var.create_timeout != "" && can(regex("^([0-9]+h)?([0-9]+m)?([0-9]+s)?$", var.create_timeout))
    error_message = "The create_timeout must be a valid Terraform duration string (e.g. \"30m\", \"1h\", \"90s\")."
  }
}

variable "vault_endpoint_wait" {
  description = "How long to wait after the module creates the bucket vault before it creates the key, so the vault's management endpoint resolves in DNS. Only used when the module creates the vault."
  type        = string
  default     = "6m"

  validation {
    condition     = var.vault_endpoint_wait != "" && can(regex("^([0-9]+h)?([0-9]+m)?([0-9]+s)?$", var.vault_endpoint_wait))
    error_message = "The vault_endpoint_wait must be a valid Terraform duration string (e.g. \"6m\", \"300s\")."
  }
}

variable "policy_propagation_wait" {
  description = "How long to wait for the IAM policy to propagate before creating the resources that depend on it."
  type        = string
  default     = "60s"

  validation {
    condition     = var.policy_propagation_wait != "" && can(regex("^([0-9]+h)?([0-9]+m)?([0-9]+s)?$", var.policy_propagation_wait))
    error_message = "The policy_propagation_wait must be a valid Terraform duration string (e.g. \"60s\")."
  }
}

# endregion timeouts
