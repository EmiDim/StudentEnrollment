--**************************************************************************--
-- Title: DWStudentEnrollments Report Views
-- Author: RRoot
-- Desc: This file creates [DWStudentEnrollments] Reporting Functions and Views for DWStudentEnrollment. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created File
-- 2020-03-04,RRoot, Modified ETL code
-- 2020-03-27, Emilija Dimikj, Modified KPI and View Code
--**************************************************************************--

Set NoCount On;
Go
USE DWStudentEnrollments;
Go

Create or Alter Function dbo.fKPIMaxLessCurrentEnrollments(@ClassKey int)
Returns int
AS
Begin
  Return(
   Select Distinct [Number of Students] = Case
   When (dc.MaxCourseEnrollment * .25) >= (Count(fe.Studentkey) Over(Partition By fe.ClassKey))
    Then -1
   When (dc.MaxCourseEnrollment * .5) > (Count(fe.Studentkey) Over(Partition By fe.ClassKey))
    Then 0
   When (dc.MaxCourseEnrollment * .75) >= (Count(fe.Studentkey) Over(Partition By fe.ClassKey))
    Then 1
  End
  From FactEnrollments as fe Join DimClasses as dc
    On fe.ClassKey = dc.ClassKey
  Where fe.ClassKey = @ClassKey
  )
End;
Go

Create or Alter View vRptStudentEnrollments
AS
Select 
 [EnrollmentID] = E.EnrollmentID 
,[FullDateTime] = Cast(D.FullDateTime as Date)
,[Date] = D.DateName
,[Month] = D.MonthName
,[Quarter] = D.QuarterName
,[Year] = D.YearName
,[ClassID] = C.ClassID
,[Course] = C.ClassName
,[DepartmentID] = C.DepartmentID
,[Department]= C.DepartmentName
,[ClassStartDate] = C.ClassStartDate
,[ClassEndDate] = C.ClassEndDate
,[CurrentCoursePrice] = C.CurrentClassPrice -- Changed Column Name
,[MaxCourseEnrollment] = C.MaxCourseEnrollment
,[ClassroomID] = C.ClassroomID
,[Classroom] = C.ClassroomName
,[MaxClassroomSize] = C.MaxClassroomSize
,[StudentID] = S.StudentID
,[StudentFullName] = S.StudentFullName
,[StudentEmail] = S.StudentEmail
,[CourseEnrollmentLevelKPI] = dbo.fKPIMaxLessCurrentEnrollments(E.ClassKey)
  From FactEnrollments as E 
	INNER JOIN DimDates as D ON E.EnrollmentDateKey = D.DateKey
	INNER JOIN DimClasses as C ON E.ClassKey = C.ClassKey
	INNER JOIN DimStudents as S ON E.StudentKey = S.StudentKey;
Go
Select * From vRptStudentEnrollments;