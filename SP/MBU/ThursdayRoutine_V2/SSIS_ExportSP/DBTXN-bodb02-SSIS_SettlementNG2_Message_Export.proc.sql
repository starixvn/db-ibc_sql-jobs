/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_SettlementNG2_Message_Export]
	@winlostdate smalldatetime=null
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]	
	Database: DBTXN.bodb02
	Original: Task_Archive_SelectNG2_Message 
	
	Revisions:
 */
 BEGIN 
	SET NOCOUNT ON

	DECLARE  @max_winlostdate SMALLDATETIME,
			 @min_winlostdate SMALLDATETIME

	--SELECT	 @max_winlostdate = MAX(winlostdate),@min_winlostdate = MIN(winlostdate)
	--FROM	dbo.Task_ArchiveDate

	SELECT	 @max_winlostdate = @winlostdate
		,@min_winlostdate = @winlostdate

	-- to DB06.bodb_Archive.dbo.translog_bk
	SELECT SeqID, CreationTime, DoneAPI_Time, TotalRow, StartCalculate_Time, DoneCalculate_Time, Status, Task, EventDate, GambleID, MatchId 
	FROM dbo.SettlementNG2_Message m   WITH(NOLOCK)
	WHERE
		m.EventDate BETWEEN @min_winlostdate AND @max_winlostdate
END
GO

