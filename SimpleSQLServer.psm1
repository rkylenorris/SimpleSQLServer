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
        $ConnectionString=$env:SIMPLESQLSERVER_CONNECTION_STRING
    )
    
    begin {
        if([string]::IsNullOrEmpty($ConnectionString) -or [string]::IsNullOrWhiteSpace($ConnectionString)){
            throw "Connection String is Empty"
        }
    }
    
    process {
        try{
            $connection = new-object system.data.SqlClient.SQLConnection($ConnectionString)
        }catch{
            Write-Error "SQL Connection Error: $_"
            return $null
        }
        
        try{
            $connection.Open()
        }catch{
            Write-Error "SQL Connection Error: $_"
            return $null
        }
        

        return $connection
    }
    
    end {
        
    }
}

function Invoke-SQLSelectQuery {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,
        ParameterSetName='FromFile')]
        [Parameter(Mandatory,
        ParameterSetName='FromString')]
        [system.data.SqlClient.SQLConnection]
        $SQLConnection,
        [Parameter(Mandatory,
        ParameterSetName='FromString')]
        [string]
        $SelectQueryText,
        [Parameter(Mandatory,
        ParameterSetName='FromFile')]
        [string]
        $SQLQueryFile,
        [Parameter(Mandatory=$False,
        ParameterSetName='FromFile')]
        [Parameter(Mandatory=$False,
        ParameterSetName='FromString')]
        [hashtable]$Parameters,
        [Parameter(Mandatory=$False,
        ParameterSetName='FromFile')]
        [Parameter(Mandatory=$False,
        ParameterSetName='FromString')]
        [switch]
        $CloseConnection
    )

    begin {    
        $query = [string]::Empty
        if($PSCmdlet.ParameterSetName -eq 'FromString'){
            if(-not([string]::IsNullOrWhiteSpace($SelectQueryText) -and [string]::IsNullOrEmpty($SelectQueryText))){
                $query = $SelectQueryText
            }else{
                throw [System.Management.Automation.PSArgumentNullException] "query string passed null or empty"
            }
            
        }else{
            if(Test-Path $SQLQueryFile){
                $query = [System.IO.File]::ReadAllText($SQLQueryFile)
            }else{
                throw [System.IO.FileNotFoundException] "$SQLQueryFile not found."
            }
        }
    }

    process {
        $sqlCommand = New-Object System.Data.SqlClient.SqlCommand($query, $SQLConnection)

        if($Parameters){
            $Parameters.Keys | ForEach-Object {
                $sqlCommand.Parameters.AddWithValue($key, $Parameters[$key]) | Out-Null
            }
        }

        $sqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $sqlCommand
        $dataset = New-Object System.Data.DataSet

        try{
            $sqlAdapter.Fill($dataset) | Out-Null
        }catch{
            Write-Error "SQL Adapter Fill Error: $_"
            if($CloseConnection){
                $SQLConnection.Close()
            }
            return $null
        }
        

        if($CloseConnection){
            $SQLConnection.Close()
        }

        return ,$dataset
    }

    end {

    }
}

function Invoke-SQLNonQuery {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
        ParameterSetName='FromFile')]
        [Parameter(Mandatory,
        ParameterSetName='FromString')]
        [system.data.SqlClient.SQLConnection]
        $SQLConnection,
        [Parameter(Mandatory,
        ParameterSetName='FromString')]
        [string]
        $QueryText,
        [Parameter(Mandatory,
        ParameterSetName='FromFile')]
        [string]
        $QueryFile,
        [Parameter(Mandatory=$False,
        ParameterSetName='FromFile')]
        [Parameter(Mandatory=$False,
        ParameterSetName='FromString')]
        [hashtable]$Parameters,
        [Parameter(Mandatory=$False,
        ParameterSetName='FromFile')]
        [Parameter(Mandatory=$False,
        ParameterSetName='FromString')]
        [switch]
        $CloseConnection
    )
    
    begin {
        $query = [string]::Empty
        if($PSCmdlet.ParameterSetName -eq 'FromString'){
            if(-not([string]::IsNullOrWhiteSpace($QueryText) -and [string]::IsNullOrEmpty($QueryText))){
                $query = $QueryText
            }else{
                throw [System.Management.Automation.PSArgumentNullException] "query string passed null or empty"
            }
            
        }else{
            if(Test-Path $QueryFile){
                $query = [System.IO.File]::ReadAllText($QueryFile)
            }else{
                throw [System.IO.FileNotFoundException] "$QueryFile not found."
            }
        }
    }
    
    process {
        $sqlCommand = New-Object System.Data.SqlClient.SqlCommand($query, $SQLConnection)

        if($Parameters){
            $Parameters.Keys | ForEach-Object {
                $sqlCommand.Parameters.AddWithValue($key, $Parameters[$key]) | Out-Null
            }
        }

        

        try {
            $sqlCommand.ExecuteNonQuery() | Out-Null
        }
        catch {
            Write-Error "SQL Execute Non Query Error: $_"
        }

        if($CloseConnection){
            $SQLConnection.Close()
        }
    }
    
    end {
        
    }
}

function Invoke-SQLBulkInsert {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [system.data.SqlClient.SQLConnection]
        $SQLConnection,
        [Parameter(Mandatory)]
        [string]
        $TableName,
        [Parameter(Mandatory)]
        [System.Data.DataTable]
        $DataTable,
        [Parameter(Mandatory=$false)]
        [switch]
        $CloseConnection
    )
    
    begin {
        
    }
    
    process {
        $bulkCopy = New-Object System.Data.SqlClient.SqlBulkCopy($SQLConnection)
        $bulkCopy.DestinationTableName = $TableName

        try{
            if($SQLConnection.State -eq [System.Data.ConnectionState]::Closed){
                $SQLConnection.Open()
            }

            $bulkCopy.WriteToServer($DataTable)

            if($CloseConnection){
                $SQLConnection.Close()
            }
        }catch{
            Write-Error "BulkInsert Error: $_"
        }finally{
            $bulkCopy.Dispose()
        }
    }
    
    end {
        
    }
}

# Export only the functions using PowerShell standard verb-noun naming.
Export-ModuleMember -Function *-*