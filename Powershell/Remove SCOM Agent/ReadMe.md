##SYNOPSIS
    This script was designed to help with forcibly removing the SCOM Agent.

##DESCRIPTION
    If there are issues in removing the SCOM Agent, this script may be able to help forcibly remove the application from the server.
    Commands and references used in the script are taken from a SCOM 2019 agent installation and may be different in other versions.

    This is not 100% foolproof nor does it guarantee complete removal of all components, the intent is to remove as many _obvious_ references
    as possible so that the machine is no longer recognized to have an agent installed, or had one previously.

    This script will attempt to remove all registered services, performance counters, DLLs, and program files. This script makes direct deletions
    from the registry and file system.

    One external file is REQUIRED: RegistryKeys.txt

##NOTES
    This script assumes:
        - You are running this script as an Administrator
        - You have exhausted other options for agent removal
        - You have a full backup/snapshot/etc. of this machine and the registry in particular
        - You assume all responsibility for what happens when you run this script - USE AT YOUR OWN RISK
        - The creator and Microsoft is not liable for any damage or loss done with this script
        - You have vetted the validity of this script and is approved to use in your environment

##NOTICE
    By using this script, you in no way hold the author or Microsoft responsible for any damage or loss occured to the systems it is run on.
    You agree to have validated the script in its entirety and vetted it to be safe to use, assuming all responsibility for any ensuing issues.

##AUTHOR
    Lorne Sepaugh (lornesepaugh@microsoft.com)