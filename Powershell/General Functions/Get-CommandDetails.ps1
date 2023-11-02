# -------------------------------------------------------------------------------
# Author: Blake Drumm (blakedrumm@microsoft.com)
# Date Created: November 1st, 2023
# Edit line 7 if you want to change the module or command to get information on.
# -------------------------------------------------------------------------------
# Get details of commands in a specific module
$commandDetailsList = foreach ($function in (Get-Command -Module OperationsManager)) {
    
    # Determine the input types based on parameters accepting pipeline input
    $inputTypes = $function.Parameters.Values | Where-Object {
        $_.Attributes | Where-Object {
            $_ -is [System.Management.Automation.ParameterAttribute] -and ($_.ValueFromPipeline -or $_.ValueFromPipelineByPropertyName)
        }
    } | ForEach-Object { $_.ParameterType.FullName } | Sort-Object -Unique
    
    # Create a custom object for each function
    $functionDetails = [PSCustomObject]@{
        Name         = $function.Name
        InputType    = if ($inputTypes) { $inputTypes } else { 'None' }
        OutputType   = if ($function.OutputType) { $function.OutputType.Name } else { 'None' }
        Parameters   = @()
    }
    
    # Get parameter details
    foreach ($parameterName in $function.Parameters.Keys) {
        $parameter = $function.Parameters[$parameterName]
        
        # Retrieve aliases for the parameter
        $aliasAttribute = $parameter.Attributes | Where-Object { $_ -is [System.Management.Automation.AliasAttribute] }
        $aliases = if ($aliasAttribute -and $aliasAttribute.AliasNames) {
            $aliasAttribute.AliasNames -join ', '
        } else {
            'None'
        }

        # Retrieve default value of the parameter
        $defaultValue = if ($null -ne $parameter.DefaultValue -and $parameter.DefaultValue -ne '') {
            $parameter.DefaultValue
        } else {
            'None'
        }
        
        # Check for wildcard support
        $wildcardSupport = $parameter.Attributes | Where-Object {
            $_ -is [System.Management.Automation.ParameterAttribute] -and $_.SupportsWildcards
        }

        # Check for pipeline input support
        $pipelineInput = $parameter.Attributes | Where-Object {
            $_ -is [System.Management.Automation.ParameterAttribute] -and ($_.ValueFromPipeline -or $_.ValueFromPipelineByPropertyName)
        }
        $pipelineInputType = 'None'
        if ($pipelineInput.ValueFromPipeline) {
            $pipelineInputType = 'ByValue'
        } elseif ($pipelineInput.ValueFromPipelineByPropertyName) {
            $pipelineInputType = 'ByPropertyName'
        }

        # Check if the parameter has a specific position
        $positionAttribute = $parameter.Attributes | Where-Object {
            $_ -is [System.Management.Automation.ParameterAttribute] -and $_.Position -ne -2147483648
        }
        $position = if ($positionAttribute) { $positionAttribute.Position } else { 'Named' }

        # Create a custom object for each parameter
        $paramDetails = [PSCustomObject]@{
            Name                   = $parameterName
            Type                   = $parameter.ParameterType.FullName
            DefaultValue           = $defaultValue
            Required               = $parameter.Attributes.Mandatory
            AcceptsWildcardChars   = $wildcardSupport -ne $null
            AcceptsPipelineInput   = $pipelineInputType
            Position               = $position
            Aliases                = $aliases
        }

        # Add the parameter details object to the function details
        $functionDetails.Parameters += $paramDetails
    }

    # Return the custom object for the function
    $functionDetails
}

# Output the details or store them in a variable for further processing
$commandDetailsList
