USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[NAP_Set_MatchDelSettled]    Script Date: 01/26/2015 04:11:25 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.NAP_Set_MatchDelSettled    Script Date: 3/20/2014 5:36:23 PM ******/

CREATE PROCEDURE [dbo].[NAP_Set_MatchDelSettled] 
	@date datetime
AS
/*	Creator: Kathy
	Date: 20140318
	Task: Delete settled matches, messages in Single and Parlay's queue
	DB: DBTXN/BODB02
	Original: Admin_Settlement_1
	
	Revisions:
		
	Param's Explanation:
		
		
*/
BEGIN
	SET NOCOUNT ON

	-- Single match
	DELETE Single_Calculate_Queue WITH(UPDLOCK,ROWLOCK)
	WHERE Starttime < @Date AND IsCalculating NOT IN (0, 1)

	-- Parlay
	DELETE Parlay_Calculate_Queue WITH (UPDLOCK,ROWLOCK)
	WHERE Starttime < @Date AND IsCalculating NOT IN (0, 1)

	-- Settled message
	DELETE Settled_Message WITH(UPDLOCK, ROWLOCK)
	WHERE Starttime < @Date 
	AND IsRead = 1
END
GO

GRANT VIEW DEFINITION ON [dbo].[NAP_Set_MatchDelSettled] TO [vnteam] AS [dbo]
GO


