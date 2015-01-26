USE [MonDB]
GO
/****** Object:  StoredProcedure [dbo].[DBA_Mon_GetDB_Info]    Script Date: 01/26/2015 01:51:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [dbo].[DBA_Mon_GetDB_Info]
AS
Begin
	Declare @Now datetime ,@sp_name varchar(30) ,@SQL Varchar(100),
			@Day char(1), @Hore smallint
	Select  @Now = Getdate () , @Day =  datepart(weekday,getdate()) ,@Hore = DATEPART(hour, getdate())

	While 1 = 1
	Begin

		Select Top 1 @sp_name = sp_name 
		From dbo.Mon_Job_Schedule nolock
		Where DATEDIFF(ss,LastExecutionTime,@Now) > JobRange -5 
			and isEnabled = 1 and JobDay like '%'+@Day+'%'  and @Hore between JobHourStart and JobHourEnd
		IF @@Rowcount > 0
		Begin
			Set @SQL = 'Exec '+@sp_name
			exec ( @SQL )
			Update Mon_Job_Schedule Set LastExecutionTime = @Now
			Where sp_name = @sp_name
		End
		Else Return

	End

End