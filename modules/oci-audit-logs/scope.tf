# region scope

data "oci_identity_compartments" "all" {
  count = length(var.included_compartment_ids) > 0 ? 1 : 0

  compartment_id            = var.oci_tenancy_id
  compartment_id_in_subtree = true
  access_level              = "ANY"
  state                     = "ACTIVE"
}

locals {
  all_compartments = flatten(data.oci_identity_compartments.all[*].compartments)

  # Descendants are collected level by level: a subtree listing is only allowed from the tenancy, and
  # compartments nest at most six levels below the root, so five steps reach them all.
  included_descendants_1 = [for c in local.all_compartments : c.id if contains(var.included_compartment_ids, c.compartment_id)]
  included_descendants_2 = [for c in local.all_compartments : c.id if contains(local.included_descendants_1, c.compartment_id)]
  included_descendants_3 = [for c in local.all_compartments : c.id if contains(local.included_descendants_2, c.compartment_id)]
  included_descendants_4 = [for c in local.all_compartments : c.id if contains(local.included_descendants_3, c.compartment_id)]
  included_descendants_5 = [for c in local.all_compartments : c.id if contains(local.included_descendants_4, c.compartment_id)]
  included_descendants = concat(local.included_descendants_1, local.included_descendants_2, local.included_descendants_3,
  local.included_descendants_4, local.included_descendants_5)

  # A compartment already under a listed subtree is covered by that subtree's source, so it is dropped: no log
  # arrives twice.
  included_roots         = [for id in distinct(var.included_compartment_ids) : id if !contains(local.included_descendants, id)]
  included_single_ids    = [for id in distinct(var.included_compartment_ids_without_subcompartments) : id if !contains(local.included_descendants, id)]
  any_compartment_listed = length(var.included_compartment_ids) > 0 || length(var.included_compartment_ids_without_subcompartments) > 0
  whole_tenancy_included = !local.any_compartment_listed

  # `_Audit` covers a compartment alone, `_Audit_Include_Subcompartment` a compartment and its whole subtree. TENANCY
  # reads the root's own events alongside listed compartments.
  root_events_included = var.scope_type == "TENANCY" && local.any_compartment_listed

  # distinct: a listed tenancy under TENANCY scope is the root source twice, and a source read twice sends its logs twice.
  audit_log_sources = distinct(concat(
    local.whole_tenancy_included ? [{ compartment_id = var.oci_tenancy_id, log_group_id = "_Audit_Include_Subcompartment" }] : [],
    local.root_events_included ? [{ compartment_id = var.oci_tenancy_id, log_group_id = "_Audit" }] : [],
    [for id in local.included_roots : { compartment_id = id, log_group_id = "_Audit_Include_Subcompartment" }],
    [for id in local.included_single_ids : { compartment_id = id, log_group_id = "_Audit" }],
  ))
}

# endregion scope
