# Azure Policy Remediation Automation

Uses a LogicApp which triggers on EventGrid and automatically initiates Policy Remediation Tasks.

Contains a sample terraform deployment of
- EventGrid System Topic
- Event Grid System Subscription
- LogicApp

# Future Use

Consider using an Azure Blueprint to deploy the Event Grid System Topics and Subscriptions to every subscription:
- allows to prevent subscription owners tampering with the event grid configuration (deny assignments)

Terraform `azapi` provider is able to deploy `"type": "Microsoft.Blueprint/blueprints"`. See https://learn.microsoft.com/en-us/azure/templates/microsoft.blueprint/blueprints?pivots=deployment-language-terraform


