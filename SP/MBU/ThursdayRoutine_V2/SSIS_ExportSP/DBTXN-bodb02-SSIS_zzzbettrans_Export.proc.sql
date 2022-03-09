/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_zzzbettrans_Export]
	@winlostdate smalldatetime=null
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]	
	Database: DBTXN.bodb02
	Original: DB06x.bodb_archive.Task_Archive_Copy
	
	Revisions:
		- 20130831@Bobby: Init
 */
 BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @tmpRequest table(RequestId INT);
	declare @RequestIds varchar(max);

	INSERT INTO @tmpRequest(RequestId)
	SELECT RequestID
	FROM dbo.Task_Archive_TVS tvs with(nolock)
	WHERE tvs.Winlostdate=@winlostdate

	SET @RequestIds = STUFF((SELECT ',' + CAST(RequestId AS VARCHAR(50)) FROM @tmpRequest FOR XML PATH('')),1,1,'')

    SELECT	transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, matchid, bettype, keyid, t1.VoidingHistoryId
	FROM	dbo.zzzbettrans AS t1 WITH (NOLOCK)
	INNER JOIN dbo.TicketVoiding_VoidingHistory v WITH (NOLOCK) ON v.VoidingHistoryId = t1.VoidingHistoryId
		CROSS APPLY (
					SELECT	val AS RequestId
					FROM	dbo.f_SplitString(@RequestIds, ',')
					WHERE val = v.RequestId
			) r
	WHERE	t1.VoidingHistoryId IS NOT NULL
		AND r.RequestId IS NOT NULL
	
	---------------Table 4: zzzbettrans_bk --------------------
	UNION --ALL
	SELECT	t1.transid, t1.custid, t1.transdate, t1.oddsid, t1.hdp1, t1.hdp2, t1.odds, t1.stake, t1.STATUS, t1.winlost, t1.livehomescore, t1.liveawayscore, t1.liveindicator, t1.betteam, t1.creator, t1.refno, t1.comstatus, t1.winlostdate, t1.betfrom, t1.betcheck, t1.checktime, t1.matchid, t1.bettype, t1.keyid, t1.VoidingHistoryId
	FROM	dbo.zzzbettrans AS t1 WITH (NOLOCK)
		INNER JOIN dbo.bettrans14 AS t2 WITH (NOLOCK) ON t1.transid = t2.transid AND t2.winlostdate = @winlostdate
	WHERE	t1.VoidingHistoryId IS NULL	
		AND EXISTS (SELECT 1 FROM dbo.SportBettypeMatrix t3 WITH (NOLOCK) WHERE t2.bettype=t3.BetType
							AND t3.ProductID IN (1,3,5,25,27,37) AND t2.statusID=102 )
	UNION
	SELECT	t1.transid, t1.custid, t1.transdate, t1.oddsid, t1.hdp1, t1.hdp2, t1.odds, t1.stake, t1.STATUS, t1.winlost, t1.livehomescore, t1.liveawayscore, t1.liveindicator, t1.betteam, t1.creator, t1.refno, t1.comstatus, t1.winlostdate, t1.betfrom, t1.betcheck, t1.checktime, t1.matchid, t1.bettype, t1.keyid, t1.VoidingHistoryId
	FROM	dbo.zzzbettrans AS t1 WITH (NOLOCK)
		INNER JOIN dbo.bettransm14 t2 WITH (NOLOCK) ON t1.transid = t2.transid AND t2.statusID=102 and t1.matchid=t2.matchid AND t2.winlostdate = @winlostdate
	WHERE	t1.VoidingHistoryId IS NULL
	OPTION (maxrecursion 0);
END
GO

