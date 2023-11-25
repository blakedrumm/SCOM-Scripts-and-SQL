# -------------------------------------------------------------------------------
# Author: Blake Drumm (blakedrumm@microsoft.com)
# Date Created: November 1st, 2023
# Date Modified: November 24th, 2023
# Edit line 8 if you want to change the module or command to get information on.
# -------------------------------------------------------------------------------
# Get details of commands in a specific module
$commandDetailsList = foreach ($function in (Get-Command -Module OperationsManager)) {
    
    # Identify mandatory parameters that accept pipeline input
    $mandatoryPipelineInputParams = $function.Parameters.Values | Where-Object {
        $_.Attributes | Where-Object {
            $_ -is [System.Management.Automation.ParameterAttribute] -and 
            $_.Mandatory -and 
            ($_.ValueFromPipeline -or $_.ValueFromPipelineByPropertyName)
        }
    }

    # Initialize an array to hold formatted parameter details strings
    $paramDetailsList = @()

    # Get parameter details and format them into strings
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
        $pipelineInputType = if ($pipelineInput) { 
            if ($pipelineInput.ValueFromPipeline) {
                'ByValue'
            } elseif ($pipelineInput.ValueFromPipelineByPropertyName) {
                'ByPropertyName'
            } else {
                'None'
            }
        } else {
            'None'
        }

        # Check if the parameter has a specific position
        $positionAttribute = $parameter.Attributes | Where-Object {
            $_ -is [System.Management.Automation.ParameterAttribute] -and $_.Position -ne -2147483648
        }
        $position = if ($positionAttribute) { $positionAttribute.Position } else { 'Named' }

        # Format each parameter detail into a string
        $paramDetailString = "Name: $($parameterName)`n" +
                             "Type: $($parameter.ParameterType.FullName)`n" +
                             "DefaultValue: $($defaultValue)`n" +
                             "Required: $($parameter.Attributes.Mandatory)`n" +
                             "AcceptsWildcardChars: $($wildcardSupport -ne $null)`n" +
                             "AcceptsPipelineInput: $($pipelineInputType)`n" +
                             "Position: $($position)`n" +
                             "Aliases: $($aliases)"

        # Add the formatted string to the list
        $paramDetailsList += $paramDetailString
    }

    # Generate example for piping object with mandatory parameters
    $examplePiping = if ($mandatoryPipelineInputParams) {
        $exampleObjectProps = $mandatoryPipelineInputParams | ForEach-Object {
            "$($_.Name) = <" + $_.ParameterType.Name + ">"
        }
        "[PSCustomObject]@{" + ($exampleObjectProps -join "; ") + "} | $($function.Name)"
    } else {
        "No mandatory pipeline input parameters available"
    }

    # Create a custom object for the function with all collected details
    [PSCustomObject]@{
        Name                = $function.Name
        InputType           = if ($mandatoryPipelineInputParams) { $mandatoryPipelineInputParams.ParameterType.FullName | Sort-Object -Unique } else { 'None' }
        OutputType          = if ($function.OutputType) { $function.OutputType.Name } else { 'None' }
        Parameters          = $paramDetailsList -join "`n`n"
        PipelineInputParams = $mandatoryPipelineInputParams.Name -join ', '
        ExampleUsage        = $examplePiping
    }
}

# Output the details in a structured format
$commandDetailsList | Format-List
