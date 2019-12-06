/*<info serverAlias="DBCUST-CUSTDB" executers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_Archive_TOControl_Delete]
(
	@matchIDs	NVARCHAR(MAX) = ''
)
AS					
/*
	Created: 20190318@Helen
	Database: DBCUST.CUSTDB
	Original: 
	
	Revisions:
		- 20191126@Helen: Archive TO Control - delete [Redimine:98467]
 */
BEGIN
	SET NOCOUNT ON
	
	DECLARE @MatchidList_delete AS TABLE (Matchid INT)

	INSERT INTO @MatchidList_delete (Matchid)
	SELECT val
	FROM dbo.f_StringSplit(@matchIDs, ',')
	OPTION (MAXRECURSION 0)
	
	WHILE (1=1)
	BEGIN
	
		DELETE TOP (2000) t
		FROM dbo.TOControl_Setting t WITH (ROWLOCK)
			INNER JOIN @MatchidList_delete m ON t.matchid = m.Matchid
			
		IF @@ROWCOUNT = 0 BREAK	
	END
	
END
GO