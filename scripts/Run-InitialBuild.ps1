[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$BucketName,

    [Parameter(Mandatory=$true)]
    [string]$BuildFilePath
)

try {
    $ErrorActionPreference = "Stop"

    Start-Transcript -Path c:\cfn\log\Run-InitialBuild.ps1.txt -Append

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo.FileName = "C:\Program Files (x86)\MSBuild\14.0\Bin\MSBuild.exe"
    $process.StartInfo.Arguments = "$BuildFilePath /p:BucketName=$BucketName /t:Build;Deploy"
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.RedirectStandardOutput = $true

    if($process.Start() ){
       $output = $process.StandardOutput.ReadToEnd()
       Write-Verbose $output
    }
    $process.WaitForExit()

    <#
       Start-Process "C:\Program Files (x86)\MSBuild\14.0\Bin\MSBuild.exe" -ArgumentList "$BuildFilePath /p:BucketName=$BucketName /t:Build;Deploy" -Wait
    #>
}
catch {
    Write-Verbose "$($_.exception.message)@ $(Get-Date)"
    $_ | Write-AWSQuickStartException
}