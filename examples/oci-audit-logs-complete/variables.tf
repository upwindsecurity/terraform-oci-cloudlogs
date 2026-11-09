variable "upwind_cloudlogs_group_id" {
  description = "The OCID of the log-reader group that OCI onboarding creates: the ocid of its federated_cloudlogs_group output."
  type        = string
}

variable "oci_tenancy_id" {
  description = "The OCI tenancy OCID."
  type        = string
}

variable "oci_region" {
  description = "The OCI home region, where the pipeline is created."
  type        = string
  default     = "us-ashburn-1"
}

variable "resource_suffix" {
  description = "Optional suffix, up to 10 alphanumeric characters, appended to resource names."
  type        = string
  default     = "prod"
}

variable "scope_type" {
  description = "TENANCY collects the tenancy root's own events too; COMPARTMENT only the included compartments."
  type        = string
  default     = "TENANCY"
}

variable "included_compartment_ids" {
  description = "Compartments to collect logs from, with every compartment under them."
  type        = list(string)
  default     = []
}

variable "included_compartment_ids_without_subcompartments" {
  description = "Compartments to collect logs from alone, without the compartments under them."
  type        = list(string)
  default     = []
}

variable "bucket_cmk_key_id" {
  description = "OCID of the customer's own key, in the pipeline region and compartment, to encrypt the log bucket with. Empty creates a vault and key for it."
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of freeform tags to apply to all resources."
  type        = map(string)
  default = {
    environment = "production"
    owner       = "security"
  }
}

variable "defined_tags" {
  description = "A map of namespace-qualified defined tags to apply to all resources."
  type        = map(string)
  default     = {}
}
