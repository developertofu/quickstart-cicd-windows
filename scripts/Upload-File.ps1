[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Source,

    [Parameter(Mandatory=$true)]
    [string]$Destination
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

    $parentDir = Split-Path $Source -Parent
    if (-not (Test-Path $parentDir)) {
        New-Item -Path $parentDir -ItemType directory -Force | Out-Null
    }

    $qualifier = Split-Path $Destination -Qualifier
    if ($qualifier -eq "s3:") {
        $tries = 5
        while ($tries -ge 1) {
            try {
                Write-S3Object -BucketName (Get-S3BucketName -S3Uri $Destination) -Key (Get-S3Key -S3Uri $Destination) -File $Source -ErrorAction Stop
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
    $_ | Write-AWSQuickStartException
}
