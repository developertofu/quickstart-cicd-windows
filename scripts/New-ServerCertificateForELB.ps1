[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$ServerCertificateName
)

try {
    $ErrorActionPreference = "Stop"

    Start-Transcript -Path c:\cfn\log\New-ServerCertificateForELB.ps1.txt -Append

    Unblock-File -Path C:\cfn\downloads\BouncyCastle.Crypto.dll
    Add-Type -Path C:\cfn\downloads\BouncyCastle.Crypto.dll

    $PrivateKeyOutputFile = "C:\cfn\config\MyPrivateKeyCert.PEM"
    $CertificateBodyOutputFile = "C:\cfn\config\MyCertificateBody.PEM"

    $rsaKeyGenerator = New-Object Org.BouncyCastle.Crypto.Generators.RsaKeyPairGenerator
    $secureRandom = New-Object Org.BouncyCastle.Security.SecureRandom
    $rsaKeyGeneratorParms = New-Object Org.BouncyCastle.Crypto.KeyGenerationParameters($secureRandom,2048)
    $rsaKeyGenerator.Init($rsaKeyGeneratorParms)
    $keys = [Org.BouncyCastle.Crypto.AsymmetricCipherKeyPair] $rsaKeyGenerator.GenerateKeyPair()

    $textWriter = New-Object System.IO.StringWriter
    $pemWriter = New-Object Org.BouncyCastle.OpenSsl.PemWriter $textWriter
    $pemWriter.WriteObject($keys.Private)
    $textWriter.ToString() | Out-File $PrivateKeyOutputFile

    $bcCert = New-Object Org.BouncyCastle.x509.X509V3CertificateGenerator

    $random = New-Object System.Random

    $bcCert.SetSerialNumber([Org.BouncyCastle.Math.BigInteger]::ProbablePrime(120,$random))
    $bcCert.SetSubjectDN("CN=*.elb.amazonaws.com")
    $bcCert.SetIssuerDN("CN=*.elb.amazonaws.com")
    $bcCert.SetNotAfter([DateTime]::Now.AddYears(5))
    $bcCert.SetNotBefore([DateTime]::Now.AddDays(-1))
    $bcCert.SetSignatureAlgorithm("MD5WithRSA")
    $bcCert.SetPublicKey($keys.Public)

    $newCert = $bcCert.Generate($keys.Private)

    $cert = [Org.BouncyCastle.Security.DotNetUtilities]::ToX509Certificate($newCert)
    
    $out = New-Object String[] -ArgumentList 3
 
    $out[0] = "-----BEGIN CERTIFICATE-----"
    $out[1] = [System.Convert]::ToBase64String($cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert), [System.Base64FormattingOptions]::InsertLineBreaks)
    $out[2] = "-----END CERTIFICATE-----"
 
    [System.IO.File]::WriteAllLines($CertificateBodyOutputFile,$out)

    Publish-IAMServerCertificate -ServerCertificateName $ServerCertificateName -CertificateBody (Get-Content -Raw $CertificateBodyOutputFile) -PrivateKey (Get-Content -Raw $PrivateKeyOutputFile)

    Remove-Item $PrivateKeyOutputFile

}
catch {
    Write-Verbose "$($_.exception.message)@ $(Get-Date)"
    $_ | Write-AWSQuickStartException
}