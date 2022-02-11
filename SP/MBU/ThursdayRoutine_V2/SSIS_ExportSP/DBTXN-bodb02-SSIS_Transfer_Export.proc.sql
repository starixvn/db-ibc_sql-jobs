/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_Transfer_Export]
	@BUDate smalldatetime=null
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]	
	Database: DBTXN.bodb02
	Original: Task_Archive_SelectTransfer
	
	Revisions:
 */
 BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE	@BU_Date		DATETIME -- Next BalanceUp Date
		,	@CurrentBU_Date	DATETIME
		;

	--SELECT	@BU_Date		= DATEADD(DAY, 1, MAX(winlostdate))
	--	,	@CurrentBU_Date	= MIN(winlostdate)
	--FROM	dbo.Task_ArchiveDate;

	SELECT	@BU_Date		= @BUDate
		,	@CurrentBU_Date	= MIN(winlostdate)
	FROM	dbo.Task_ArchiveDate;

	-- Transfer Archive
	SELECT	[transid]		= transid
		,	[custid]		= custid
		,	[transdate]		= transdate
		,	[Debit]			= actual_stake
		,	[Credit]		= winlost
		,	[TransDesc]		= TransDesc
		,	[winlostdate]	= winlostdate
		,	[recommend]		= recommend
		,	[mrecommend]	= mrecommend
		,	[srecommend]	= srecommend
		,	[bettype]		= bettype
		,	[currency]		= currency
		,	[refno]			= refno
		,	[creator]		= creator
		,	[balance]		= balance
	FROM	dbo.bettrans WITH(NOLOCK)
	WHERE	ruben = 1
		AND	matchid = 0
		AND	bettype > 20000
		--AND	winlostdate >= @CurrentBU_Date
		AND	winlostdate < @BU_Date
		AND	custid <> 0
		AND	(winlost + actual_stake) <> 0;
	
END