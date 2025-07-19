resource "azurerm_role_assignment" "assignment" {
  count = var.enable == true ? 1 : 0
  scope                = var.scope
  role_definition_name = var.role
  principal_id         = var.principal_id
}
