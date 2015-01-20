USE [LASDB]
GO

/****** Object:  StoredProcedure [dbo].[Task_GENData_rptLASWinlost_FULL]    Script Date: 01/20/2015 01:54:23 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.Task_GENData_rptLASWinlost_FULL    Script Date: 9/24/2014 10:17:19 AM ******/

CREATE PROCEDURE [dbo].[Task_GENData_rptLASWinlost_FULL]
	@winlostdate DATE
AS

/*	Creator: Victor
	Task : Summary data to rptLASWinlost & rptLASWinlost_Agent
	DB: DBLAS.LASDB
	Date: 2014-03-19
		             
	Param's Explanation:
	• @winlostdate: The date need to summary
	
	Revisions:	
		- 20140923@Victor: Update condition to select suitable GEN SP
*/


IF (@winlostdate > current_timestamp) OR EXISTS(SELECT 1 FROM dbo.SystemSettings WITH (NOLOCK) WHERE VValue = '1' AND VName in ('isMovingBet','isArchivingBet'))
BEGIN	
	RETURN
END

IF EXISTS(SELECT TOP 1 1 FROM dbo.bettrans14 WITH (NOLOCK) WHERE winlostdate = @winlostdate)
BEGIN
	PRINT '*** bettrans14 - ' + convert(varchar(10), @winlostdate, 111) + ' ***'
	EXEC [dbo].[Task_GENData_rptLASWinlost_bettrans14] @winlostdate
END
ELSE
BEGIN
	IF EXISTS (SELECT TOP 1 1 FROM dbo.bettrans WITH (NOLOCK) WHERE winlostdate >= @winlostdate)
	BEGIN
		PRINT '*** bettrans - ' + convert(varchar(10), @winlostdate, 111) + ' ***'
		EXEC [dbo].[Task_GENData_rptLASWinlost_bettrans] @winlostdate
	END
END
GO


