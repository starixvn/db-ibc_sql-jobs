USE [bodb_Archive]
GO

/****** Object:  StoredProcedure [dbo].[Task_Archive_SelectDate_Manually]    Script Date: 01/22/2015 00:02:13 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_Archive_SelectDate_Manually]
	@minDate smalldatetime,
	@maxDate smalldatetime
AS
SET NOCOUNT ON

truncate table Task_ArchiveDate_Manually

;With Calendar As
    (
    Select @minDate As [Date]
    Union All
    Select DateAdd(d,1,[Date])
    From Calendar
    Where [Date] < @maxDate
    )
INSERT INTO Task_ArchiveDate_Manually (winlostdate)
Select [Date]
From Calendar    
Option ( Maxrecursion 0 );

GO


