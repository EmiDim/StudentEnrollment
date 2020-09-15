--*************************************************************************--
-- Title: Create the DWStudentEnrollments database
-- Author: RRoot
-- Desc: This file will drop and create the [DWStudentEnrollments] database, with all its objects. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created File
-- 2020-03-14,Emilija Dimikj, Modified DW creation code
-- 2020-03-22, Emilija Dimikj, Synchronising with Randal's code
-- 2020-03-27, Emilija Dimikj, DimDates->FullDateTime format 110
--**************************************************************************--

USE [master]
If Exists (Select Name from SysDatabases Where Name = 'DWStudentEnrollments')
  Begin
   ALTER DATABASE DWStudentEnrollments SET SINGLE_USER WITH ROLLBACK IMMEDIATE
   DROP DATABASE DWStudentEnrollments
  End
Go
Create Database DWStudentEnrollments;
Go
USE DWStudentEnrollments;
Go

--********************************************************************--
-- Create the Dimension Tables
-- 2020-03-22, Emilija Dimikj, changed tables 
--********************************************************************--
/****** Students Dimension Table  ******/
CREATE TABLE [dbo].[DimStudents](
	[StudentKey] int	NOT NULL IDENTITY(1,1) ,
	[StudentID] int		NOT NULL,
	[StudentFullName] nvarchar(200)		NOT NULL,
	[StudentEmail] nvarchar(100)	NOT NULL
);
ALTER TABLE [dbo].[DimStudents] ADD CONSTRAINT
	pkDimStudents PRIMARY KEY CLUSTERED (StudentKey);
Go

/****** Classes Dimension Table  ******/
-- merged with Classrooms and Departments tab. for the star schema
CREATE TABLE [dbo].[DimClasses](
	[ClassKey] int		NOT NULL IDENTITY(1,1),
	[ClassID] int		NOT NULL,
	[ClassName] nvarchar(100)	NOT NULL,
	[ClassStartDate] date		NOT NULL,
	[ClassEndDate] date			NOT NULL,
	[CurrentClassPrice] money	NOT NULL,
	[MaxCourseEnrollment] int	NOT NULL,
	[ClassroomID] int			NOT NULL,
	[ClassroomName] nvarchar(100)	NOT NULL,
	[MaxClassroomSize] int		NOT NULL,
	[DepartmentID] int			NOT NULL,
	[DepartmentName] nvarchar(100)	NOT NULL
 );
ALTER TABLE [dbo].[DimClasses] ADD CONSTRAINT
	pkDimClasses PRIMARY KEY CLUSTERED (ClassKey);
Go

/****** Date Dimension Table ******/
/****** for reporting purposes ******/
CREATE TABLE [dbo].[DimDates](
	[DateKey] int			NOT NULL,
	[FullDateTime] datetime NOT NULL,
	[DateName] nvarchar(50) NULL,
	[MonthKey] int			NOT NULL,
	[MonthName] nvarchar(50)	NOT NULL,
	[QuarterKey] int		NOT NULL,
	[QuarterName] nvarchar(50)	NOT NULL,
	[YearKey] int			NOT NULL,
	[YearName] nvarchar(50)	NOT NULL 
);
ALTER TABLE [dbo].[DimDates] ADD CONSTRAINT
	pkDimDates PRIMARY KEY CLUSTERED (DateKey);
Go

--********************************************************************--
-- Create the Fact Tables
--********************************************************************--
CREATE TABLE [dbo].[FactEnrollments](
	[EnrollmentID] int		NOT NULL,
	[EnrollmentDateKey] int	NOT NULL,
	[StudentKey] int		NOT NULL,
	[ClassKey] int			NOT NULL,
	[ActualEnrollmentPrice] [money] NOT NULL
);
ALTER TABLE [dbo].[FactEnrollments] ADD CONSTRAINT
	pkFactEnrollments PRIMARY KEY CLUSTERED (EnrollmentID,EnrollmentDateKey,StudentKey,ClassKey);
Go

--********************************************************************--
-- Add the Foreign Key Constraints
-- 2020-03-22, Emilija Dimikj, changed names of all foreign keys
--********************************************************************--

ALTER TABLE [dbo].[FactEnrollments] ADD CONSTRAINT
	fkFactEnrollmentsToDimStudents FOREIGN KEY(StudentKey) 
	REFERENCES dbo.DimStudents(StudentKey);

ALTER TABLE [dbo].[FactEnrollments] ADD CONSTRAINT
	fkFactEnrollmentsToDimClasses FOREIGN KEY(ClassKey) 
	REFERENCES dbo.DimClasses(ClassKey);

ALTER TABLE [dbo].[FactEnrollments] ADD CONSTRAINT
	fkFactEnrollmentsToDimDates FOREIGN KEY(EnrollmentDateKey) 
	REFERENCES dbo.DimDates(DateKey);
Go

