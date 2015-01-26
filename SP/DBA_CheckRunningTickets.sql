USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[DBA_CheckRunningTickets]    Script Date: 01/26/2015 03:29:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DBA_CheckRunningTickets]
AS
BEGIN
	-- 20140310@Vivi: check translog have running tickets everydate

	declare @today smalldatetime
	set @today=convert(varchar(10), GETDATE(), 120)
	
	IF EXISTS (select translogid from translog with (nolock) where winlostdate < @today and statusID = 0)
	BEGIN
		RAISERROR ('FAILED: Have running tickets - translog', 16, 1)
		RETURN
	END

END
GO


