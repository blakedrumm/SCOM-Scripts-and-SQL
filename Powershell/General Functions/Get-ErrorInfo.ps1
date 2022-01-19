[CmdLetBinding()]
param
(
    [Parameter(ValueFrompipeline)]
    [Management.Automation.ErrorRecord]$errorRecord
)
<#
Example 1:
    try
    {
        Stop-Service -Name someservice -ErrorAction Stop
    }  
    catch 
    {
        $_ | Get-ErrorInfo
    }
    
Example 2:
    $result = Get-ChildItem -Path C:\Windows -Filter *.ps1 -Recurse -ErrorAction SilentlyContinue -ErrorVariable myErrors
    $myErrors | Get-ErrorInfo
#>
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
