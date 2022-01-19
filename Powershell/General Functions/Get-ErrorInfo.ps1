[CmdLetBinding()]
param
(
    [Parameter(ValueFrompipeline)]
    [Management.Automation.ErrorRecord]$errorRecord
)


process {

    # From http://community.idera.com/powershell/powertips/b/tips/posts/demystifying-error-handling


    $info = [PSCustomObject]@{
        Exception = $errorRecord.Exception.Message
        Reason    = $errorRecord.CategoryInfo.Reason
        Target    = $errorRecord.CategoryInfo.TargetName
        Script    = $errorRecord.InvocationInfo.ScriptName
        Line      = $errorRecord.InvocationInfo.ScriptLineNumber
        Column    = $errorRecord.InvocationInfo.OffsetInLine
        Date      = Get-Date
        User      = $env:username
    }
    
    $info
}
