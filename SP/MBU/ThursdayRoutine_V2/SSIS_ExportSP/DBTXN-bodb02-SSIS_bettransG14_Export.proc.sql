/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_bettransG14_Export]
	@winlostdate smalldatetime=null
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]	
	Database: DBTXN.bodb02
	Original: Task_Archive_SelectBettransG
	
	Revisions:
		- 20130831@Bobby: Init
 */
BEGIN
	SET NOCOUNT ON;

	--DECLARE	@max_winlostdate	SMALLDATETIME
	--	;

	--SELECT	@max_winlostdate = MAX(winlostdate)
	--FROM	dbo.Task_ArchiveDate WITH (NOLOCK);

	-- to DB06.bodb_Archive.dbo.bettransG
	SELECT	transid, custid, transdate, oddsid, odds, stake, status, winlost, betteam, creator, refno, winlostdate, betfrom
		,	checktime, apositiontaking, mpositiontaking, tpositiontaking, awinlost, mwinlost, playerdiscount, discount, adiscount
		,	playercomm, comm, acomm, actualrate, matchid, matchdate, statuswinlost, ruben, bettype, spositiontaking, swinlost
		,	sdiscount, scomm, statusID, virtualrate, SiteID, transdesc, BetID3rd, epositiontaking, actual_stake, netstake
	FROM	dbo.bettransG14 WITH (NOLOCK)
	--WHERE	winlostdate <= @max_winlostdate;
	WHERE	winlostdate = @winlostdate;
END
GO
