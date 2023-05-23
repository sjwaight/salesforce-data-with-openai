# Creating test data for Salesforce with Azure OpenAI GPT and Logic Apps

This sample shows you how you can use the Azure OpenAI's GPT model to generate test data for Salesforce.

The repositories contents are as follows.

- Deployment of infrastructure via Bicep: find in 'infra' folder.
- Logic App (Standard): delivers main functionality. Lives in 'logic' folder and is deployed by the GitHub Action you will find in the .github/workflows folder. 

Deploy infrastructure to an existing Resource Group using this command. 

```bash
az deployment group create --resource-group <resource-group-name> --template-file infra/main.bicep
```

The Bicep template will create resources with randomised names based on your resource group name.

> Note: At time of writing you have a limited number of Azure Regions in which to access the OpenAI Service, so make sure to review the bicep template before running. You will also need to have [access approval for use of the OpenAI Services](https://learn.microsoft.com/en-us/azure/cognitive-services/openai/quickstart?pivots=programming-language-studio&tabs=command-line#prerequisites).

Once your infrastructure is deployed you can then configure the GitHub Action to deploy the Logic App. See the [documentation on how to do this](https://github.com/Azure/logicapps/blob/master/github-sample/README.md#devops).

A sample local.settings.json (which will also include some App Settings required in your Azure hosting plan) is shown below.

In order to populate the `SALESFORCE_CONNECTION_RUNTIMEURL` property you should manually configure up your Salesforce Connection and then copy the value that represents the Azure-managed API endpoint for accessing Salesforce and replace {salesforce_runtime_url} with it.

```json
{
  "IsEncrypted": false,
  "Values": {
    "FUNCTIONS_EXTENSION_VERSION": "~4",
    "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING": "DefaultEndpointsProtocol=https;AccountName={accountname};AccountKey={account_key};EndpointSuffix=core.windows.net",
    "WEBSITE_SITE_NAME": "{logic_app_name}",
    "FUNCTIONS_WORKER_RUNTIME": "node",
    "APP_KIND": "workflowApp",
    "WEBSITE_AUTH_ENABLED": "False",
    "AzureWebJobsStorage": "DefaultEndpointsProtocol=https;AccountName={accountname};AccountKey={account_key};EndpointSuffix=core.windows.net",
    "AzureFunctionsJobHost__extensionBundle__id": "Microsoft.Azure.Functions.ExtensionBundle.Workflows",
    "ScmType": "None",
    "keyVault_VaultUri": "https://{key_vault_name.vault.azure.net/",
    "WEBSITE_CONTENTSHARE": "{logic_app_name}",
    "FUNCTIONS_RUNTIME_SCALE_MONITORING_ENABLED": "1",
    "AzureFunctionsJobHost__extensionBundle__version": "[1.*, 2.0.0)",
    "WEBSITE_SLOT_NAME": "Production",
    "SALESFORCE_CONNECTION_RUNTIMEURL": "{salesforce_runtime_url}",
    "APPLICATIONINSIGHTS_CONNECTION_STRING": "InstrumentationKey={app_insights_key};IngestionEndpoint={app_insights_url};LiveEndpoint={app_insights_live_url}",
    "WEBSITE_NODE_DEFAULT_VERSION": "16.16.0",
    "APPINSIGHTS_INSTRUMENTATIONKEY": "{app_insights_key}",
    "WORKFLOWS_TENANT_ID": "{azure_ad_tenant_id}",
    "WORKFLOWS_SUBSCRIPTION_ID": "{azure_subscription_id}",
    "WORKFLOWS_RESOURCE_GROUP_NAME": "{target_resource_group_name}",
    "WORKFLOWS_LOCATION_NAME": "{target_resource_group_location}",
    "WORKFLOWS_MANAGEMENT_BASE_URI": "https://management.azure.com/"
  }
}
```
