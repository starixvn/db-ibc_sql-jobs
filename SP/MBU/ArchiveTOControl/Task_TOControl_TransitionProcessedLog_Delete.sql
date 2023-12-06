/*<info serverAlias="DBCUST-CUSTDB" executers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_TOControl_TransitionProcessedLog_Delete]
AS					
/*
	Created: 20231204@Max
	Database: DBCUST.CUSTDB
	Original: 
	
	Revisions:
		- 20231204@Max: Clean up data new table TOControl_TransitionProcessedLog  [Redimine: #197464]
 */
BEGIN
	SET NOCOUNT ON
	
	DECLARE @ArchivedDate DATETIME
	SET @ArchivedDate = DATEADD(DAY, -7, GETDATE())
	
	WHILE (1=1)
	BEGIN
		DELETE TOP (4500) t
		FROM dbo.TOControl_TransitionProcessedLog t WITH (ROWLOCK)
		WHERE t.CreatedDate <= @ArchivedDate

		IF @@ROWCOUNT = 0 BREAK	
	END
	
END
GO
