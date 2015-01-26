USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Task_FollowBet_Step2]    Script Date: 01/26/2015 03:38:35 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.Task_FollowBet_Step2    Script Date: 10/10/2014 12:33:42 PM ******/
CREATE PROCEDURE [dbo].[Task_FollowBet_Step2]
AS
/*
	Create:  
	Task:  
	DB: DBTRANS.BODB02

	Revisions:
		- 20120529@Sophia: . Update credit/debit balance
						   . Check @@Error to rollback
		- 20131108@Elodie: Splitting bodb02 into CustDB (call CustInfo, Exchange by link database)	
		- 20130107@Kathy: Get follower from Cust_FollowBet instead of hardcoded		
		- 20140919@Kathy: Allow to follow running ticket only [Redmine:#22392]		   
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @follow_transid		BIGINT,
			@statusID			INT
	
	DECLARE @TransIDs TABLE (transid BIGINT, isFinished BIT)
	
	INSERT INTO @TransIDs (transid, isFinished)
	SELECT transid, 0
	FROM dbo.Task_FollowBet_Details WITH(NOLOCK)

	WHILE (1 = 1)
	BEGIN
		UPDATE TOP(1) @TransIDs
		SET isFinished = 1
			,@follow_transid = transid
		WHERE isFinished = 0
		
		IF @@ROWCOUNT = 0 BREAK -- no more tickets to handle
		
		SELECT @follow_transid = b.transid
			,@statusID = b.statusID
		FROM dbo.Task_FollowBet_Details t WITH(NOLOCK)
			INNER JOIN dbo.bettrans b WITH(NOLOCK) ON b.transid = t.transid
		WHERE t.transid = @follow_transid
			AND b.statusID <> 1 -- 1: Status is waiting
		
		IF @@ROWCOUNT = 0 CONTINUE -- this ticket is still waiting, leave it alone :D, get back later.
		
		IF @statusID = 0  -- follow running ticket only
		BEGIN
						EXEC dbo.Task_FollowBet_Step2_PlaceBet @follow_transid = @follow_transid
		END
		ELSE
		BEGIN
			DELETE FROM dbo.Task_FollowBet_Details WITH(UPDLOCK, ROWLOCK)
			WHERE transid = @follow_transid		
		END
			
	END --end while
	
	WAITFOR DELAY '000:00:01' -- WAIT 1 second, then back to the 1st step (list ticket)
END
GO


