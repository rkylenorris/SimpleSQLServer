Import-Module -FullyQualifiedName "C:\Users\roder\code\powershell\SimpleSQLServer\SimpleSQLServer\src\SimpleSQLServer.psm1"

Build-ConnectionString -Server "simple-sql-server.database.windows.net,1433" -Database "AdventureWorks" -UserName "rkynorris" -Password (Get-Credential)


function Build-ServerConStringSQLAuth([string]$server, [string]$db, [string]$user, [string]$pas) {
    $connectionString = "Server=$server;Database=$db;User Id=$user;Password=$pas;"
    return $connectionString
}

$conStr = Build-ServerConStringSQLAuth "simple-sql-server.database.windows.net,1433" "AdventureWorks" "rkynorris" "Sup3rG4y!"



$conn = New-SQLConnection -ConnectionString $conStr
$sqlCommand = "use AdventureWorks

Select Top(10) 
*
from SalesLT.Customer"
$command = new-object system.data.sqlclient.sqlcommand($sqlCommand,$conn)
    $conn.Open()
    
    $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataSet) | Out-Null
    
    $conn.Close()
    