Configuration InstallIIS
{

Param ( [string] $nodeName, [string] $vmNumber, [string] $backendCert, [string] $backendCertPw, [string] $backendCertDnsName, [string] $webConfigPath, [string] $defaultHtmPath )

Import-DscResource -ModuleName PSDesiredStateConfiguration

Node $nodeName
  {
    WindowsFeature WebServerRole
    {
      Name = "Web-Server"
      Ensure = "Present"
    }
    WindowsFeature WebManagementConsole
    {
      Name = "Web-Mgmt-Console"
      Ensure = "Present"
    }
    WindowsFeature WebManagementService
    {
      Name = "Web-Mgmt-Service"
      Ensure = "Present"
    }
    WindowsFeature ASPNet45
    {
      Name = "Web-Asp-Net45"
      Ensure = "Present"
    }
    WindowsFeature HTTPRedirection
    {
      Name = "Web-Http-Redirect"
      Ensure = "Present"
    }
    WindowsFeature CustomLogging
    {
      Name = "Web-Custom-Logging"
      Ensure = "Present"
    }
    WindowsFeature LogginTools
    {
      Name = "Web-Log-Libraries"
      Ensure = "Present"
    }
    WindowsFeature RequestMonitor
    {
      Name = "Web-Request-Monitor"
      Ensure = "Present"
    }
    WindowsFeature Tracing
    {
      Name = "Web-Http-Tracing"
      Ensure = "Present"
    }
    WindowsFeature BasicAuthentication
    {
      Name = "Web-Basic-Auth"
      Ensure = "Present"
    }
    WindowsFeature WindowsAuthentication
    {
      Name = "Web-Windows-Auth"
      Ensure = "Present"
    }
    WindowsFeature ApplicationInitialization
    {
      Name = "Web-AppInit"
      Ensure = "Present"
    }
    Package UrlRewrite
    {
        Ensure = "Present"
        Name = "IIS URL Rewrite Module 2"
        Path = "http://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi"
        ProductId = "9BCA2118-F753-4A1E-BCF3-5A820729965C"
        DependsOn = "[WindowsFeature]WebServerRole"
    }
    Script DownloadWebDotConfig
    {
        TestScript = {
            Test-Path "C:\inetpub\wwwroot\web.config"
        }
        SetScript ={
            $dest = "C:\inetpub\wwwroot\web.config"
            Invoke-WebRequest $using:webConfigPath -OutFile $dest
        }
        GetScript = {@{Result = "DownloadWebDotConfig"}}
        DependsOn = "[WindowsFeature]WebServerRole"
    }
    Script DownloadDefaultDotHtm
    {
        TestScript = {
            Test-Path "C:\inetpub\wwwroot\default.htm"
        }
        SetScript ={
            $dest = "C:\inetpub\wwwroot\default.htm"
            Invoke-WebRequest $using:defaultHtmPath -OutFile $dest
        }
        GetScript = {@{Result = "DownloadDefaultDotHtm"}}
        DependsOn = "[WindowsFeature]WebServerRole"
    }
    Script InstallCert
    {
        TestScript = {$false}
        SetScript ={
            $certPath = "C:\internal.pfx"
            [Io.File]::WriteAllBytes($certPath, [System.Convert]::FromBase64String($using:backendCert))
            Import-PfxCertificate -FilePath $certPath -CertStoreLocation Cert:\LocalMachine\My -password $(ConvertTo-SecureString -String $using:backendCertPw -Force -AsPlainText)
        }
        GetScript = {@{Result = "InstallCert"}}
        DependsOn = "[WindowsFeature]WebServerRole"
    }
    Script CertBinding
		{
			GetScript = {@{Result = "CertBinding"}}
			TestScript = {$false}
			SetScript ={
				$certPath = "cert:\LocalMachine\My"			
				$certObj = Get-ChildItem -Path $certPath -DNSName $using:backendCertDnsName
				if($certObj)
				{
					New-WebBinding -Name "Default Web Site" -IP "*" -Port 443 -Protocol https					
					$certWThumb = $certPath + '\' + $certObj.Thumbprint 
					cd IIS:\SSLBindings
					get-item $certWThumb | new-item 0.0.0.0!443
				}				
			}
			DependsOn  = "[Script]InstallCert"
		}
  }
}