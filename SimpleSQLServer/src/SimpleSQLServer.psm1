# Implement your module commands in this script.
$env:SIMPLESQLSERVER_CONNECTION_STRING = ""
function Build-ConnectionString {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName="Server", Position=0)]
        [Parameter(Mandatory, ParameterSetName="ServerTrusted", Position=1)]
        [string]
        $Server,
        [Parameter(Mandatory, ParameterSetName="DataSource", Position=0)]
        [Parameter(Mandatory, ParameterSetName="DataSourceIntegratedSecurity", Position=1)]
        [string]
        $DataSource,
        [Parameter(Mandatory, ParameterSetName="Server", Position=1)]
        [Parameter(Mandatory, ParameterSetName="ServerTrusted", Position=2)]
        [Parameter(Mandatory, ParameterSetName="DataSource", Position=1)]
        [Parameter(Mandatory, ParameterSetName="DataSourceIntegratedSecurity", Position=2)]
        [string]
        $Database,
        [Parameter(Mandatory, ParameterSetName="ServerTrusted", Position=0)]
        [switch]
        $Trusted,
        [Parameter(Mandatory, ParameterSetName="DataSourceIntegratedSecurity", Position=0)]
        [switch]
        $IntegratedSecurity,
        [Parameter(Mandatory, ParameterSetName="Server", Position=2)]
        [Parameter(Mandatory=$false, ParameterSetName="ServerTrusted")]
        [Parameter(Mandatory, ParameterSetName="DataSource", Position=2)]
        [Parameter(Mandatory=$false, ParameterSetName="DataSourceIntegratedSecurity")]
        [string]
        $UserName,
        [Parameter(Mandatory, ParameterSetName="Server", Position=2)]
        [Parameter(Mandatory=$false, ParameterSetName="ServerTrusted")]
        [Parameter(Mandatory, ParameterSetName="DataSource", Position=2)]
        [Parameter(Mandatory=$false, ParameterSetName="DataSourceIntegratedSecurity")]
        [pscredential]
        $Password
    )
    
    begin {
        
    }
    
    process {
        if($PSCmdlet.ParameterSetName -like "Server*"){
            $connectionString = "Server=$server;Database=$Database;"
            if((-not($Trusted))){
                if(-not($UserName -and $Password)){
                    throw "Username and Password required, or use trusted connection"
                }
            }else{
                $connectionString += "Trusted_Connection=True;"
            }
        }elseif($PSCmdlet.ParameterSetName -like "DataSource*"){
            connectionString = "Server=$server;Database=$Database;"
            if(-not($IntegratedSecurity)){
                if(-not($UserName -and $Password)){
                    throw "Username and Password required, or use integrated security"
                }
            }else{
                $connectionString += "Integrated Security=SSPI;"
            }
        }
        if($UserName -and $Password){
            $connectionString += "User Id=$UserName;Password=$($Password.GetNetworkCredential().Password);"
        }

        return $connectionString
    }
    
    end {
        
    }
}

function Set-EnvironmentConnectionString {
    [CmdletBinding()]
    param (
        # Parameter help description
        [Parameter(Mandatory)]
        [string]
        $ConnectionString
    )
    
    begin {
        
    }
    
    process {
        $env:SIMPLESQLSERVER_CONNECTION_STRING = $ConnectionString
    }
    
    end {
        
    }
}


function New-SQLConnection {
    [CmdletBinding()]
    param (
        # sql server connection string
        [Parameter(Mandatory=$False)]
        [string]
        $ConnectionString=$env:SIMPLESQLSERVER_CONNECTION_STRING,
        [switch]
        $Open
    )
    
    begin {
        if([string]::IsNullOrEmpty($ConnectionString) -or [string]::IsNullOrWhiteSpace($ConnectionString)){
            throw "Connection String is Empty"
        }
    }
    
    process {
        $connection = new-object system.data.SqlClient.SQLConnection($ConnectionString)
        if($Open){
            $connection.Open()
        }
        return $connection
    }
    
    end {
        
    }
}



# Export only the functions using PowerShell standard verb-noun naming.
Export-ModuleMember -Function *-*