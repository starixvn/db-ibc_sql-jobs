/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_Transfer_Export]
	@winlostdate smalldatetime=null
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]	
	Database: DBTXN.bodb02
	Original: Task_Archive_SelectTransfer
	
	Revisions:
		- 20130831@Bobby: Init
 */
 BEGIN
	SET NOCOUNT ON;
	
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
	FROM	dbo.Transfer WITH(NOLOCK)
	WHERE	bettype > 20000
			AND	winlostdate = @WinlostDate
			AND	custid <> 0
			AND	(winlost + actual_stake) <> 0;
	
END