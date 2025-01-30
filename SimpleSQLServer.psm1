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

New-Alias -Name scns -Value Set-EnvironmentConnectionString

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

New-Alias -Name ncn -Value New-SQLConnection

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

New-Alias -Name sqlslt -Value Invoke-SQLSelectQuery

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

New-Alias -Name sqlnq -Value Invoke-SQLNonQuery

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

New-Alias -Name sqlblk -Value Invoke-SQLBulkInsert

function Invoke-TextQualifierRegex {
    # creates regex expressions for removing text qualifiers, then removes them per line
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
    [CmdletBinding()]
    [OutputType([System.Data.DataTable])]
    param (
        # Path to CSV
        [Parameter(Mandatory)]
        [string]
        $Path,
        # Parameter help description
        [Parameter(Mandatory=$false)]
        [ValidateSet("Comma", "Tab", "Pipe")]
        [string]
        $DelimiterChoice="Comma",
        # starting row of file if not first
        [Parameter(Mandatory = $false)]
        [int]
        $StartRow = 0,
        # Provide headers if not in file
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

        $sqlCommand.ExecuteNonQuery() | Out-Null

        if($CloseConnection){
            $SQLConnection.Close()
        }
    }
}
