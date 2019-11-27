/*<info serverAlias="DBAGE-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Parlay_Correct_Tickets_settled_Sel] @LastDateTime datetime = null
AS
/*
	20180718 @ Patrick
	DBAGE.bodb02
	Task: Correct winlostdate for parlay main tickets 
	Revisions: 
		-20191127@Patrick: Setup sync status ticket on DB052 -> DB054 - [Redmine: #124482]
*/
BEGIN
	SET NOCOUNT ON
	SELECT SUBSTRING(message_body, CHARINDEX('@matchid = ', message_body, 0) + 11, 8) AS matchid
		, creationTime 
	INTO #__MatchIds
	FROM sb.CalculationLogs WITH(NOLOCK)
	WHERE creationTime >= @LastDateTime
		AND duration IS NOT NULL
		AND message_body LIKE 'EXEC dbo.NAP_Admin_Calculate_MP_broker%'
	
	DELETE FROM #__MatchIds WHERE ISNUMERIC(matchid) = 0
	DECLARE @LastDateTimeOutput DATETIME
	SELECT @LastDateTimeOutput = MAX(creationTime) 
	FROM #__MatchIds

	SELECT b.transid INTO #__TransIds
	FROM dbo.bettrans b WITH(NOLOCK)
		INNER JOIN dbo.bettransm bm WITH(NOLOCK) ON b.refno = bm.refno
	WHERE b.matchid = 29 AND b.bettype = 29
		AND bm.matchid IN (SELECT t.matchid FROM #__MatchIds t)

	SELECT transid, winlostdate
	INTO #__ParlayTickets
	FROM dbo.bettrans WITH(NOLOCK)
	WHERE matchid = 29 and bettype = 29
		AND transid IN (SELECT t.transid FROM #__TransIds t)
	
	SELECT b.winlostdate, b.transid, @LastDateTimeOutput AS LastDateTimeOutput
	FROM dbo.bettrans b WITH(NOLOCK)
		INNER JOIN #__ParlayTickets t ON b.transid = t.transid
	GROUP BY b.winlostdate, b.transid
END
GO
