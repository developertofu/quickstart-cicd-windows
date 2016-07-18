try {
    $ErrorActionPreference = "Stop"

    Start-Transcript -Path c:\cfn\log\Install-MSBuild.ps1.txt -Append
    
    Start-Process "C:\cfn\downloads\BuildTools_Full.exe" -ArgumentList '/q /l C:\Projects\BuildTools-Install-Log.txt' -Wait
}
catch {
    Write-Verbose "$($_.exception.message)@ $(Get-Date)"
    $_ | Write-AWSQuickStartException
}