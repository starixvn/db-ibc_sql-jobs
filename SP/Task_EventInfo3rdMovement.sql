USE bodb02
GO

ALTER PROCEDURE [dbo].[Task_EventInfo3rdMovement]	
AS

/*
	Created by: Sophia
	Date: 20151225
	Task: Daily EventInfo3rd movement for CockFighting [Redmine: #48601]
	DB: DBTRANS.BODB02
	Revisions:
       
*/
BEGIN 
	SET NOCOUNT ON	

	DECLARE @winlostdate SMALLDATETIME

	SELECT @winlostdate = DATEADD(dd, DATEDIFF(dd, 0, CURRENT_TIMESTAMP), 0)
	
	-- ========================================
	-- DATA VERIFICATION - Translog
	-- ========================================
 

	CREATE TABLE #EventInfo3rd (ArenaID INT, FightNo INT, EventDate SMALLDATETIME)

	INSERT INTO #EventInfo3rd (ArenaID, FightNo, EventDate)
	SELECT DISTINCT custom2, gameid3rd, winlostdate 
	FROM dbo.translog WITH (NOLOCK)
	WHERE GameId = 1003
		AND statusID IN (0,1)
		AND winlostdate < @winlostdate		
	IF @@ROWCOUNT = 0 RETURN


	IF EXISTS (
		SELECT 1  
		FROM dbo.translog t WITH (NOLOCK)
		INNER JOIN #EventInfo3rd e
			ON e.ArenaID = t.custom2
				AND e.FightNo = t.gameid3rd
				AND e.EventDate = t.winlostdate
		WHERE	t.statusID NOT IN (0,1)
				AND t.winlostdate < @winlostdate
				AND t.gameID = 1003
				AND t.currency NOT IN (20,27,28)
			)
	OR EXISTS (
		SELECT 1  
		FROM dbo.bettrans t WITH (NOLOCK)
		INNER JOIN #EventInfo3rd e
			ON e.ArenaID = t.betcheck
				AND e.FightNo = t.betdaqid
				AND e.EventDate = t.winlostdate
		WHERE	t.statusID NOT IN (0,1)
				AND t.winlostdate < @winlostdate
				AND t.bettype = 1003
				AND t.currency NOT IN (20,27,28)
			)
						
	BEGIN
		RAISERROR ('FAILED: Event need to move date has settled tickets', 16, 1)
		RETURN
	END
		

	UPDATE O
	SET EventDate = @winlostdate 
	FROM DBPRO.bodb02.dbo.EventInfo3rd O WITH (UPDLOCK, ROWLOCK)
		INNER JOIN #EventInfo3rd OT 
			ON OT.ArenaID = O.ArenaID
				AND OT.FightNo = O.FightNo
				AND OT.EventDate = O.EventDate
	
	UPDATE t
	SET winlostdate = @winlostdate
		,actualrate = e.actualrate
	FROM dbo.translog t WITH (UPDLOCK, ROWLOCK)
		INNER JOIN CustDB.dbo.exchange e WITH (NOLOCK)
			ON t.currency = e.exchangeid
		INNER JOIN #EventInfo3rd OT
			ON OT.ArenaID = t.custom2 
				AND OT.FightNo = t.gameid3rd
				AND OT.EventDate = t.winlostdate
	WHERE	t.statusID <> 0 
			AND t.winlostdate < @winlostdate
			AND t.gameID = 1003 

	DECLARE @Doing VARCHAR(4000)

	SET @Doing = '[Task_EventInfo3rdMovement] - Moving eventdate for EventInfo3rd: ' 
				+ STUFF((	SELECT ',' + cast(ArenaID AS VARCHAR(12)) +'-'+ cast(FightNo AS VARCHAR(12))+'-'+ cast(EventDate AS VARCHAR(12))
							FROM #EventInfo3rd
							FOR XML PATH('')
							), 1, 1, '')

	EXEC dbo.WriteLog_UserLog @UserID = 862400
		,@Doing = @Doing

END

GO
GRANT VIEW DEFINITION ON [dbo].[Task_EventInfo3rdMovement] TO [vnteam] AS [dbo]
GO