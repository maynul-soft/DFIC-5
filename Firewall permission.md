
[WinEventLog://Security]
disabled =0

New-NetFirewallRule `
-DisplayName "Splunk Lab Receiver" `
-Direction Inbound `
-Protocol TCP `
-LocalPort 9997 `
-RemoteAddress Any `
-Profile Any `
-Action Allow


Get-NetFirewallRule -DisplayName "Splunk Lab Receiver"

Listen: Get-Nettcpconnection -stat Listen -Localhost 9997


Restart-Service Splunkd
