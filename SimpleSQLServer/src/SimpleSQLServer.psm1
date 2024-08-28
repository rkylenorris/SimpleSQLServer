# Implement your module commands in this script.
$env:SIMPLESQLSERVER_CONNECTION_STRING = ""

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

# TODO create sql select function, CRUD functions, bulk insert


# Export only the functions using PowerShell standard verb-noun naming.
Export-ModuleMember -Function *-*