#edit line 2
$sigcheckPath = 'C:\Users\Administrator.contoso\Downloads\sigcheck.exe'
#dont edit below
$installdirectory = ((Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Console').InstallDirectory.Split('\') | Select-Object -SkipLast 1) -join ('\')
$sigpathsplit = $(($sigcheckPath.Split('\') | Select -SkipLast 1) -join '\')
& $sigcheckPath -c -w $sigpathsplit\ConsoleFiles.csv $installdirectory
