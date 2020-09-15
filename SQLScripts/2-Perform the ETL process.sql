--*************************************************************************--
-- Title: Perform the DWStudentEnrollments ETL process
-- Author: RRoot
-- Desc: This file will flush and fill the [DWStudentEnrollments] database tables. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created File
-- 2020-03-14, Emilija Dimikj, Modified ETL code
-- 2020-03-22, Emilija Dimikj, Synchronising with Randal's code
--**************************************************************************--

--********************************************************************--
USE DWStudentEnrollments
Go

--********************************************************************--
-- Drop Foreign Keys Constraints
--********************************************************************--
ALTER TABLE [dbo].[FactEnrollments] DROP CONSTRAINT
	fkFactEnrollmentsToDimStudents;

ALTER TABLE [dbo].[FactEnrollments] DROP CONSTRAINT
	fkFactEnrollmentsToDimClasses;

ALTER TABLE [dbo].[FactEnrollments] DROP CONSTRAINT
	fkFactEnrollmentsToDimDates;
Go

--********************************************************************--
-- Clear all tables and reset their Identity Auto Number 
--********************************************************************--
TRUNCATE TABLE [dbo].[DimClasses];
TRUNCATE TABLE [dbo].[DimStudents];
TRUNCATE TABLE [dbo].[DimDates];
TRUNCATE TABLE [dbo].[FactEnrollments];
Go

--********************************************************************--
-- Fill Dimension Tables
--********************************************************************--
EXEC pETLFillDimDates;
go

EXEC getOpenRowStatement @tableName='Students';
go
INSERT INTO [dbo].[DimStudents]
           ([StudentID]
           ,[StudentFullName]
           ,[StudentEmail])
Select [StudentID]
	,[StudentFullName] = Cast(([StudentFirstName] + ' ' + [StudentLastName]) as nVarChar(200))
	,[StudentEmail]
From ##TempT;

EXEC getOpenRowStatement @sqlStatement='SELECT C.ClassID,C.ClassName,C.ClassStartDate,C.ClassEndDate,C.CurrentClassPrice,C.MaxClassEnrollment,
			CR.ClassroomID,CR.ClassroomName,CR.MaxClassSize,
			D.DepartmentID,D.DepartmentName
		From Classes as C inner join Classrooms as CR on C.ClassroomID=CR.ClassroomID
			inner join Departments as D on C.DepartmentID=D.DepartmentID';
go
INSERT INTO [dbo].[DimClasses]
           ([ClassID]
           ,[ClassName]
		   ,[DepartmentID]
           ,[DepartmentName]
           ,[ClassStartDate]
           ,[ClassEndDate]
           ,[CurrentClassPrice]
           ,[MaxCourseEnrollment]
           ,[ClassroomID]
           ,[ClassroomName]
           ,[MaxClassroomSize]
           )
Select 
	 [ClassID]
	,[ClassName]
	,[DepartmentID]
	,[DepartmentName]
	,[ClassStartDate] = Cast(ClassStartDate as Date)
	,[ClassEndDate] = Cast(ClassEndDate as Date)
	,[CurrentClassPrice]
	,[MaxCourseEnrollment]= [MaxClassEnrollment]
	,[ClassroomID]
	,[ClassroomName]
	,[MaxClassroomSize] = [MaxClassSize]
from ##TempT;
Go

--********************************************************************--
-- Fill Fact Tables 
--********************************************************************--
EXEC getOpenRowStatement @tableName='Enrollments';
go

insert into [dbo].[FactEnrollments](
 [EnrollmentID]
,[EnrollmentDateKey]
,[StudentKey]
,[ClassKey]
,[ActualEnrollmentPrice]
)
SELECT E.[EnrollmentID]
	,[EnrollmentDateKey] = D.[DateKey]
	,[StudentKey] = S.[StudentKey]
	,[ClassKey] = C.[ClassKey] 
	,E.[ActualEnrollmentPrice]
  From ##TempT AS E
  JOIN [dbo].[DimDates] AS D ON E.[EnrollmentDate] = D.[FullDateTime]
  JOIN [dbo].[DimStudents] AS S ON E.[StudentID] = S.[StudentID]
  JOIN [dbo].[DimClasses] AS C ON E.[ClassID] = C.[ClassID];

--********************************************************************--
-- Replace Foreign Keys Constraints
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
-- Review the results of this script
--********************************************************************--
Select 'Database Created'
Select Name, xType, crDate from SysObjects 
Where xType in ('U', 'PK', 'F', 'V','P')
Order By xType Desc, Name