<powershell>
# swap WinRM on to port 22
# Set-Item WSMan:\localhost\Listener\*\Port 22 -Force
# Set-Item WSMan:\localhost\Service\AllowUnencrypted True
# Set-Item WSMan:\localhost\Service\Auth\Basic True
# Restart-Service WinRm

param ( 
  [ValidateRange(1,65535)][int]$ListenerPort = 5986
)

New-NetFirewallRule -DisplayName "Allow WinRM on $ListenerPort" -Direction Inbound -Protocol TCP -LocalPort $ListenerPort

#Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force

# Don't set this before Set-ExecutionPolicy as it throws an error
$ErrorActionPreference = "stop"

& netsh advfirewall set allprofiles state off
if (-not $?) { throw "Failed to turn off Windows firewall" }

# Remove HTTP listener
Remove-Item -Path WSMan:\Localhost\listener\listener* -Recurse

Set-Item WSMan:\localhost\MaxTimeoutms 1800000
Set-Item WSMan:\localhost\Service\Auth\Basic $true

$hostn=hostname

$Cert = New-SelfSignedCertificate -CertstoreLocation Cert:\LocalMachine\My -DnsName $hostn -FriendlyName packer -NotAfter $([datetime]::now.AddHours(3))
New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $Cert.Thumbprint -Force
Set-Item WSMan:\localhost\Listener\*\Port $ListenerPort -Force

Restart-Service WinRm -verbose -Force -Confirm:$false

# Test a remoting connection to localhost, which should work.
$httpResult = Invoke-Command -Port $ListenerPort -ComputerName "localhost" -ScriptBlock {$env:COMPUTERNAME} -ErrorVariable httpError -ErrorAction SilentlyContinue
$httpsOptions = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck

$httpsResult = New-PSSession -Port $ListenerPort -UseSSL -ComputerName "localhost" -SessionOption $httpsOptions -ErrorVariable httpsError -ErrorAction SilentlyContinue

If ($httpResult -and $httpsResult)
{
    Write-Verbose "HTTP: Enabled | HTTPS: Enabled"
}
ElseIf ($httpsResult -and !$httpResult)
{
    Write-Verbose "HTTP: Disabled | HTTPS: Enabled"
}
ElseIf ($httpResult -and !$httpsResult)
{
    Write-Verbose "HTTP: Enabled | HTTPS: Disabled"
}
Else
{
    Throw "Unable to establish an HTTP or HTTPS remoting session."
}
</powershell>
