/*<info serverAlias="DBCUST-CustDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_TOControl_Setting_Export]
	@winlostdate smalldatetime=null
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]	
	Database: DBCUST.CustDB
	Original: Task_Archive_TOControl_Copy
	
	Revisions:
		- 20130831@Bobby: Init
 */
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @MatchidList_copy AS TABLE (Matchid INT PRIMARY KEY);

	INSERT INTO @MatchidList_copy (Matchid)
	SELECT matchid
	FROM DBAGE.bodb02.dbo.match14 WITH (NOLOCK)
	WHERE eventdate = @winlostdate

	SELECT	ts.CustID, ts.matchid, ts.MaxTurnOver, ts.TotalTurnOver, ts.IsNotified, ts.HouseTurnover, ts.PercentLevel, ts.IsGroupHeadLine
		, @winlostdate AS winlostdate
		, ts.ProfileID, ts.IsGlobalLockTOLimit, ts.IsEventLockTOLimit
	FROM dbo.TOControl_Setting ts WITH (NOLOCK)
		INNER JOIN @MatchidList_copy m ON ts.matchid = m.Matchid
END
GO