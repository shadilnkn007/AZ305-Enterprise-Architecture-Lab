targetScope = 'managementGroup'

@description('The management group where governance policies will be deployed.')
param targetManagementGroupId string

@description('Azure regions allowed for this training environment.')
param allowedLocations array = [
  'centralindia'
  'southindia'
]

@description('The policy assignment effect.')
@allowed([
  'Audit'
  'Deny'
])
param policyEffect string = 'Audit'


// ------------------------------------------------------------
// Custom policy: Allowed Locations
// ------------------------------------------------------------

resource allowedLocationsPolicy 'Microsoft.Authorization/policyDefinitions@2025-03-01' = {
  name: 'az305-allowed-locations'
  properties: {
    displayName: 'AZ305 - Allowed Azure Locations'
    description: 'Restricts resources to the Azure regions approved for the AZ-305 enterprise lab.'
    policyType: 'Custom'
    mode: 'Indexed'

    parameters: {
      allowedLocations: {
        type: 'Array'
        metadata: {
          displayName: 'Allowed locations'
          description: 'Azure locations permitted for this lab.'
          strongType: 'location'
        }
      }

      effect: {
        type: 'String'
        metadata: {
          displayName: 'Policy effect'
          description: 'Audit or deny resources deployed outside the approved regions.'
        }
        allowedValues: [
          'Audit'
          'Deny'
        ]
      }
    }

    policyRule: {
      if: {
        allOf: [
          {
            field: 'location'
            notIn: '[parameters(''allowedLocations'')]'
          }
          {
            field: 'location'
            notEquals: 'global'
          }
        ]
      }
      then: {
        effect: '[parameters(''effect'')]'
      }
    }
  }
}


// ------------------------------------------------------------
// Assign Allowed Locations Policy
// ------------------------------------------------------------

resource allowedLocationsAssignment 'Microsoft.Authorization/policyAssignments@2025-03-01' = {
  name: 'az305-allowed-locations'
  properties: {
    displayName: 'AZ305 - Allowed Azure Locations'
    description: 'Allows resources only in Central India and South India.'
    policyDefinitionId: allowedLocationsPolicy.id

    parameters: {
      allowedLocations: {
        value: allowedLocations
      }
      effect: {
        value: policyEffect
      }
    }
  }
}


// ------------------------------------------------------------
// Custom policy: Required Tags
// ------------------------------------------------------------

resource requiredTagsPolicy 'Microsoft.Authorization/policyDefinitions@2025-03-01' = {
  name: 'az305-required-tags'
  properties: {
    displayName: 'AZ305 - Required Resource Tags'
    description: 'Audits resources that do not contain the required Environment, Project and Owner tags.'
    policyType: 'Custom'
    mode: 'Indexed'

    parameters: {
      requiredTags: {
        type: 'Array'
        metadata: {
          displayName: 'Required tags'
          description: 'Tags required on Azure resources.'
        }
      }

      effect: {
        type: 'String'
        metadata: {
          displayName: 'Policy effect'
          description: 'Audit or deny resources missing required tags.'
        }
        allowedValues: [
          'Audit'
          'Deny'
        ]
      }
    }

    policyRule: {
      if: {
        anyOf: [
          {
            field: 'tags[Environment]'
            exists: false
          }
          {
            field: 'tags[Project]'
            exists: false
          }
          {
            field: 'tags[Owner]'
            exists: false
          }
        ]
      }
      then: {
        effect: '[parameters(''effect'')]'
      }
    }
  }
}


// ------------------------------------------------------------
// Assign Required Tags Policy
// ------------------------------------------------------------

resource requiredTagsAssignment 'Microsoft.Authorization/policyAssignments@2025-03-01' = {
  name: 'az305-required-tags'
  properties: {
    displayName: 'AZ305 - Required Resource Tags'
    description: 'Requires Environment, Project and Owner tags.'
    policyDefinitionId: requiredTagsPolicy.id

    parameters: {
      requiredTags: {
        value: [
          'Environment'
          'Project'
          'Owner'
        ]
      }

      effect: {
        value: policyEffect
      }
    }
  }
}


// ------------------------------------------------------------
// Outputs
// ------------------------------------------------------------

output managementGroupId string = targetManagementGroupId
output allowedRegions array = allowedLocations
output governancePolicyEffect string = policyEffect
