Configuration iis_setup {

    Param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]     
        [string]$nodeName
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node $nodeName
    {
        LocalConfigurationManager {
            RebootNodeIfNeeded = $true
        }
        
        # WindowsFeature WebServerRole {
        #     Name   = "Web-Server"
        #     Ensure = "Present"
        # }
        # WindowsFeature WebManagementService {
        #     Name      = "Web-Mgmt-Service"
        #     Ensure    = "Present"
        #     DependsOn = '[WindowsFeature]WebServerRole'
        # }
        # WindowsFeature WebManagementConsole {
        #     Name      = "Web-Mgmt-Console"
        #     Ensure    = "Present"
        #     DependsOn = '[WindowsFeature]WebServerRole'
        # }
        # WindowsFeature WebManagementTools {
        #     Name      = "Web-Mgmt-Tools"
        #     Ensure    = "Present"
        #     DependsOn = '[WindowsFeature]WebServerRole'
        # }

        WindowsFeature IIS {
            Ensure = "Present"
            Name   = "Web-Server"
        }
        WindowsFeature IISManagementTools {
            Ensure    = "Present"
            Name      = "Web-Mgmt-Tools"
            DependsOn = '[WindowsFeature]IIS'
        }
        WindowsFeature IISManagementConsole {
            Ensure    = "Present"
            Name      = "Web-Mgmt-Console"
            DependsOn = '[WindowsFeature]IIS'
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
    }
}