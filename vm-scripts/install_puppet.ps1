if ([System.IO.File]::Exists("$Env:LOCALAPPDATA\install_puppet.done")) {
    Write-Output "Puppet already installed"
} else {
    Write-Output 'Disable Security scanning...'
    Set-MpPreference -DisableArchiveScanning $true -DisableRealtimeMonitoring $true
    $uri = "https://downloads.puppetlabs.com/windows/puppet8/puppet-agent-x64-latest.msi"
    $out = "c:\windows\temp\puppet-agent-x64-latest.msi"
    Write-Output 'Downloading Puppet Agent...'
    Invoke-WebRequest -Uri $uri -OutFile $out
    Write-Output 'Installing Puppet Agent...'
    Start-Process C:\Windows\System32\msiexec.exe -ArgumentList "/qn /norestart /i $out" -wait
    Write-Output 'Puppet installed'
    New-Item -ItemType file $Env:LOCALAPPDATA\install_puppet.done
}
