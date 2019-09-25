SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
create PROCEDURE dbo.Task_Archive_bettrans_Staging
AS
/*
	Creator:	20161213@Lukas
	Task:		Get data from bettrans_Staging for archiving
	Database:	DBTXN.bodb02

	Revisions:
		- 20161213@Lukas:	Initial - [Redmine: #000000]
*/
BEGIN 
	SET NOCOUNT ON

	DECLARE  @max_winlostdate SMALLDATETIME,
			 @min_winlostdate SMALLDATETIME

	SELECT	 @max_winlostdate = MAX(winlostdate),@min_winlostdate = MIN(winlostdate)
	FROM	dbo.Task_ArchiveDate

	-- to DB06.bodb_Archive.dbo.translog_bk
	SELECT b.SeqId, OBTransId, ObBetType, Odds, ObCustId, Stake, ActualStake, b.GambleId, Payout, NumberofHit, isSkipped
	FROM dbo.bettrans_Staging b WITH(NOLOCK)
		INNER JOIN SettlementNG2_Message m WITH(NOLOCK) ON b.SeqId = m.SeqID
	WHERE
		m.EventDate BETWEEN @min_winlostdate AND @max_winlostdate
END
GO
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/