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
  default     = ""
}

variable "tags" {
  description = "A map of freeform tags to apply to all resources."
  type        = map(string)
  default     = {}
}
