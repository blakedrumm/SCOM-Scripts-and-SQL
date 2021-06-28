$events = (Get-EventLog -LogName 'Operations Manager' -Source 'OpsMgr Connector' | Where-Object {$_.EventID -eq 20000})
$message = $events | %{ ($_|Select-Object -Property Message -ExpandProperty Message) }
$message | %{ ($_ -split "Requesting Device Name : ")[1]} | Select-Object -Unique | Sort-Object
