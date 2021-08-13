USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Task_Parlay_Correct_Tickets_settled] @LastDateTime datetime = null
AS
/*
	20180718 @ Patrick
	DBAGE.bodb02
	Task: Correct winlostdate for parlay main tickets 
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @LastDateTimeOutput DATETIME
	SET @LastDateTimeOutput = GETDATE()

	IF @LastDateTime IS NULL
	BEGIN
		SELECT @LastDateTime = CONVERT(VARCHAR(50), sValue, 121)
		FROM dbo.Tickets_settled_setting WITH(NOLOCK) WHERE [sKey] = 'ssb_logs'
	END

	IF @LastDateTime IS NULL
		SET @LastDateTime = DATEADD(HOUR, -1, GETDATE())

	DECLARE @sqlCommandText NVARCHAR(4000)
	CREATE TABLE #__ParlayTickets (transId BIGINT, winlostdate SMALLDATETIME, LastDateTimeOutput DATETIME)

	SET @sqlCommandText = 'exec bodb02.dbo.Task_Parlay_Correct_Tickets_settled_Sel @LastDateTime = ''' + CONVERT(VARCHAR(50), @LastDateTime, 121) + ''''
	print @sqlCommandText
	INSERT INTO #__ParlayTickets(winlostdate, transId, LastDateTimeOutput)
	EXEC (@sqlCommandText) AT DBAGE
	
	SELECT @LastDateTimeOutput = MAX(LastDateTimeOutput) FROM #__ParlayTickets WITH(NOLOCK)

	DECLARE @__tmpData TABLE (transId BIGINT, winlostdate SMALLDATETIME)
	WHILE 1 = 1
	BEGIN
		
		DELETE FROM @__tmpData

		DELETE TOP(2000) FROM #__ParlayTickets 
		OUTPUT deleted.transId, deleted.winlostdate INTO @__tmpData(transId, winlostdate)
		
		IF @@ROWCOUNT = 0
			BREAK
	
		--//remove temp data if unchanges winlostdate
		DELETE t
		FROM @__tmpData t 
			INNER JOIN dbo.bettrans b WITH(NOLOCK) ON t.transId = b.transid
		WHERE t.winlostdate = b.winlostdate
			AND b.matchid = 29 AND b.bettype = 29
		
		UPDATE b
		SET winlostdate = t.winlostdate
		FROM dbo.bettrans b WITH(ROWLOCK, UPDLOCK)
			INNER JOIN @__tmpData t ON b.transid = t.transId
		WHERE b.winlostdate <> t.winlostdate
			AND b.bettype = 29 AND b.matchid = 29
	END

	UPDATE s
	SET sValue = CONVERT(VARCHAR(50), @LastDateTimeOutput, 121)
	FROM dbo.Tickets_settled_setting s WITH(ROWLOCK, UPDLOCK) 
	WHERE [sKey] = 'ssb_logs'
END
