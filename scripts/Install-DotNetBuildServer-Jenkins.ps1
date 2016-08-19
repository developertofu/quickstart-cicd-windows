try {
    $ErrorActionPreference = "Stop"

    Start-Transcript -Path c:\cfn\log\Install-DotNetBuildServer-Jenkins.ps1.txt -Append
      
    Unblock-File -Path C:\cfn\downloads\jenkins.msi
    $Arguments = "/q", "/l", "c:\cfn\log\Install-Jenkins-Log.txt"
    Start-Process "C:\cfn\downloads\jenkins.msi" -ArgumentList $Arguments -Wait
    $Arguments = "/q", "/l", "c:\cfn\log\Install-MsBuild-Log.txt"
    Start-Process "C:\cfn\downloads\BuildTools_Full.exe" -ArgumentList $Arguments -Wait
    
    New-Item "C:\Program Files (x86)\Jenkins\jenkins.install.InstallUtil.lastExecVersion" -type file -value "2.0" -force

    $jenkinsConfig = [xml](Get-Content "C:\Program Files (x86)\Jenkins\jenkins.xml")
    $oldjavaparms = $jenkinsConfig.service.arguments
    $jenkinsConfig.service.arguments = "-Djava.awt.headless=true -Dhudson.diyChunking=false " + $oldjavaparms
    $jenkinsConfig.Save("C:\Program Files (x86)\Jenkins\jenkins.xml")
    
    $jenkinsCLIConfig = [xml](Get-Content "C:\Program Files (x86)\Jenkins\config.xml")
    $jenkinsCLIConfig.hudson.slaveAgentPort = "8181"
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
    
    cd "C:\Program Files (x86)\Jenkins\jre\bin"

    Start-Sleep -s 10       

    $adminPassword = Get-Content("C:\Program Files (x86)\Jenkins\secrets\initialAdminPassword")

    $commandLine = 'java.exe -jar "C:\Program Files (x86)\Jenkins\war\WEB-INF\jenkins-cli.jar" -s http://localhost:8080 groovy --username admin --password ' + $adminPassword + ' = < c:\cfn\scripts\create-jenkins-user.groovy'

    cmd /c $commandLine
    
    Remove-Item "C:\cfn\scripts\Create-Jenkins-User.groovy"

    Restart-Service "Jenkins"
}
catch {
    Write-Verbose "$($_.exception.message)@ $(Get-Date)"
    $_ | Write-AWSQuickStartException
}