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
Set-AzureRmResourceGroup -Name SentiaResourceGroup -Tag @{Environment="Test";Company="Sentia"}
#Create storage account and virtual network
New-AzureRmResourceGroupDeployment -Name ExampleDeployment -ResourceGroupName SentiaResourceGroup -TemplateUri https://github.com/dobraz/Sentia/blob/master/azuredeployStrNet.json -TemplateParameterUri https://github.com/dobraz/Sentia/blob/master/Parameters.json


