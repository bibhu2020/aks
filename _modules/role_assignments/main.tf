resource "azurerm_role_assignment" "assignment" {
  for_each             = var.role_assignments
  scope                = each.value.scope
  role_definition_name = each.value.role
  principal_id         = each.value.principal_id
}
