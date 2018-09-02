This repository contains a Powershell script AzureDeploy.ps1 that:
- Creates a Resource Group in West Europe
- Creates a Storage Account in the above created Resource Group, using encryption and an unique name, starting with the prefix 'sentia' 
- Creates a Virtual Network in the above created Resource Group with three subnets, using 172.16.0.0/12 as the address prefix 
- Applies the following tags to the resource group: Environment='Test', Company='Sentia' 
- Create a policy definition using the REST API to restrict the resourcetypes to only allow: compute, network and storage resourcetypes 
- Assigns the policy definition using the REST API to the subscription and resource group you created previously

Script calls the following json files as Template and Template Parameters for the Resource Group:
azureeployStrNet.json
Parameters.json

Assumptions:
 - subnets for the Virtual Network are 172.16.0.0/24, 172.16.1.0/24 and 172.16.2.0/24

Also included:
ResourceRESTPolicy.json - json file for Policy Definition using REST API
ResourceRESTPolicyAssignement.json - file for Policy Assignement using REST API
