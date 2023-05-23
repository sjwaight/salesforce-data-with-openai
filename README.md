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
