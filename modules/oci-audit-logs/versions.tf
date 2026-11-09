terraform {
  required_version = ">= 1.11.0"

  required_providers {
    # Upper bounds are deliberate: a new provider major must be tested against this
    # module before customers get it. The source is oracle/oci, as in OCI onboarding:
    # a root module that declares oracle/oci cannot pass its provider to a module
    # that declares hashicorp/oci.
    oci = {
      source                = "oracle/oci"
      version               = ">= 8.22.0, < 9.0.0"
      configuration_aliases = [oci.home_region]
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.10.0, < 1.0.0"
    }
  }
}
