/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_zzzbettransM_Export]
	@winlostdate smalldatetime=null
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]	
	Database: DBTXN.bodb02
	Original: DB06x.bodb_archive.Task_Archive_Copy
	
	Revisions:
		- 20130831@Bobby: Init
		- 20220315@Kathy: Change to use STRING_SPLIT [Redmine:#166457]
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
	FROM	dbo.zzzbettransM AS t1 WITH (NOLOCK)
		INNER JOIN dbo.TicketVoiding_VoidingHistory v WITH (NOLOCK) ON v.VoidingHistoryId = t1.VoidingHistoryId
		CROSS APPLY (
					SELECT	value AS RequestId
					FROM	STRING_SPLIT(@RequestIds, ',')
					WHERE value = v.RequestId
			) r
	WHERE	t1.VoidingHistoryId IS NOT NULL
		AND r.RequestId IS NOT NULL

	---------------Table 3: zzzbettransM_bk --------------------
	UNION --ALL
	SELECT	transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, matchid, bettype, keyid, VoidingHistoryId
	FROM	dbo.zzzbettransM AS t1 WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.bettransm14 AS t2 WITH (NOLOCK) WHERE t1.transid = t2.transid AND t2.statusID=102 and t1.matchid=t2.matchid AND t2.winlostdate = @winlostdate)
		AND t1.VoidingHistoryId IS NULL
END
GO
