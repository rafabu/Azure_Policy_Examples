######################################################
# Deploy sample Web App (hello world) with
#     - Web App (Linux)
#     - Azure SQL
#     - Key Vault
#     - Application Insights
#     - Virtual Machine to allow developer access
######################################################

data "azuread_client_config" "aad" {
}
data "azurerm_subscription" "sub" {
}

