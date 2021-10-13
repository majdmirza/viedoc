[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name "NuGet" -Force
Install-Module -Name xWebAdministration -Force

configuration SampleIISInstall
{

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -Module xWebAdministration
   
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

    File viedoc4folder {
        Type            = 'Directory'
        DestinationPath = 'C:\inetpub\wwwroot\viedoc4'
        Ensure          = "Present"
        DependsOn       = '[WindowsFeature]ASPNet45'
    }

    xWebsite DevWebsite
    {
        Ensure       = 'Present'
        Name         = 'viedoc4'
        State        = 'Started'
        PhysicalPath = 'C:\inetpub\wwwroot\viedoc4'
        BindingInfo  = @( MSFT_xWebBindingInformation
            {
                Protocol = "HTTP"
                Port     = 80
                HostName = 'vm-app1-4jtquxj7hbmfy.westeurope.cloudapp.azure.com'
            }

        )
        DependsOn    = '[File]viedoc4folder'

    } 

}

# Compile the configuration file to a MOF format
SampleIISInstall

# Run the configuration on localhost
Start-DscConfiguration -Path .\SampleIISInstall -Wait -Force -Verbose