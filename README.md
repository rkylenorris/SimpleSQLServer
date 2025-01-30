#  **SimpleSQLServer: A PowerShell Module for SQL Server Operations**  

### Author: R. Kyle Norris

## ** Overview**  
SimpleSQLServer is a PowerShell module that simplifies Microsoft SQL Server operations, including:  
✅ Establishing SQL Server connections  
✅ Executing `SELECT`, `INSERT`, `UPDATE`, and `DELETE` queries  
✅ Performing bulk inserts from a CSV file  
✅ Calling stored procedures  
✅ Exporting query results to CSV  

---

## **📥 Installation**  
### **1️⃣ Clone or Download the Module**  
```powershell
git clone https://github.com/rkylenorris/SimpleSQLServer
```
Alternatively, you can download the `.psm1` and `.psd1` files.

### **2️⃣ Import the Module**  
```powershell
Import-Module "C:\Path\To\SimpleSQLServer.psm1"
```

### **3️⃣ Verify Installation**  
```powershell
Get-Module -ListAvailable | Where-Object { $_.Name -eq "SimpleSQLServer" }
```

---

## **⚡ Usage**
### **🔹 Set the SQL Connection String**
```powershell
Set-EnvironmentConnectionString -ConnectionString "Server=MyServer;Database=MyDB;User Id=MyUser;Password=MyPassword;"
```

### **🔹 Create a SQL Connection**
```powershell
$connection = New-SQLConnection
```

---

## **📌 SQL Operations**
### **🔍 Select Data**
```powershell
$connection = New-SQLConnection
$dataset = Invoke-SQLSelectQuery -SQLConnection $connection -SelectQueryText "SELECT * FROM Employees" -CloseConnection
$dataset.Tables[0] | Format-Table
```

### **🆕 Insert a Record**
```powershell
$connection = New-SQLConnection
Invoke-SQLNonQuery -SQLConnection $connection -QueryText "INSERT INTO Employees (Name, Age) VALUES (@Name, @Age)" -Parameters @{ Name = "John Doe"; Age = 30 } -CloseConnection
```

### **✏️ Update a Record**
```powershell
$connection = New-SQLConnection
Invoke-SQLNonQuery -SQLConnection $connection -QueryText "UPDATE Employees SET Age = @Age WHERE Name = @Name" -Parameters @{ Name = "John Doe"; Age = 35 } -CloseConnection
```

### **🗑 Delete a Record**
```powershell
$connection = New-SQLConnection
Invoke-SQLNonQuery -SQLConnection $connection -QueryText "DELETE FROM Employees WHERE Name = @Name" -Parameters @{ Name = "John Doe" } -CloseConnection
```

---

## **📂 Bulk Insert from CSV**
### **🔄 Convert CSV to DataTable**
```powershell
$dataTable = Convert-CsvToDataTable -CsvPath "C:\data\employees.csv"
```

### **🚀 Bulk Insert into SQL Server**
```powershell
$connection = New-SQLConnection
Invoke-SQLBulkInsert -SQLConnection $connection -TableName "Employees" -DataTable $dataTable -CloseConnection
```

---

## **📑 Execute a Stored Procedure**
```powershell
$connection = New-SQLConnection
Invoke-SQLStoredProcedure -SQLConnection $connection -ProcedureName "usp_GetEmployee" -Parameters @{ EmployeeID = 1 } -CloseConnection
```

---

## **📜 License**
This project is licensed under the **MIT License**.

---

## **🙌 Contributions**
Contributions are welcome! Feel free to submit a **pull request** or open an **issue**.

---

## **📞 Support**
For questions, reach out via **GitHub Issues** or email at **r.kyle.norris@gmail.com**.

---

### 🎉 **Happy Scripting with SimpleSQLServer!** 🚀
