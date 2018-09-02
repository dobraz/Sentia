Connect-AzureRmAccount
$azContext = Get-AzureRmContext
$azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
$profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
$token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
$authHeader = @{
  'Authorization'='Bearer ' + $token.AccessToken
}
#Create a resource group
$ResourceGroup = New-AzureRmResourceGroup -Name SentiaResourceGroup -Location "West Europe"
$ResourceGroup
#Set Tags for resource Group
$RGTags = Set-AzureRmResourceGroup -Name SentiaResourceGroup -Tag @{Environment="Test";Company="Sentia"}
$RGTags
#Create storage account and virtual network
$Resources = New-AzureRmResourceGroupDeployment -Name ExampleDeployment -ResourceGroupName SentiaResourceGroup -TemplateUri https://raw.githubusercontent.com/dobraz/Sentia/master/azuredeployStrNet.json -TemplateParameterUri https://raw.githubusercontent.com/dobraz/Sentia/master/Parameters.json
$Resources
$resourceTypesNetworkArray=@((Get-AzureRmResourceProvider -ProviderNamespace Microsoft.network).ResourceTypes.ResourceTypeName)
$resourceTypesNetworkArray = $resourceTypesNetworkArray | ForEach-Object {"Microsoft.Network/$_"}
$resourceTypesStorageArray=@((Get-AzureRmResourceProvider -ProviderNamespace Microsoft.storage).ResourceTypes.ResourceTypeName)
$resourceTypesStorageArray = $resourceTypesStorageArray | ForEach-Object {"Microsoft.Storage/$_"}
$resourceTypesComputeArray=@((Get-AzureRmResourceProvider -ProviderNamespace Microsoft.compute).ResourceTypes.ResourceTypeName)
$resourceTypesComputeArray = $resourceTypesComputeArray | ForEach-Object {"Microsoft.Compute/$_"}
$ResourceTypesArray=$resourceTypesNetworkArray+$resourceTypesStorageArray+$resourceTypesComputeArray
#Policy Definition
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
    Uri         = 'https://management.azure.com/subscriptions/f929a8a8-6e38-454f-9968-dd60ab98b301/providers/Microsoft.Authorization/policyDefinitions/AllowedResourceTypesv2?api-version=2018-03-01'
    ContentType = "application/json"
    Headers     = $authHeader
    Body        = $DefinitionBody | ConvertTo-Json -Depth 50
}
#PolicyAssignment
Invoke-RestMethod @RestDefinition
$AssignBody=@{
 "properties"=@{
    "displayName"="Enforce resource Types"
    "description"= "Force resource types to compute, network and storage"
    "metadata"=@{
      "assignedBy"="Dominik Obraz"
    }
    "policyDefinitionId"="/subscriptions/f929a8a8-6e38-454f-9968-dd60ab98b301/providers/Microsoft.Authorization/policyDefinitions/AllowedResourceTypesv2"
    "parameters"=@{
      "listOfResourceTypesAllowed"=@{
        "value"=($ResourceTypesArray)
      }
    }
  }
}
$RestAssign = @{
    Method      = 'PUT'
    Uri         = 'https://management.azure.com/subscriptions/f929a8a8-6e38-454f-9968-dd60ab98b301/providers/Microsoft.Authorization/policyAssignments/Newassignment?api-version=2018-03-01'
    ContentType = "application/json"
    Headers     = $authHeader
    Body        = $AssignBody | ConvertTo-Json -Depth 50
}
Invoke-RestMethod @RestAssign