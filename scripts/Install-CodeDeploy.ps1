try {
    $ErrorActionPreference = "Stop"

    Start-Transcript -Path c:\cfn\log\Install-CodeDeploy.ps1.txt -Append
    
    Start-Process "C:\cfn\downloads\codedeploy-agent.msi" -ArgumentList '/quiet /l C:\cfn\log\host-agent-install-log.txt' -Wait
    
    $codeDeployServiceName = "codedeployagent"
    $codeDeployService = Get-Service $codeDeployServiceName
    if ($codeDeployService.Status -ne "Running") {
        Start-Service $codeDeployServiceName
    }
}
catch {
    Write-Verbose "$($_.exception.message)@ $(Get-Date)"
    $_ | Write-AWSQuickStartException
}