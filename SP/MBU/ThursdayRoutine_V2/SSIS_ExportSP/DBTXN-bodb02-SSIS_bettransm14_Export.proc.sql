/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_bettransm14_Export]
	@winlostdate smalldatetime=null
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]	
	Database: DBTXN.bodb02
	Original: Task_Archive_SelectBettransm
	
	Revisions:
		- 20130831@Bobby: Init
 */
 BEGIN
	SET NOCOUNT ON;

	--DECLARE	@max_winlostdate	SMALLDATETIME
	--	;

	--SELECT	@max_winlostdate = MAX(winlostdate)
	--FROM	dbo.Task_ArchiveDate;

	-- to DB06.bodb_Archive.dbo.bettransm
	SELECT	[betcheck]	= CONVERT(VARCHAR(50), betcheck)
		,	[betfrom]	= CONVERT(VARCHAR(4),  betfrom)
		,	[betteam]	= CONVERT(VARCHAR(10), betteam)
		,	[comstatus]	= CONVERT(VARCHAR(20), comstatus)
		,	[status]	= CONVERT(VARCHAR(10), status)

		,	transdate, transid, custid, matchid, oddsid, bettype, hdp1, hdp2, stake, odds, finalodds
		,	apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, awinlost, mwinlost, swinlost
		,	playerdiscount, discount, adiscount, sdiscount, playercomm, comm, acomm, scomm
		,	liveawayscore, livehomescore, liveindicator, matchdate, isfinish
		,	oddsspread, refno, ruben, statusID, statuswinlost, winlost
		,	actualrate, checktime, creator, winlostdate, recommdate, transdesc, SecAcceptFlag, ReasonIDm
	FROM	dbo.bettransm14 WITH (NOLOCK)
	WHERE	winlostdate = @winlostdate;
END
GO
