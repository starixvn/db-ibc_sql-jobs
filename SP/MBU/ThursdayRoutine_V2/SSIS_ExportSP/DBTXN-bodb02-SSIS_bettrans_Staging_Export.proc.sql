/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_bettrans_Staging_Export]
	@winlostdate smalldatetime=null
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]	
	Database: DBTXN.bodb02
	Original: Task_Archive_bettrans_Staging
	
	Revisions:
		- 20130831@Bobby: Init
 */
BEGIN 
	SET NOCOUNT ON

	DECLARE  @max_winlostdate SMALLDATETIME,
			 @min_winlostdate SMALLDATETIME

	--SELECT	 @max_winlostdate = MAX(winlostdate),@min_winlostdate = MIN(winlostdate)
	--FROM	dbo.Task_ArchiveDate

	SELECT	 @max_winlostdate = @winlostdate
		, @min_winlostdate = @winlostdate

	-- to DB06.bodb_Archive.dbo.translog_bk
	SELECT b.SeqId, OBTransId, ObBetType, Odds, ObCustId, Stake, ActualStake, b.GambleId, Payout, NumberofHit, isSkipped
	FROM dbo.bettrans_Staging b WITH(NOLOCK)
		INNER JOIN dbo.SettlementNG2_Message m WITH(NOLOCK) ON b.SeqId = m.SeqID
	WHERE
		m.EventDate BETWEEN @min_winlostdate AND @max_winlostdate
END
GO
