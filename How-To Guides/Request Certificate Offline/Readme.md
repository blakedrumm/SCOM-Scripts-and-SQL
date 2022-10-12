# Create your own offline Certificate Request for Workgroup Machine
In the below example we are assuming your machine is named **IIS-2019**.

Create a new file on your machine and name it:
> IIS-2019-CertReq.inf

In the file edit it to include something similar the following:
```
[NewRequest]
Subject="CN=IIS-2019,OU=Servers,O=Support Team,L=Charlotte,S=North Carolina,C=US" ; SCOM only uses the first CN Name.
Exportable=TRUE ; Private key is exportable (required for Server Authentication)
KeyLength=2048
KeySpec=1 ; Key Exchange – Required for encryption
KeyUsage=0xf0 ; Digital Signature, Key Encipherment
MachineKeySet=TRUE

; Optionally include the Certificate Template
; [RequestAttributes]
; CertificateTemplate="OperationsManager"

[EnhancedKeyUsageExtension]
OID=1.3.6.1.5.5.7.3.1 ; Server Authentication
OID=1.3.6.1.5.5.7.3.2  ; Client Authentication
```
Open an Administrator Command Prompt and navigate to where you saved the above file. \
Run the following:
```
Certreq -New -f .\IIS-2019-CertReq.inf .\IIS-2019-CertRequest.req
```

Upload the above to your Certificate Authority.
