function Set-EnvironmentConnectionString {
    <#
    .SYNOPSIS
    Sets the environment variable for the SQL Server connection string.

    .DESCRIPTION
    The Set-EnvironmentConnectionString function allows you to set an environment variable that stores the SQL Server connection string. This connection string can be used by other functions that require a connection to the SQL Server.

    .PARAMETER ConnectionString
    The SQL Server connection string that will be stored in the environment variable. This parameter is mandatory.

    .EXAMPLE
    Set-EnvironmentConnectionString -ConnectionString "Server=myServerAddress;Database=myDataBase;User Id=myUsername;Password=myPassword;"
    This example sets the environment variable SIMPLESQLSERVER_CONNECTION_STRING to the specified connection string.

    .LINK
    New-SQLConnection, Invoke-SQLSelectQuery, Invoke-SQLNonQuery
    #>
    [CmdletBinding()]
    param (
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

New-Alias -Name scns -Value Set-EnvironmentConnectionString

function New-SQLConnection {
    <#
    .SYNOPSIS
    Creates a new SQL Server connection using the specified connection string.

    .DESCRIPTION
    The New-SQLConnection function establishes a connection to the SQL Server using the provided connection string. If no connection string is provided, it uses the connection string stored in the SIMPLESQLSERVER_CONNECTION_STRING environment variable.

    .PARAMETER ConnectionString
    The SQL Server connection string. If not provided, the function will use the value from the environment variable SIMPLESQLSERVER_CONNECTION_STRING.

    .EXAMPLE
    $connection = New-SQLConnection -ConnectionString "Server=myServerAddress;Database=myDataBase;User Id=myUsername;Password=myPassword;"
    This example creates a new SQL connection using the specified connection string.

    .LINK
    Set-EnvironmentConnectionString, Invoke-SQLSelectQuery, Invoke-SQLNonQuery
    #>
    [CmdletBinding()]
    param (
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

New-Alias -Name ncn -Value New-SQLConnection

function Invoke-SQLSelectQuery {
    <#
    .SYNOPSIS
    Executes a SQL SELECT query against the specified SQL connection.

    .DESCRIPTION
    The Invoke-SQLSelectQuery function executes a SQL SELECT query either from a provided string or a file. It returns the results in a DataSet.

    .PARAMETER SQLConnection
    The SQL Server connection object used to execute the query. This parameter is mandatory.

    .PARAMETER SelectQueryText
    The SQL SELECT query as a string. This parameter is mandatory when using the 'FromString' parameter set.

    .PARAMETER SQLQueryFile
    The path to a file containing the SQL SELECT query. This parameter is mandatory when using the 'FromFile' parameter set.

    .PARAMETER Parameters
    A hashtable of parameters to be passed to the SQL command. This parameter is optional.

    .PARAMETER CloseConnection
    A switch that indicates whether to close the SQL connection after executing the query. This parameter is optional.

    .EXAMPLE
    $results = Invoke-SQLSelectQuery -SQLConnection $connection -SelectQueryText "SELECT * FROM Users"
    This example executes a SELECT query to retrieve all records from the Users table.

    .EXAMPLE
    $results = Invoke-SQLSelectQuery -SQLConnection $connection -SQLQueryFile "C:\Queries\GetUsers.sql"
    This example executes a SELECT query from the specified SQL file.

    .LINK
    New-SQLConnection, Invoke-SQLNonQuery
    #>
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

New-Alias -Name sqlslt -Value Invoke-SQLSelectQuery

function Invoke-SQLNonQuery {
    <#
    .SYNOPSIS
    Executes a SQL non-query command against the specified SQL connection.

    .DESCRIPTION
    The Invoke-SQLNonQuery function executes a SQL command that does not return any results (e.g., INSERT, UPDATE, DELETE). It can read the command from either a string or a file.

    .PARAMETER SQLConnection
    The SQL Server connection object used to execute the command. This parameter is mandatory.

    .PARAMETER QueryText
    The SQL command as a string. This parameter is mandatory when using the 'FromString' parameter set.

    .PARAMETER QueryFile
    The path to a file containing the SQL command. This parameter is mandatory when using the 'FromFile' parameter set.

    .PARAMETER Parameters
    A hashtable of parameters to be passed to the SQL command. This parameter is optional.

    .PARAMETER CloseConnection
    A switch that indicates whether to close the SQL connection after executing the command. This parameter is optional.

    .EXAMPLE
    Invoke-SQLNonQuery -SQLConnection $connection -QueryText "DELETE FROM Users WHERE Id = 1"
    This example executes a DELETE command to remove a user with a specific ID.

    .EXAMPLE
    Invoke-SQLNonQuery -SQLConnection $connection -QueryFile "C:\Queries\DeleteUser.sql"
    This example executes a non-query command from the specified SQL file.

    .LINK
    New-SQLConnection, Invoke-SQLSelectQuery
    #>
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

New-Alias -Name sqlnq -Value Invoke-SQLNonQuery

function Invoke-SQLBulkInsert {
    <#
    .SYNOPSIS
    Performs a bulk insert of data into a specified SQL Server table.

    .DESCRIPTION
    The Invoke-SQLBulkInsert function allows you to perform a bulk insert operation into a SQL Server table using a DataTable object.

    .PARAMETER SQLConnection
    The SQL Server connection object used for the bulk insert. This parameter is mandatory.

    .PARAMETER TableName
    The name of the table into which the data will be inserted. This parameter is mandatory.

    .PARAMETER DataTable
    The DataTable object containing the data to be inserted. This parameter is mandatory.

    .PARAMETER CloseConnection
    A switch that indicates whether to close the SQL connection after the operation. This parameter is optional.

    .EXAMPLE
    Invoke-SQLBulkInsert -SQLConnection $connection -TableName "Users" -DataTable $dataTable
    This example performs a bulk insert of data from the DataTable into the Users table.

    .LINK
    New-SQLConnection
    #>
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

New-Alias -Name sqlblk -Value Invoke-SQLBulkInsert

function Invoke-TextQualifierRegex {
    <#
    .SYNOPSIS
    Removes text qualifiers from a specified line based on the delimiter.

    .DESCRIPTION
    The Invoke-TextQualifierRegex function creates regex expressions to remove text qualifiers (like quotes) from a line of text based on the specified delimiter.

    .PARAMETER Delimiter
    The delimiter used to separate values in the line. This parameter is mandatory and can be either "Comma", "Tab", or "Pipe".

    .PARAMETER Line
    The line of text from which to remove text qualifiers. This parameter is mandatory.

    .EXAMPLE
    $cleanedLine = Invoke-TextQualifierRegex -Delimiter "Comma" -Line '"value1","value2","value3"'
    This example removes quotes from the line, resulting in 'value1,value2,value3'.

    .LINK
    #>
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Comma", "Tab", "Pipe")]
        [string]$Delimiter,
        [Parameter(Mandatory = $true)]
        [string]
        $Line
    )

    $DelimiterCode = switch ($Delimiter) {
        'Comma' { "," }
        'Tab' { "\t" }
        'Pipe' { "\|" }
        Default { "" }
    }

    $regex_patterns = @{
        main  = '(?m)"([^' + $DelimiterCode + ']*?)"(?=' + $DelimiterCode + '|$)'
        inner = '(?<=' + $DelimiterCode + ')"'
    }

    $new_line = $Line
    $new_line = $new_line -replace $regex_patterns.main, '$1'
    $new_line = $new_line -replace $regex_patterns.inner, ''

    return $new_line
}

function Infer-DataType {
    <#
    .SYNOPSIS
    Infers the data type of a given value.

    .DESCRIPTION
    The Infer-DataType function analyzes a string value and determines its most appropriate .NET data type (int, double, datetime, bool, or string).

    .PARAMETER Value
    The string value for which to infer the data type. This parameter is mandatory.

    .EXAMPLE
    $type = Infer-DataType -Value "123"
    This example returns [int] as the inferred data type.

    .LINK
    #>
    param (
        [string]$Value
    )
    $today = Get-Date
    if ([int]::TryParse($Value, [ref]$null)) {
        return [int]
    }
    elseif ([double]::TryParse($Value, [ref]$null)) {
        return [double]
    }
    elseif ([datetime]::TryParse($Value, [ref]$today)) {
        return [datetime]
    }
    elseif ($Value -match '^(?i)(true|false)$') {
        return [bool]
    }
    else {
        return [string]
    }
}

function Import-CSVToDataTable {
    <#
    .SYNOPSIS
    Imports a CSV file into a DataTable.

    .DESCRIPTION
    The Import-CSVToDataTable function reads a CSV file and converts it into a DataTable object, allowing for easy manipulation of the data.

    .PARAMETER Path
    The path to the CSV file to be imported. This parameter is mandatory.

    .PARAMETER DelimiterChoice
    The delimiter used in the CSV file (Comma, Tab, or Pipe). This parameter is optional and defaults to "Comma".

    .PARAMETER StartRow
    The row number from which to start reading the CSV file. This parameter is optional and defaults to 0 (the first row).

    .PARAMETER Headers
    An array of strings representing the column headers. This parameter is optional.

    .EXAMPLE
    $dataTable = Import-CSVToDataTable -Path "C:\Data\mydata.csv" -DelimiterChoice "Comma"
    This example imports the CSV file into a DataTable.

    .LINK
    Invoke-TextQualifierRegex, Infer-DataType
    #>
    [CmdletBinding()]
    [OutputType([System.Data.DataTable])]
    param (
        [Parameter(Mandatory)]
        [string]
        $Path,
        [Parameter(Mandatory=$false)]
        [ValidateSet("Comma", "Tab", "Pipe")]
        [string]
        $DelimiterChoice="Comma",
        [Parameter(Mandatory = $false)]
        [int]
        $StartRow = 0,
        [Parameter(Mandatory = $false)]
        [string[]]
        $Headers
    )
    
    begin {
        if (-not (Test-Path $Path)) {
            throw FileNotFoundException("Path $path does not exist")
        }

        $Delimiter = switch ($DelimiterChoice) {
            'Comma' { "," }
            'Tab' { "t" }
            'Pipe' { "|" }
            Default { "" }
        }
    }
    
    process {
        $reader = New-Object System.IO.StreamReader $Path
        $dt = New-Object System.Data.DataTable
        if ($StartRow -gt 0) {
            for ($i = 0; $i -lt $StartRow; $i++) {
                $reader.ReadLine() | Out-Null
            }
        }
        if ($Headers.Count -gt 0) {
            $columns = $Headers
        }
        else {
            $headerRow = $reader.ReadLine()
            $headerRowCleaned = Invoke-TextQualifierRegex -Delimiter $DelimiterChoice -Line $headerRow
            $columns = $headerRowCleaned -split $Delimiter
        }
        $firstRow = (Invoke-TextQualifierRegex -Delimiter $DelimiterChoice -Line $reader.ReadLine()) -split $Delimiter
            
        for ($i = 0; $i -lt $columns.Count; $i++) {
            $columnName = $columns[$i]
            $columnType = Infer-DataType -Value $firstRow[$i]
            $col = New-Object System.Data.DataColumn $columnName, $columnType
            $dt.Columns.Add($col)
        }

        $firstDTRow = $dt.NewRow()
        for ($i = 0; $i -lt $firstRow.Count; $i++) {
            $firstDTRow[$columns[$i]] = $firstRow[$i]
        }

        $dt.Rows.Add($firstDTRow)

        while (($line = $reader.ReadLine()) -ne $null) {
            $cleanedLine = (Invoke-TextQualifierRegex -Delimiter $DelimiterChoice -Line $line) -split $Delimiter
            $row = $dt.NewRow()
            for ($i = 0; $i -lt $cleanedLine.Count; $i++) {
                $row[$columns[$i]] = $cleanedLine[$i]
            }
            $dt.Rows.Add($row)
        }
    
        $dt.AcceptChanges()

        return ,$dt
        
    }
    
    end {
        
    }
}

function Invoke-SQLStoredProcedure {
    <#
    .SYNOPSIS
    Executes a stored procedure against the specified SQL connection.

    .DESCRIPTION
    The Invoke-SQLStoredProcedure function runs a stored procedure on the SQL Server using the provided connection and parameters.

    .PARAMETER SQLConnection
    The SQL Server connection object used to execute the stored procedure. This parameter is mandatory.

    .PARAMETER ProcedureName
    The name of the stored procedure to execute. This parameter is mandatory.

    .PARAMETER Parameters
    A hashtable of parameters to be passed to the stored procedure. This parameter is optional.

    .PARAMETER CloseConnection
    A switch that indicates whether to close the SQL connection after executing the stored procedure. This parameter is optional.

    .EXAMPLE
    Invoke-SQLStoredProcedure -SQLConnection $connection -ProcedureName "sp_UpdateUser" -Parameters @{ UserId=1; UserName="JohnDoe" }
    This example executes the stored procedure sp_UpdateUser with the specified parameters.

    .LINK
    New-SQLConnection
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.Data.SqlClient.SQLConnection]$SQLConnection,

        [Parameter(Mandatory)]
        [string]$ProcedureName,

        [Parameter(Mandatory=$False)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$False)]
        [switch]$CloseConnection
    )

    process {
        $sqlCommand = New-Object System.Data.SqlClient.SqlCommand($ProcedureName, $SQLConnection)
        $sqlCommand.CommandType = [System.Data.CommandType]::StoredProcedure

        if ($Parameters) {
            foreach ($key in $Parameters.Keys) {
                $sqlCommand.Parameters.AddWithValue($key, $Parameters[$key]) | Out-Null
            }
        }

        if($SQLConnection.State -eq [System.Data.ConnectionState]::Closed){
            $SQLConnection.Open()
        }

        try {
            $sqlCommand.ExecuteNonQuery() | Out-Null
        }
        catch {
            Write-Error "SQL Stored Procedure error: $_"
            return
        }finally{
            if($CloseConnection){
                $SQLConnection.Close()
            }
        }
        
    }
}
