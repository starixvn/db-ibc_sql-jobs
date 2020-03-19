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
		- 20200122@Max: Support Separate setting and notification into Live/Non-Live major and minor bettypes [Redmine: #126841]
 */
BEGIN
	SET NOCOUNT ON
	
	DECLARE @MatchidList_copy AS TABLE (Matchid INT)
	INSERT INTO @MatchidList_copy (Matchid)
	SELECT matchid
	FROM DBAGE.bodb02.dbo.match14 WITH (NOLOCK)
	WHERE eventdate = @winlostdate

	SELECT	ts.CustID, ts.matchid, ts.MaxTurnOver, ts.TotalTurnOver, ts.IsNotified, ts.HouseTurnover, ts.PercentLevel, ts.IsGroupHeadLine, @winlostdate AS winlostdate, ts.ProfileID
	FROM dbo.TOControl_Setting ts WITH (NOLOCK)
		INNER JOIN @MatchidList_copy m ON ts.matchid = m.Matchid
	
END
GO
