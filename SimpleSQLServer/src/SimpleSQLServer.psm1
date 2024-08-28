# Implement your module commands in this script.
$env:SIMPLESQLSERVER_CONNECTION_STRING = ""

function BuildServerConStringSQLAuth([string]$server, [string]$db, [string]$user, [string]$pas) {
    $connectionString = "Server=$server;Database=$db;User Id=$user;Password=$pas;"
    return $connectionString
}

function Build-ConnectionString {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName="Server")]
        [Parameter(Mandatory, ParameterSetName="ServerTrusted")]
        [string]
        $Server,
        [Parameter(Mandatory, ParameterSetName="DataSource")]
        [Parameter(Mandatory, ParameterSetName="DataSourceIntegratedSecurity")]
        [string]
        $DataSource,
        [Parameter(Mandatory, ParameterSetName="Server")]
        [Parameter(Mandatory, ParameterSetName="ServerTrusted")]
        [Parameter(Mandatory, ParameterSetName="DataSource")]
        [Parameter(Mandatory, ParameterSetName="DataSourceIntegratedSecurity")]
        [string]
        $Database,
        [Parameter(ParameterSetName="ServerTrusted")]
        [switch]
        $Trusted,
        [Parameter(ParameterSetName="DataSourceIntegratedSecurity")]
        [switch]
        $IntegratedSecurity,
        [Parameter(Mandatory=$false, ParameterSetName="Server")]
        [Parameter(Mandatory=$false, ParameterSetName="ServerTrusted")]
        [Parameter(Mandatory=$false, ParameterSetName="DataSource")]
        [Parameter(Mandatory=$false, ParameterSetName="DataSourceIntegratedSecurity")]
        [string]
        $UserName,
        [Parameter(Mandatory=$false, ParameterSetName="Server")]
        [Parameter(Mandatory=$false, ParameterSetName="ServerTrusted")]
        [Parameter(Mandatory=$false, ParameterSetName="DataSource")]
        [Parameter(Mandatory=$false, ParameterSetName="DataSourceIntegratedSecurity")]
        [pscredential]
        $Password,
        [Parameter(Mandatory=$false, ParameterSetName="Server")]
        [Parameter(Mandatory=$false, ParameterSetName="ServerTrusted")]
        [Parameter(Mandatory=$false, ParameterSetName="DataSource")]
        [Parameter(Mandatory=$false, ParameterSetName="DataSourceIntegratedSecurity")]
        [switch]
        $SetAsEnviromentConnectionString
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

        if($SetAsEnviromentConnectionString){
            Set-EnvironmentConnectionString -ConnectionString $connectionString
        }else{
            return $connectionString
        }
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