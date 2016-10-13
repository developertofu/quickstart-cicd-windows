[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Source,

    [Parameter(Mandatory=$true)]
    [string]$Destination,

    [Parameter(Mandatory=$false)]
    [string]$ServerSideEncryptionMethod
)

function Get-S3BucketName {
    param(
        [Parameter(Mandatory=$true)]
        [string]$S3Uri
    )

    return ($S3Uri -split '/')[2]
}

function Get-S3Key {
    param(
        [Parameter(Mandatory=$true)]
        [string]$S3Uri
    )

    $bucketName = Get-S3BucketName -S3Uri $S3Uri

    return $S3Uri.Substring(("s3://$bucketName/").Length)
}

try {
    $ErrorActionPreference = "Stop"

    Start-Transcript -Path c:\cfn\log\Upload-File.ps1.txt -Append

    $parentDir = Split-Path $Source -Parent
    if (-not (Test-Path $parentDir)) {
        New-Item -Path $parentDir -ItemType directory -Force | Out-Null
    }

    $qualifier = Split-Path $Destination -Qualifier
    if ($qualifier -eq "s3:") {
        $tries = 5
        while ($tries -ge 1) {
            try {
                $params =  @{
                    BucketName = Get-S3BucketName -S3Uri $Destination
                    Key = Get-S3Key -S3Uri $Destination
                    File = $Source
                }
                if ($ServerSideEncryptionMethod) {
                    $params.Add("ServerSideEncryption", $ServerSideEncryptionMethod)
                }
                Write-S3Object @params
                break
            }
            catch {
                $tries--
                Write-Verbose "Exception:"
                Write-Verbose "$_"
                if ($tries -lt 1) {
                    throw $_
                }
                else {
                    Write-Verbose "Failed upload. Retrying again in 5 seconds"
                    Start-Sleep 5
                }
            }
        }
    } else {
        throw "$Source is not a valid S3 destination"
    }
}
catch {
    Write-Verbose "$($_.exception.message)@ $(Get-Date)"
    $_ | Write-AWSQuickStartException
}
