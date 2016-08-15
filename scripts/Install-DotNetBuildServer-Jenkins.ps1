[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$JobName
)

try {
    $ErrorActionPreference = "Stop"

    Start-Transcript -Path c:\cfn\log\Install-DotNetBuildServer-Jenkins.ps1.txt -Append
      
    Unblock-File -Path C:\cfn\downloads\jenkins\jenkins.msi
    $Arguments = "/q", "/l", "c:\cfn\log\Install-Jenkins-Log.txt"
    Start-Process "C:\cfn\downloads\jenkins\jenkins.msi" -ArgumentList $Arguments -Wait
    $Arguments = "/q", "/l", "c:\cfn\log\Install-MsBuild-Log.txt"
    Start-Process "C:\cfn\downloads\BuildTools_Full.exe" -ArgumentList $Arguments -Wait
    
    New-Item "C:\Program Files (x86)\Jenkins\jenkins.install.InstallUtil.lastExecVersion" -type file -value "2.0" -force

    $jenkinsConfig = [xml](Get-Content "C:\Program Files (x86)\Jenkins\jenkins.xml")
    $oldjavaparms = $jenkinsConfig.service.arguments
    $jenkinsConfig.service.arguments = "-Djava.awt.headless=true -Dhudson.diyChunking=false " + $oldjavaparms
    $jenkinsConfig.Save("C:\Program Files (x86)\Jenkins\jenkins.xml")
    
    $jenkinsCLIConfig = [xml](Get-Content "C:\Program Files (x86)\Jenkins\config.xml")
    $jenkinsCLIConfig.hudson.slaveAgentPort = "0"
    $jenkinsCLIConfig.Save("C:\Program Files (x86)\Jenkins\config.xml")
    
    Copy-Item "C:\cfn\downloads\msbuild.hpi" "C:\Program Files (x86)\Jenkins\plugins"
    Copy-Item "C:\cfn\downloads\aws-codepipeline.hpi" "C:\Program Files (x86)\Jenkins\plugins"
    Copy-Item "C:\cfn\downloads\groovy.hpi" "C:\Program Files (x86)\Jenkins\plugins"

    Restart-Service "Jenkins"

    $svc = Get-Service "Jenkins"
    $timer = 0
    while($svc.Status -ne 'Running')
    {   
       Start-Sleep -s 10
       if($timer -le 300)
       {
          $timer = $timer + 10
       }
       else
       {
          throw "Jenkins service took longer than 5 minutes to reach running state."
       }
    }

    $adminpassword = Get-Content "C:\Program Files (x86)\Jenkins\secrets\initialAdminPassword"
    
    cd "C:\Program Files (x86)\Jenkins\jre\bin"

    cmd /c 'java.exe -jar "C:\Program Files (x86)\Jenkins\war\WEB-INF\jenkins-cli.jar" -s http://localhost:8080 groovy --username admin --password $adminpassword = < c:\cfn\config\Create-Jenkins-User.groovy'
    #Remove-Item "C:\cfn\scripts\Create-Jenkins-User.groovy"
    
    cmd /c 'java.exe -jar "C:\Program Files (x86)\Jenkins\war\WEB-INF\jenkins-cli.jar" -s http://localhost:8080 create-job $JobName --username admin --password $adminpassword < c:\cfn\config\config.xml'   
}
catch {
    Write-Verbose "$($_.exception.message)@ $(Get-Date)"
    $_ | Write-AWSQuickStartException
}