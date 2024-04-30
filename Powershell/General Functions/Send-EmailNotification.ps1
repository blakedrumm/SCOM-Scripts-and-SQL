<#
    .SYNOPSIS
        Sends an email notification using SMTP.

    .DESCRIPTION
        This function facilitates email sending using specified SMTP server configurations, offering enhanced security features over the 'Send-MailMessage' cmdlet. It provides robust authentication options by supporting both direct credential input and 
        PSCredential objects. Additionally, this function ensures secure email transmission through the enforcement of SSL/TLS protocols for SMTP connections and by handling passwords exclusively as secure strings. It also supports sending emails with 
        attachments and HTML content, catering to a variety of messaging needs.

    .PARAMETER EmailUsername
        The username for the SMTP server.

    .PARAMETER EmailPassword
        The password for the SMTP server, should be passed as a secure string.

    .PARAMETER Credential
        An optional PSCredential object that contains the user's credentials to authenticate to the SMTP server.

    .PARAMETER From
        The email address of the sender.

    .PARAMETER To
        An array of recipient email addresses.

    .PARAMETER Cc
        An optional array of CC recipient email addresses.

    .PARAMETER Subject
        The subject of the email.

    .PARAMETER Body
        The body of the email. Can be plain text or HTML based on the IsBodyHtml flag.

    .PARAMETER SMTPServer
        The SMTP server address.

    .PARAMETER SMTPPort
        The port number of the SMTP server. Default is 587.

    .PARAMETER Attachment
        An optional file path for an email attachment.

    .PARAMETER IsBodyHtml
        A boolean indicating whether the email body should be treated as HTML.

    .EXAMPLE
        PS C:\> Send-EmailNotification -Credential (Get-Credential) -From "sender@example.com" -To "receiver@example.com","other@example.com" -Subject "Test Email" -Body "This is a test email." -SMTPServer "smtp.example.com" -SMTPPort 587

    .EXAMPLE
        PS C:\> Send-EmailNotification -EmailUsername "sender@example.com" -EmailPassword (ConvertTo-SecureString "Passw0rd" -AsPlainText -Force) -From "sender@example.com" -To "receiver@example.com" -Subject "Hello" -Body "Welcome!" -SMTPServer "smtp.example.com" -SMTPPort 465 -IsBodyHtml $true

    .NOTES
        This function requires appropriate network permissions to access the SMTP server.

    .AUTHOR
        Blake Drumm (blakedrumm@microsoft.com)

    .CREATED
        April 23rd, 2024

    .MODIFIED
        April 30th, 2024

    .LINK
        My personal blog: https://blakedrumm.com/
#>