--********************************************************************--
-- Create a Reporting View of all tables
-- 2020-03-22, Emilija Dimikj, changed names of all views;
--								* in select replaced with list of columns
--********************************************************************--
CREATE VIEW vDimClasses AS
  SELECT [ClassKey]
      ,[ClassID]
      ,[ClassName]
      ,[ClassStartDate]
      ,[ClassEndDate]
      ,[CurrentClassPrice]
      ,[MaxCourseEnrollment]
      ,[ClassroomID]
      ,[ClassroomName]
      ,[MaxClassroomSize]
      ,[DepartmentID]
      ,[DepartmentName]
  FROM [dbo].[DimClasses];
Go
CREATE VIEW vDimStudents AS
  SELECT [StudentKey]
      ,[StudentID]
      ,[StudentFullName]
      ,[StudentEmail]
  FROM [dbo].[DimStudents];
Go
CREATE VIEW vDimDates AS
  SELECT [DateKey]
      ,[FullDateTime]
      ,[DateName]
      ,[MonthKey]
      ,[MonthName]
      ,[QuarterKey]
      ,[QuarterName]
      ,[YearKey]
      ,[YearName]
  FROM [dbo].[DimDates];
Go
CREATE VIEW vFactEnrollments AS
  SELECT [EnrollmentID]
      ,[EnrollmentDateKey]
      ,[StudentKey]
      ,[ClassKey]
      ,[ActualEnrollmentPrice]
  FROM [dbo].[FactEnrollments];
Go

--********************************************************************--
-- Stored Procedures
--********************************************************************--
Create or Alter Procedure pETLFillDimDates
As
 Begin
-- Create variables to hold the start and end date
DECLARE @StartDate datetime = '01/01/2020';
DECLARE @EndDate datetime = '12/31/2029';

-- Use a while loop to add dates to the table
DECLARE @DateInProcess datetime;
SET @DateInProcess = @StartDate;

WHILE @DateInProcess <= @EndDate
 BEGIN
	 INSERT INTO DimDates ( 
	   [DateKey]
	 , [FullDateTime]
	 , [DateName]
	 , [MonthKey]
	 , [MonthName]
	 , [QuarterKey]
	 , [QuarterName]
	 , [YearKey]
	 , [YearName]
	 )
	 Values ( 
		Convert(nVarchar(50), @DateInProcess, 112) -- [DateKey]
	  , Convert(nVarchar(50), @DateInProcess, 110) -- [FullDateTime]
	  , Concat(DateName(weekday, @DateInProcess ),', ',Convert(nVarchar(50), @DateInProcess, 110)) -- [DateName]  
	  , Cast(Year( @DateInProcess ) as nvarchar(4)) + Right('0' + Cast(Month( @DateInProcess ) as nVarchar(3)), 2) -- [MonthKey]    
	  , Concat(DateName( month, @DateInProcess ),' - ',Cast( Year(@DateInProcess) as nVarchar(50)))-- [MonthName]
	  , Cast(Year( @DateInProcess ) as nvarchar(4)) + Right('0' + (DateName( quarter, @DateInProcess )), 2) -- [QuarterKey]
	  , Concat('Qtr',DateName( quarter, @DateInProcess ),' - ',Cast( Year(@DateInProcess) as nVarchar(50))) -- [QuarterName] 
	  , Year( @DateInProcess ) -- [YearKey]
	  , Cast( Year(@DateInProcess ) as nVarchar(50) ) -- [Year] 
	  );
	 -- Add a day and loop again
	 Set @DateInProcess = DateAdd(d, 1, @DateInProcess);
	 End
  End
 Go

create or alter procedure getOpenRowStatement
	@tableName nvarchar(50) = NULL,
	@sqlStatement nvarchar(max) =NULL
as
begin
	drop table if exists ##TempT;

	exec sp_configure 'show advanced option', '1'; -- Show advance settings
	RECONFIGURE; -- Force the change

	exec sp_configure 'Ad Hoc Distributed Queries', 1; -- Turn ON Ad Hoc queries
	RECONFIGURE; -- Force the change

	declare @OpenRowSetStatement as nvarchar(max);
	if @tableName is not null 
		set @OpenRowSetStatement='SELECT s.* into ##TempT
				FROM OPENROWSET(''SQLNCLI11''
				,''Server=continuumsql.westus2.cloudapp.azure.com;uid=BICert;pwd=BICert;database=StudentEnrollments;''
				, ''SELECT * FROM ' + @tableName + ''') AS s;';
	else if @sqlStatement is not null
		set @OpenRowSetStatement='SELECT s.* into ##TempT
				FROM OPENROWSET(''SQLNCLI11''
				,''Server=continuumsql.westus2.cloudapp.azure.com;uid=BICert;pwd=BICert;database=StudentEnrollments;''
				, ''' + @sqlStatement + ''') AS s;'
	else
		goto turnOff

	EXECUTE sp_executesql @OpenRowSetStatement;

turnOff:	exec sp_configure 'Ad Hoc Distributed Queries', 0; -- Turn OFF Ad Hoc queries
		RECONFIGURE; -- Force the change 

		exec sp_configure 'show advanced option', '0';
		RECONFIGURE; -- Force the change 
end
go

--********************************************************************--
-- Review the results of this script
--********************************************************************--
Select 'Database Created'
Select Name, xType, crDate from SysObjects 
Where xType in ('U', 'PK', 'F', 'V','P')
Order By xType Desc, Name


