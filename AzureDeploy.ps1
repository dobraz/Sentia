Connect-AzureRmAccount
$azContext = Get-AzureRmContext
$azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
$profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
$token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
$authHeader = @{
  'Authorization'='Bearer ' + $token.AccessToken
}
#Get Azure SubscriptionID
$SubscriptionID=(Get-AzureRmSubscription).Id
#Create a resource group
$ResourceGroup = New-AzureRmResourceGroup -Name SentiaResourceGroup -Location "West Europe"
$ResourceGroup
#Set Tags for resource Group
$RGTags = Set-AzureRmResourceGroup -Name SentiaResourceGroup -Tag @{Environment="Test";Company="Sentia"}
$RGTags
#Create storage account and virtual network
$Resources = New-AzureRmResourceGroupDeployment -Name ExampleDeployment -ResourceGroupName SentiaResourceGroup -TemplateUri https://raw.githubusercontent.com/dobraz/Sentia/master/azuredeployStrNet.json -TemplateParameterUri https://raw.githubusercontent.com/dobraz/Sentia/master/Parameters.json
$Resources
#Create array of Resorce Types for Resource Provider Microsoft.Network
$resourceTypesNetworkArray=@((Get-AzureRmResourceProvider -ProviderNamespace Microsoft.network).ResourceTypes.ResourceTypeName)
$resourceTypesNetworkArray = $resourceTypesNetworkArray | ForEach-Object {"Microsoft.Network/$_"}
#Create array of Resorce Types for Resource Provider Microsoft.Storage
$resourceTypesStorageArray=@((Get-AzureRmResourceProvider -ProviderNamespace Microsoft.storage).ResourceTypes.ResourceTypeName)
$resourceTypesStorageArray = $resourceTypesStorageArray | ForEach-Object {"Microsoft.Storage/$_"}
#Create array of Resorce Types for Resource Provider Microsoft.Compute
$resourceTypesComputeArray=@((Get-AzureRmResourceProvider -ProviderNamespace Microsoft.compute).ResourceTypes.ResourceTypeName)
$resourceTypesComputeArray = $resourceTypesComputeArray | ForEach-Object {"Microsoft.Compute/$_"}
#Create array that is combined of arrays for Microsoft.Network, Microsoft.Storage and Microsoft.Compute
$ResourceTypesArray=$resourceTypesNetworkArray+$resourceTypesStorageArray+$resourceTypesComputeArray
$DefinitionBody=@{
 "properties"=@{
    "displayName"="Allowed resource types"
    "description"="This policy enables you to specify the resource types that your organization can deploy."
    "parameters"=@{
      "listOfResourceTypesAllowed"=@{
        "type"="Array"
        "metadata"=@{
          "description"="The list of resource types that can be deployed."
          "displayName"="Allowed resource types"
	  "strongType"="resourceTypes"
        }
      }
    }
    "policyRule"=@{
      "if"=@{
        "not"=@{
          "field"="type"
          "in"="[parameters('listOfResourceTypesAllowed')]"
        }
      }
      "then"=@{
        "effect"="deny"
      }
    }
  }
}
$RestDefinition = @{
    Method      = 'PUT'
    Uri         = "https://management.azure.com/subscriptions/$SubscriptionID/providers/Microsoft.Authorization/policyDefinitions/AllowedResourceTypesv2?api-version=2018-03-01"
    ContentType = "application/json"
    Headers     = $authHeader
    Body        = $DefinitionBody | ConvertTo-Json -Depth 50
}
#PolicyAssignment using REST API
Invoke-RestMethod @RestDefinition
$AssignBody=@{
 "properties"=@{
    "displayName"="Enforce resource Types"
    "description"= "Force resource types to compute, network and storage"
    "metadata"=@{
      "assignedBy"="Dominik Obraz"
    }
    "policyDefinitionId"="/subscriptions/$SubscriptionID/providers/Microsoft.Authorization/policyDefinitions/AllowedResourceTypesv2"
    "parameters"=@{
      "listOfResourceTypesAllowed"=@{
        "value"=($ResourceTypesArray)
      }
    }
  }
}
$RestAssign = @{
    Method      = 'PUT'
    Uri         = 'https://management.azure.com/subscriptions/$SubscriptionID/resourceGroups/SentiaResourceGroup/providers/Microsoft.Authorization/policyAssignments/Newassignment?api-version=2018-03-01'
    ContentType = "application/json"
    Headers     = $authHeader
    Body        = $AssignBody | ConvertTo-Json -Depth 50
}
Invoke-RestMethod @RestAssign