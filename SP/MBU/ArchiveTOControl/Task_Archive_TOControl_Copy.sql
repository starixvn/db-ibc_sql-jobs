/*<info serverAlias="DBCUST-CUSTDB" executers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Archive_TOControl_Copy]
(
	@matchIDs	NVARCHAR(MAX) = ''
)
AS				
/*
	Created: 20190318@Helen
	Database: DBCUST.CUSTDB
	Original: 
	
	Revisions:
		- 20191126@Helen: Archive TO Control - copy [Redimine:98467]
 */
BEGIN
	SET NOCOUNT ON
	
	DECLARE @MatchidList_copy AS TABLE (Matchid INT)
	INSERT INTO @MatchidList_copy (Matchid)
	SELECT val
	FROM dbo.f_StringSplit(@matchIDs, ',')
	OPTION (MAXRECURSION 0)

	SELECT	ts.CustID, ts.matchid, ts.MaxTurnOver, ts.TotalTurnOver, ts.IsNotified, ts.HouseTurnover, ts.PercentLevel, ts.IsGroupHeadLine
	FROM dbo.TOControl_Setting ts WITH (NOLOCK)
		INNER JOIN @MatchidList_copy m ON ts.matchid = m.Matchid
	
END
GO