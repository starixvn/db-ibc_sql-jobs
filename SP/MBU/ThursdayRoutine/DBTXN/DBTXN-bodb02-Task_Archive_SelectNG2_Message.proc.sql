SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE	dbo.Task_Archive_SelectNG2_Message
AS
/*
	Creator:	20161213@Lukas
	Task:		Get data from SettlementNG2_Message for archiving
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

	-- to DB06.bodb_Archive.dbo.SettlementNG2_Message
	SELECT SeqID, CreationTime, DoneAPI_Time, TotalRow, StartCalculate_Time, DoneCalculate_Time, Status, Task, EventDate, GambleID, MatchId 
	FROM dbo.SettlementNG2_Message m   WITH(NOLOCK)
	WHERE
		m.EventDate BETWEEN @min_winlostdate AND @max_winlostdate
END
GO
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/