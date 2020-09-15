--*************************************************************************--
-- Title: Investigating Data Techniques
-- Author: RRoot
-- Desc: This file shows different ways to investigate data when starting a BI Solution. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created File
-- 2020-03-29, Emilija Dimikj, Modifing for run on linked server: just db definition without sample data
--**************************************************************************--

EXEC master.dbo.sp_addlinkedserver
 @server = N'AZURESQLSERVER', 
 @srvproduct=N'',
  @provider=N'SQLNCLI',
   @datasrc=N'CONTINUUMSQL.WESTUS2.CLOUDAPP.AZURE.COM',
    @catalog=N'StudentEnrollments'

EXEC master.dbo.sp_addlinkedsrvlogin
 @rmtsrvname=N'AZURESQLSERVER',
 @useself=N'FALSE', 
 @locallogin=NULL, 
 @rmtuser=N'BICert', 
 @rmtpassword=N'BICert';
GO

-- Getting MetaData --------------------------------------------------------------

-- Two important functions are Object_Name and Object_ID
--Select 'Name' = object_name(-105), 'ID' = object_id('SysObjects');
SELECT * FROM OPENQUERY(AZURESQLSERVER, 'Select ''Name'' = object_name(-105), ''ID'' = object_id(''SysObjects'')')
-- Note the aliases
--Select 'Object_Name' = Object_Name(-105), 'Object_Id' = object_id('SysObjects');
SELECT * FROM OPENQUERY(AZURESQLSERVER, 'Select ''Object_Name'' = Object_Name(-105), ''Object_Id'' = object_id(''SysObjects'')')


-- [SysObjects] --
--Select * From SysObjects Order by crdate desc;
Select * From [AZURESQLSERVER].[StudentEnrollments].[sys].SysObjects Order by crdate desc

-- Filter out most system objects
Select * 
From [AZURESQLSERVER].[StudentEnrollments].[sys].SysObjects 
Where xtype in ('u', 'pk', 'f') 
Order By  parent_obj

-- Just the object and Parent objects
Select  Name, [Parent object] = iif(parent_obj = 0, '', Object_Name(parent_obj)) 
From [AZURESQLSERVER].[StudentEnrollments].[sys].SysObjects 
Where xtype in ('u', 'pk', 'f')
Order By  parent_obj


-- [Sys.Objects] -- Newer
Select * 
From [AZURESQLSERVER].[StudentEnrollments].Sys.Objects Order by create_date desc;

-- Filter out most system objects
Select *, 'Parent object' = iif(parent_object_id = 0, '', Object_Name(parent_object_id)) 
From [AZURESQLSERVER].[StudentEnrollments].Sys.Objects 
Where type in ('u', 'pk', 'f') 
Order By  parent_object_id

-- Just the object and Parent objects
Select Name, 'Parent object' = iif(parent_object_id = 0, '', Object_Name(parent_object_id)) 
From [AZURESQLSERVER].[StudentEnrollments].Sys.Objects 
Where type in ('u', 'pk', 'f') 
Order By  parent_object_id

-- [Sys.Tables] -- 
Select * From [AZURESQLSERVER].[StudentEnrollments].Sys.Tables Order By create_date;

Select "Schema" = schema_name([schema_id]), [name] 
From [AZURESQLSERVER].[StudentEnrollments].Sys.Tables 

-- [Sys.Columns] -- 
Select * From [AZURESQLSERVER].[StudentEnrollments].Sys.Columns; 

Select [Table] = object_name([object_id]), [Name], system_type_id, max_length, [precision], scale, is_nullable 
From [AZURESQLSERVER].[StudentEnrollments].Sys.Columns; 

Select [Table] = object_name([object_id]), [Name], system_type_id, max_length, [precision], scale, is_nullable  
From [AZURESQLSERVER].[StudentEnrollments].Sys.Columns
Where [object_id] in (Select [object_id] From Sys.Tables); 

-- [Sys.Types] -- 
Select * From [AZURESQLSERVER].[StudentEnrollments].Sys.Types;

Select [Table] = object_name([object_id]), c.[Name], t.[Name], c.max_length, t.max_length
From [AZURESQLSERVER].[StudentEnrollments].Sys.Types as t 
Join [AZURESQLSERVER].[StudentEnrollments].Sys.Columns as c 
 On t.system_type_id = c.system_type_id 
Where [object_id] in (Select [object_id] From [AZURESQLSERVER].[StudentEnrollments].Sys.Tables); 

-- Combining the results 
Select 
 [Database] = DB_Name()
,[Schema Name] = SCHEMA_NAME(tab.[schema_id])
,[Table] = object_name(tab.[object_id])
,[Column] =  col.[Name]
,[Type] =  t.[Name] 
,[Nullable] = col.is_nullable
From [AZURESQLSERVER].[StudentEnrollments].Sys.Types as t 
Join [AZURESQLSERVER].[StudentEnrollments].Sys.Columns as col 
 On t.system_type_id = col.system_type_id 
Join [AZURESQLSERVER].[StudentEnrollments].Sys.Tables tab
  On Tab.[object_id] = col.[object_id]
And t.name <> 'sysname'
Order By 1, 2; 


-- Getting Sample Data --------------------------------------------------------------

--exec('Exec sp_msforeachtable @Command1 = ''sp_help [?]''') AT [AZURESQLSERVER]
--Go
--Notice that sp_help is called for each table in the database and that I am using square brackets instead of a double quote. 
--This make this command evaluate as an object and not just a string, which can be important sometimes, though in this case it doesn’t matter.

--We create our own Sproc and pass in the table name as an argument value. 
--This next example uses the TSQL Exec command run a string of text characters as if it were a typed-out SQL statement.
--Create or Alter Proc pSelTop2
--(@TableName as nVarchar(100))
--AS 
--Print @TableName
--Declare @SQLCode nvarchar(100) = 'Select Top 2 [Table] = Replace(''' +  @TableName +  ''', ''[dbo].'', '''')' + ' , * ' 
--                                                  + 'From  ' + @TableName 
--Print @SQLCode
--Exec(@SQLCode)
--Go
----Now I can use Microsoft’s stored procedure to execute my stored procedure like this:
--Exec sp_msforeachtable @Command1 = 'exec pSelTop2 "?" '
--Go

EXEC sp_dropserver 'AZURESQLSERVER', 'droplogins';
