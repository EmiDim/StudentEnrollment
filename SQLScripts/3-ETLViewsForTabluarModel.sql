--*************************** Instructors Version ******************************--
-- Title: DWStudentEnrollments Tabular Models Views
-- Author: RRoot
-- Desc: This file will create or alter views in the [DWStudentEnrollments] database for its Tabular Models. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created File
-- 2020-03-22, Emilija Dimikj, Create Tabular Views code
-- 2020-03-27, Emilija Dimikj, Synchronising with Randal's code
--**************************************************************************--
Set NoCount On;
Go
USE DWStudentEnrollments;
Go

-- Dimension Tables --
CREATE OR ALTER VIEW [dbo].[vTabularDimStudents] as
select 
[StudentKey]
,[StudentID]
,[StudentFullName]
,[StudentEmail]
from DimStudents;
GO

CREATE OR ALTER   view [dbo].[vTabularDimClasses] as
select 
[ClassKey]
,[ClassID]
,[ClassName]
,[DepartmentID]
,[DepartmentName]
,[ClassStartDate]
,[ClassEndDate]
,[CurrentCoursePrice] = [CurrentClassPrice]
,[MaxCourseEnrollment]
,[ClassroomID]
,[ClassroomName]
,[MaxClassroomSize]
from DimClasses;
GO

CREATE OR ALTER   view [dbo].[vTabularDimDates] as
select 
[DateKey]=CONVERT(date,cast(DateKey as char(8)),110)
,[FullDateTime]
,[DateName]
,[MonthKey]
,[MonthName]
,[QuarterKey]
,[QuarterName]
,[YearKey]
,[Yearname]
from DimDates;
GO

-- Fact Table --
CREATE OR ALTER view [dbo].[vTabularFactEnrollments] as
select 
[EnrollmentID]
,[EnrollmentDateKey]=CONVERT(date,cast(EnrollmentDateKey as char(8)),110)
,[StudentKey]
,[ClassKey]
,[ActualEnrollmentPrice]
from FactEnrollments;
GO


Select * from vTabularDimStudents;
Select * from vTabularDimClasses
Select * from vTabularDimDates
Select * from vTabularFactEnrollments