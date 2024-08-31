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

function Invoke-SQLSelectQuery {
    [CmdletBinding()]
    param(
        # Parameter help description
        [Parameter(Mandatory,
        ParameterSetName='FromFile')]
        [Parameter(Mandatory,
        ParameterSetName='FromString')]
        [system.data.SqlClient.SQLConnection]
        $SQLConnection,
        # Parameter help description
        [Parameter(Mandatory,
        ParameterSetName='FromString')]
        [string]
        $SelectQueryText,
        # Parameter help description
        [Parameter(Mandatory,
        ParameterSetName='FromFile')]
        [string]
        $SQLQueryFile,
        [Parameter(Mandatory=$False,
        ParameterSetName='FromFile')]
        [Parameter(Mandatory=$False,
        ParameterSetName='FromString')]
        [switch]
        $CloseConnection
    )

    
    $query = [string]::Empty
    if($PSCmdlet.ParameterSetName -eq 'FromString'){
        if(-not([string]::IsNullOrWhiteSpace($SelectQueryText) -and [string]::IsNullOrEmpty($SelectQueryText))){
            $query = $SelectQueryText
        }else{
            throw [System.Management.Automation.PSArgumentNullException] "query string passed null or empty"
        }
        
    }else{
        if(Test-Path $SQLQueryFile){
            $query = Get-Content $SQLQueryFile -Raw    
        }else{
            throw [System.IO.FileNotFoundException] "$SQLQueryFile not found."
        }
    }

    $sqlCommand = New-Object System.Data.SqlClient.SqlCommand($query, $SQLConnection)


    if($SQLConnection.State -eq [System.Data.ConnectionState]::Closed){
        $SQLConnection.Open()
    }

    $sqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $sqlCommand
    $dataset = New-Object System.Data.DataSet
    $sqlAdapter.Fill($dataset) | Out-Null

    if($CloseConnection){
        $SQLConnection.Close()
    }

    return ,$dataset
}


# Export only the functions using PowerShell standard verb-noun naming.
Export-ModuleMember -Function *-*