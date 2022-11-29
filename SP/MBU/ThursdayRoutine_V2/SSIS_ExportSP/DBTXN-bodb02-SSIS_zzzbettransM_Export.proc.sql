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
		- 20221003@Max: [TVS] Enhance archive process of TVS data regarding the Scale Out DB project - [Redmine: #178234]
 */
 BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	declare @tmpVoidingHistory table(VoidingHistoryId INT);

	INSERT INTO @tmpVoidingHistory(VoidingHistoryId)
	SELECT VoidingHistoryId
	FROM dbo.Task_Archive_TVS tvs with(nolock)
		CROSS APPLY (
					SELECT	value AS VoidingHistoryId
					FROM	STRING_SPLIT(tvs.VoidingHistoryIds, ',')
			) r
	WHERE tvs.Winlostdate=@winlostdate

    SELECT	transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, matchid, bettype, keyid, t1.VoidingHistoryId
	FROM	dbo.zzzbettransM AS t1 WITH (NOLOCK)
		INNER JOIN @tmpVoidingHistory v ON v.VoidingHistoryId = t1.VoidingHistoryId
	WHERE	t1.VoidingHistoryId IS NOT NULL

	---------------Table 3: zzzbettransM_bk --------------------
	UNION --ALL
	SELECT	transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, matchid, bettype, keyid, VoidingHistoryId
	FROM	dbo.zzzbettransM AS t1 WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.bettransm14 AS t2 WITH (NOLOCK) WHERE t1.transid = t2.transid AND t2.statusID=102 and t1.matchid=t2.matchid AND t2.winlostdate = @winlostdate)
		AND t1.VoidingHistoryId IS NULL
END
GO
