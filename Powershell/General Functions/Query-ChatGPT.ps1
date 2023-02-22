param
(
	$Question,
	$Tokens,
	[switch]$Notepad
)

#region ChatGPT-CoreCode
####put your key here
$script:OpenAI_Key = "zx-BvbAUZYXAWKB7QNmVPxuT3OlpkSJAzUGIqZ19qXiMZhkm0pC"
$logname = "c:\Windows\temp\ChatGPT-Logs.log"
function Invoke-GetTime
{
	Get-Date -Format yyyy-MM-dd-HH-mm-ss
}
function Write-Logs ($Level = 1, $Message, $type = " [ChatGPT]")
{
	if ($Level -eq 1)
	{
		$tempMessage = $(Invoke-GetTime) + $type + " [ info ]: "
		Write-Host -ForegroundColor Green  $Message
	}
	elseif ($Level -eq 2)
	{
		$tempMessage = $(Invoke-GetTime) + $type + " [Error]: "
		Write-Host -ForegroundColor Red  $Message
	}
	elseif ($Level -eq 3)
	{
		$tempMessage = $(Invoke-GetTime) + $type + " [result]: The response is as follows："
		Write-Host -ForegroundColor White  $Message
		$tempMessage += "`n"
		
	}
	elseif ($Level -eq 4)
	{
		$tempMessage = $(Invoke-GetTime) + $type + " [result]: issue："
		
	}
	$tempMessage += $Message
	
	$tempMessage | Out-File $logname -Encoding utf8 -Append -Force
	if ($Message -eq "End of execution")
	{ "*************************************`n" | Out-File $logname -Encoding utf8 -Append -Force }
	
}

function Query-ChatGPT ($Question, $Tokens = 1000, [switch]$Notepad)
{
	Write-Logs -Message "Start loading"
	$key = $script:openai_key
	$url = "https://api.openai.com/v1/completions"
	$body = [pscustomobject]@{
		"model"  = "text-davinci-003"
		"prompt" = "$question"
		"temperature" = .2
		"max_tokens" = $tokens
		"top_p"  = 1
		"n"	     = 1
		"frequency_penalty" = 1
		"presence_penalty" = 1
	}
	$header = @{
		"Authorization" = "Bearer $key"
		"Content-Type"  = "application/json; charset=utf-8"
	}
	$bodyJSON = ($body | ConvertTo-Json)
	$bodyJSON = [System.Text.Encoding]::UTF8.GetBytes($bodyJSON)
	$res = Invoke-RestMethod $url -Method 'POST' -Headers $header -Body $bodyJSON
	$global:string = $res.choices.text.trim()
	$dstEncoding = [System.Text.Encoding]::GetEncoding('iso-8859-1')
	$srcEncoding = [System.Text.Encoding]::UTF8
	$result = $srcEncoding.GetString([System.Text.Encoding]::Convert($srcEncoding, $dstEncoding, $srcEncoding.GetBytes($string)))
	
	Write-Logs -Message $question -Level 4
	Write-Logs -Message $result -Level 3
	Write-Logs -Message "End of execution"
	if ($Notepad)
	{
		notepad $logname
	}
	
}

#endregion

Clear-Host;

if ($Question)
{
	Query-ChatGPT -Question $Question -Tokens:$Tokens -Notepad:$Notepad
}
else
{
	Query-ChatGPT -Question "How do you create a monitor in SCOM?"
}
