/*<info serverAlias="DBCUST-CUSTDB" executers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_Archive_TOControl_Copy]
(
	@winlostdate DATETIME
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
	SELECT matchid
	FROM DBAGE.bodb02.dbo.match14 WITH (NOLOCK)
	WHERE eventdate = @winlostdate

	SELECT	ts.CustID, ts.matchid, ts.MaxTurnOver, ts.TotalTurnOver, ts.IsNotified, ts.HouseTurnover, ts.PercentLevel, ts.IsGroupHeadLine, @winlostdate AS winlostdate
	FROM dbo.TOControl_Setting ts WITH (NOLOCK)
		INNER JOIN @MatchidList_copy m ON ts.matchid = m.Matchid
	
END
GO
