class Website {
    [DscProperty(Key)]
    [string] $name

    [DscProperty(Mandatory)]
    [string] $host
}

Configuration iis_setup {

    Param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]     
        [string]$nodeName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]     
        [Website[]]$websites,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]   
        [string]$backendCertificate,

        # [Parameter(Mandatory = $true)]
        # [ValidateNotNullOrEmpty()]   
        [string]$backendCertificatePwd        
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName @{ModuleName = "xWebAdministration"; ModuleVersion = "3.2.0" }

    Node $nodeName {
        LocalConfigurationManager {
            RebootNodeIfNeeded = $true
        }
        
        WindowsFeature WebServerRole {
            Name   = "Web-Server"
            Ensure = "Present"
        }
        WindowsFeature WebManagementService {
            Name      = "Web-Mgmt-Service"
            Ensure    = "Present"
            DependsOn = '[WindowsFeature]WebServerRole'
        }
        WindowsFeature WebManagementConsole {
            Name      = "Web-Mgmt-Console"
            Ensure    = "Present"
            DependsOn = '[WindowsFeature]WebServerRole'
        }
        WindowsFeature WebManagementTools {
            Name      = "Web-Mgmt-Tools"
            Ensure    = "Present"
            DependsOn = '[WindowsFeature]WebServerRole'
        }

        # WindowsFeature IIS {
        #     Ensure = "Present"
        #     Name   = "Web-Server"
        # }
        # WindowsFeature IISManagementTools {
        #     Ensure    = "Present"
        #     Name      = "Web-Mgmt-Tools"
        #     DependsOn = '[WindowsFeature]IIS'
        # }
        # WindowsFeature IISManagementConsole {
        #     Ensure    = "Present"
        #     Name      = "Web-Mgmt-Console"
        #     DependsOn = '[WindowsFeature]IISManagementTools'
        # }

        WindowsFeature ASPNet45 {
            Name   = "Web-Asp-Net45"
            Ensure = "Present"
        }
       
        WindowsFeature HTTPRedirection {
            Name   = "Web-Http-Redirect"
            Ensure = "Present"
        }

        WindowsFeature CustomLogging {
            Name   = "Web-Custom-Logging"
            Ensure = "Present"
        }

        WindowsFeature LogginTools {
            Name   = "Web-Log-Libraries"
            Ensure = "Present"
        }

        WindowsFeature RequestMonitor {
            Name   = "Web-Request-Monitor"
            Ensure = "Present"
        }

        WindowsFeature Tracing {
            Name   = "Web-Http-Tracing"
            Ensure = "Present"
        }

        WindowsFeature BasicAuthentication {
            Name   = "Web-Basic-Auth"
            Ensure = "Present"
        }

        WindowsFeature WindowsAuthentication {
            Name   = "Web-Windows-Auth"
            Ensure = "Present"
        }

        WindowsFeature ApplicationInitialization {
            Name   = "Web-AppInit"
            Ensure = "Present"
        }

        #Install URL Rewrite module for IIS
        Package UrlRewrite {
            Name      = "IIS URL Rewrite Module 2"
            DependsOn = "[WindowsFeature]ASPNet45"
            Ensure    = "Present"
            
            Path      = "https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi"
            Arguments = "/quiet"
            ProductId = "EB675D0A-2C95-405B-BEE8-B42A65D23E11"
        }

        # Stop the default website
        xWebsite DefaultSite
        {
            Ensure       = 'Present'
            Name         = 'Default Web Site'
            State        = 'Stopped'
            PhysicalPath = 'C:\inetpub\wwwroot'
            DependsOn    = '[WindowsFeature]ASPNet45'

        }

        Script InstallCertificate {
            TestScript = { $false }
            SetScript  = {
                $path = "C:\mmgroup-solutions.pfx"
                [Io.File]::WriteAllBytes($path, [System.Convert]::FromBase64String($using:backendCertificate))
                Import-PfxCertificate -FilePath $path -CertStoreLocation Cert:\LocalMachine\My ##-Password $(ConvertTo-SecureString -String $using:backendCertificatePwd -Force -AsPlainText)
            }
            GetScript  = { @{Result = "InstallCertificate" } }
            DependsOn  = '[WindowsFeature]WebServerRole'
        }

        foreach ($website in $websites) {
            File $website.name {
                Type            = 'Directory'
                DestinationPath = 'C:\inetpub\wwwroot\' + $website.name
                Ensure          = "Present"
                DependsOn       = '[WindowsFeature]ASPNet45'
            }
    
            xWebAppPool $website.name {
                Name                  = $website.name
                Ensure                = "Present"
                State                 = 'Started'
                autoStart             = $true
                enable32BitAppOnWin64 = $true
                managedPipelineMode   = 'Integrated'
                managedRuntimeLoader  = 'webengine4.dll'
                managedRuntimeVersion = 'v4.0'
                idleTimeout           = (New-TimeSpan -Minutes 20).ToString()
                idleTimeoutAction     = 'Terminate'
                maxProcesses          = 1
            }

            xWebsite $website.name {
                Name            = $website.host
                Ensure          = 'Present'
                State           = 'Started'
                ApplicationPool = $website.name
                PhysicalPath = 'C:\inetpub\wwwroot\' + $website.name
                BindingInfo     = @( MSFT_xWebBindingInformation {
                        Protocol             = "HTTPS"
                        Port                 = 443
                        HostName             = $website.host
                        CertificateStoreName = "MY"
                        CertificateSubject   = "CN=mmgroup.solutions"
                        # CertificateThumbprint = "D97BEAADDADFCC803A9645723E45B2563FC4A0FE"
                    }
                )
                DependsOn   = '[File]' + $website.name
            }
             
            # Script $website.name {
            #     GetScript  = { @{Result = "CertificateBinding" } }
            #     TestScript = { $false }
            #     SetScript  = {
            #         $path = "Cert:\LocalMachine\My"
            #         $cert = Get-ChildItem -Path $path -DNSName "mmgroup.solutions"
            #         if ($cert) {
            #             New-WebBinding -Name $using:website.host -IPAddress "*" -Port 443 -Protocol https -HostHeader $using:website.host
            #             $thumb = $path + '\' + $cert.Thumbprint
            #             cd IIS:\SSLBindings
            #             Get-Item $thumb | New-Item 0.0.0.0!443
            #         }
            #     }
            #     DependsOn  = '[Script]InstallCertificate'
            # }
        }
    }
}