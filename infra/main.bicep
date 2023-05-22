@allowed([
  'eastus'
  'southcentralus'
  'westeurope'
  'franecentral'
])
param deployment_region string = 'eastus'

param openai_service_name string = 'openai-cs-${uniqueString(resourceGroup().name)}'
param openai_model_name string = 'openai-md-${uniqueString(resourceGroup().name)}'
param logicapp_hosting_plan_name string = 'openai-la-asp-${uniqueString(resourceGroup().name)}'
param open_ai_keyvault_name string = 'openai-kv-${uniqueString(resourceGroup().name)}'
param managed_service_identity_name string = 'openai-msi-${uniqueString(resourceGroup().name)}'
param storage_account_name string = 'openaistg${uniqueString(resourceGroup().name)}'
param logicapp_site_name string = 'openai-hst-${uniqueString(resourceGroup().name)}'

param connections_keyvault_name string = 'keyvault'
param connections_salesforce_name string = 'salesforce'

param api_key_name string = 'openai-api-key'

// Managed Service Identity

resource managed_service_identity_resource 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: managed_service_identity_name
  location: deployment_region
}

// End of Managed Service Identity

// Azure OpenAI Service and Models

resource openai_service_resource 'Microsoft.CognitiveServices/accounts@2022-12-01' = {
  name: openai_service_name
  location: deployment_region
  sku: {
    name: 'S0'
  }
  kind: 'OpenAI'
  properties: {
    customSubDomainName: openai_service_name
    networkAcls: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: []
    }
    publicNetworkAccess: 'Enabled'
  }
}

resource openai_model_resource 'Microsoft.CognitiveServices/accounts/deployments@2022-12-01' = {
  parent: openai_service_resource
  name: openai_model_name
  properties: {
    model: {
      format: 'OpenAI'
      name: 'text-davinci-003'
      version: '1'
    }
    scaleSettings: {
      scaleType: 'Standard'
    }
  }
}

// End of OpenAI Service and Models

// Logic Apps Standard Hosting

resource logicapps_hosting_resource 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: logicapp_hosting_plan_name
  location: deployment_region
  sku: {
    name: 'WS1'
    tier: 'WorkflowStandard'
    size: 'WS1'
    family: 'WS'
    capacity: 1
  }
  kind: 'elastic'
  properties: {
    perSiteScaling: false
    elasticScaleEnabled: true
    maximumElasticWorkerCount: 20
    isSpot: false
    reserved: false
    isXenon: false
    hyperV: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    zoneRedundant: false
  }
}

resource logicapp_app_site_resource 'Microsoft.Web/sites@2022-09-01' = {
  name: logicapp_site_name
  location: deployment_region
  kind: 'functionapp,workflowapp'
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${managed_service_identity_resource.id}': {}
    }
  }
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: '${logicapp_site_name}.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${logicapp_site_name}.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    serverFarmId: logicapps_hosting_resource.id
    reserved: false
    isXenon: false
    hyperV: false
    vnetRouteAllEnabled: false
    vnetImagePullEnabled: false
    vnetContentShareEnabled: false
    siteConfig: {
      numberOfWorkers: 1
      acrUseManagedIdentityCreds: false
      alwaysOn: false
      http20Enabled: false
      functionAppScaleLimit: 0
      minimumElasticInstanceCount: 1
      functionsRuntimeScaleMonitoringEnabled: false
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storage_account_name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storage_account_resource.listKeys().keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~16'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'OPENAI_MODEL_NAME'
          value: openai_model_name
        }
        {
          name: 'OPENAI_INSTANCE_NAME'
          value: openai_service_name
        }
      ]
    }
    scmSiteAlsoStopped: false
    clientAffinityEnabled: false
    clientCertEnabled: false
    clientCertMode: 'Required'
    hostNamesDisabled: false
    containerSize: 1536
    dailyMemoryTimeQuota: 0
    httpsOnly: true
    redundancyMode: 'None'
    publicNetworkAccess: 'Enabled'
    storageAccountRequired: false
    keyVaultReferenceIdentity: managed_service_identity_resource.id
  }
}

// End of Logic Apps Standard Hosting

// Key Vault and Secret

resource keyvault_resource 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: open_ai_keyvault_name
  location: deployment_region
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: managed_service_identity_resource.properties.principalId
        permissions: {
          certificates: []
          keys: []
          secrets: [
            'Get'
          ]
        }
      }
    ]
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enableRbacAuthorization: false
    provisioningState: 'Succeeded'
    publicNetworkAccess: 'Enabled'
  }
}

resource keyvault_secret_resource 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyvault_resource
  name: api_key_name
  properties: {
    attributes: {
      enabled: true
    }
    value: openai_service_resource.listKeys().key1
  }
}

// End of Key Vault and Secret

// Storage Account

resource storage_account_resource 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storage_account_name
  location: deployment_region
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {
    defaultToOAuthAuthentication: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}

// End of Storage Account

// Logic App Connections

resource connections_keyvault_name_resource 'Microsoft.Web/connections@2016-06-01' = {
  name: connections_keyvault_name
  location: deployment_region
  properties: {
    displayName: 'openaikeyvaultconnection'
    api: {
      name: connections_keyvault_name
      displayName: 'Azure Key Vault'
      description: 'Azure Key Vault is a service to securely store and access secrets.'
      iconUri: 'https://connectoricons-prod.azureedge.net/releases/v1.0.1623/1.0.1623.3210/keyvault/icon.png'
      brandColor: '#0079d6'
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', deployment_region, 'keyvault')
      type: 'Microsoft.Web/locations/managedApis'
    }
    testLinks: []
  }
}

resource connections_salesforce_name_resource 'Microsoft.Web/connections@2016-06-01' = {
  name: connections_salesforce_name
  location: deployment_region
  properties: {
    displayName: 'sample@contoso.com'
    customParameterValues: {}
    nonSecretParameterValues: {
      'token:LoginUri': 'https://login.salesforce.com'
      salesforceApiVersion: 'v41'
    }
    api: {
      name: 'salesforce'
      displayName: 'Salesforce'
      description: 'The Salesforce Connector provides an API to work with Salesforce objects.'
      iconUri: 'https://connectoricons-prod.azureedge.net/releases/v1.0.1624/1.0.1624.3220/salesforce/icon.png'
      brandColor: '#1EB8EB'
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', deployment_region, 'salesforce')
      type: 'Microsoft.Web/locations/managedApis'
    }
  }
}

// End Logic App Connections
