New-NetFirewallRule `
-DisplayName "Splunk Lab Receiver" `
-Direction Inbound `
-Protocol TCP `
-LocalPort 9997 `
-RemoteAddress Any `
-Profile Any `
-Action Allow





Get-NetFirewallRule -DisplayName "Splunk Lab Receiver"
