# SMTP server settings
$SmtpServer = "us-smtp-outbound-1.mimecast.com"
$SmtpPort = 587

# Email details
$From = "youremail@example.com"
$To = "recipientemail@example.com"
$Subject = "Test Email"
$Body = "This is a test email sent from PowerShell."

# Credentials for Windows Integrated Authentication (typically NTLM for SMTP)
$Credential = Get-Credential

# Send the email
Send-MailMessage -From $From -To $To -Subject $Subject -Body $Body -SmtpServer $SmtpServer -Port $SmtpPort -UseSsl -Credential $Credential