#Email Function
function Send-EmailNotification
{
	param
	(
		[System.String]$EmailUsername,
		[System.Security.SecureString]$EmailPassword,
		[System.Management.Automation.PSCredential]$Credential,
		#Either utilize $Credential or $EmailUsername and $EmailPassword.
		[System.String]$From,
		[System.String[]]$To,
		[System.String[]]$Cc,
		[System.String]$Subject,
		[System.String]$Body,
		[System.String]$SMTPServer,
		[System.String]$SMTPPort = '587',
		[System.String]$Attachment,
		[boolean]$IsBodyHtml
	)
	
function Test-TCPConnection {
    [CmdletBinding()]
    param (
        [string]$IPAddress,
        [int]$Port,
        [int]$Timeout = 1000,
        [int]$RetryCount = 3
    )
    
    $attempt = 0
    while ($attempt -lt $RetryCount) {
        try {
            $tcpclient = New-Object System.Net.Sockets.TcpClient
            $connect = $tcpclient.BeginConnect($IPAddress, $Port, $null, $null)
            $wait = $connect.AsyncWaitHandle.WaitOne($Timeout, $false)
            if (!$wait) {
                throw "Connection timeout"
            }
            $tcpclient.EndConnect($connect)
            $tcpclient.Close()
            return $true
        }
        catch {
            $tcpclient.Close()
            if ($attempt -eq $RetryCount - 1) {
                if ($ErrorActionPreference -ne 'SilentlyContinue' -and $ErrorActionPreference -ne 'Ignore') {
                    # If it's the last attempt and error action is not to ignore or silently continue, throw an exception
                    throw "Failed to connect to $IPAddress on port $Port after $RetryCount attempts. Error: $_"
                }
            }
            Start-Sleep -Seconds 1  # Optional: sleep 1 second between retries
        }
        $attempt++
    }
    return $false
}
	
	try
	{
		# Start progress
		$progressParams = @{
			Activity	    = "Sending Email"
			Status		    = "Preparing to send email"
			PercentComplete = 0
		}
		Write-Progress @progressParams
		
		# Create a new MailMessage object
		$MailMessage = New-Object System.Net.Mail.MailMessage
		$MailMessage.From = $From
		$To.ForEach({ $MailMessage.To.Add($_) })
		$Cc.ForEach({ $MailMessage.CC.Add($_) })
		$MailMessage.Subject = $Subject
		$MailMessage.Body = $Body
		$MailMessage.IsBodyHtml = $IsBodyHtml
		
		# Handle attachment if specified
		if ($Attachment -ne $null -and $Attachment -ne '')
		{
			# Update progress
			$progressParams.Status = "Adding attachments"
			$progressParams.PercentComplete = 20
			Write-Progress @progressParams
			$MailMessage.Attachments.Add((New-Object System.Net.Mail.Attachment($Attachment)))
		}
		else
		{
			# Update progress
			$progressParams.Status = "Not adding any attachments"
			$progressParams.PercentComplete = 20
			Write-Progress @progressParams
		}
		
		# Update progress
		$progressParams.Status = "Setting up SMTP client to: $SMTPServer`:$SMTPPort"
		$progressParams.PercentComplete = 40
		Write-Progress @progressParams
		
		# Example usage
		Test-TCPConnection -IPAddress $SMTPServer -Port $SMTPPort -ErrorAction Stop | Out-Null
		
		# Create SMTP client
		$SmtpClient = New-Object System.Net.Mail.SmtpClient($SMTPServer, $SMTPPort)
		$SmtpClient.EnableSsl = $true
		if ($Credential)
		{
			$SmtpClient.Credentials = $Credential
		}
		else
		{
			$SmtpClient.Credentials = New-Object System.Net.NetworkCredential($EmailUsername, $EmailPassword)
		}
		
		# Update progress
		$progressParams.Status = "Sending email"
		$progressParams.PercentComplete = 60
		Write-Progress @progressParams
		
		# Send the email
		$SmtpClient.Send($MailMessage)
		
		# Final progress update
		$progressParams.Status = "Email sent successfully!"
		$progressParams.PercentComplete = 100
		Write-Progress @progressParams
		Write-Output "Email sent successfully!"
	}
	catch
	{
		Write-Warning @"
Exception while sending email notification. $_
"@
	}
	finally
	{
		if ($MailMessage)
		{
			$MailMessage.Dispose()
		}
		if ($SmtpClient)
		{
			$SmtpClient.Dispose()
		}
		Write-Progress -Activity "Sending Email" -Status "Completed" -Completed
	}
}

#=========================================================
# Example 1
Send-EmailNotification -Credential (Get-Credential) -From 'your-email@gmail.com' -To 'recipient-email@domain.com' -Subject "Subject Name" -Body "Hello!" -SmtpServer 'smtp.server.com' -SMTPPort 465

#=========================================================
# Example 2
Send-EmailNotification -EmailUsername 'your-email@gmail.com' -EmailPassword (ConvertTo-SecureString 'yourpassword' -AsPlainText -Force) -From 'your-email@gmail.com' -To 'recipient-email@domain.com' -Subject "Subject Name" -Body @"
Hello!

Welcome!
"@ -SmtpServer 'smtp.server.com'

#=========================================================
