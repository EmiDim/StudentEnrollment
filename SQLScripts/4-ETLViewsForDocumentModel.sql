--*************************** Instructors Version ******************************--
-- Title: DWStudentEnrollments Document Models Views
-- Author: RRoot
-- Desc: This file will create or alter views in the 
--		[DWStudentEnrollments] database for its Document Models. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created File
-- 2020-03-27,Emilija Dimikj, Create DocumentDB View code
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

-- All Tables --
Create or Alter View vETLDocumentDB as
SELECT [EnrollmentID]=E.EnrollmentID
, [EnrollmentDate]=CONVERT(date,cast(D.DateKey as char(8)),110)
, [Date]=Replace([DateName], ',' , ' ')
, [Month]=D.MonthName
, [Quarter]=D.QuarterName
, [Year]=YearName
, [ClassID]=C.ClassID
, [Course]=C.ClassName
, [DepartmentID]=C.DepartmentID
, [DepartmentName]=C.DepartmentName
, [ClassStartDate]=C.ClassStartDate
, [ClassEndDate]=C.ClassEndDate
, [CurrentCoursePrice]=C.CurrentClassPrice
, [MaxCourseEnrollment] = MaxCourseEnrollment
, [EnrollmentsPerCourse] = Count(E.StudentKey) Over(Partition By E.ClassKey)
, [FreePlacesPerCourse]=MaxCourseEnrollment-Count(E.StudentKey) Over(Partition By E.ClassKey)
, [CourseEnrollmentLevelKPI] = dbo.fKPIMaxLessCurrentEnrollments(E.ClassKey)
, [ClassroomID]=C.ClassroomID
, [ClassroomName]=C.ClassroomName
, [MaxClassroomSize]=C.MaxClassroomSize
, [StudentID]=S.StudentID
, [StudentFullName]=S.StudentFullName
, [StudentEmail]=S.StudentEmail
, [ActualEnrollmentPrice]=E.ActualEnrollmentPrice
FROM FactEnrollments as E
	INNER JOIN DimClasses as C ON E.ClassKey=C.ClassKey
	INNER JOIN DimStudents as S ON E.StudentKey=S.StudentKey
	INNER JOIN DimDates as D ON E.EnrollmentDateKey=D.DateKey
Go

Select * From vETLDocumentDB;
Go
