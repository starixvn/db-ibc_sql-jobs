/*<info serverAlias="DBSSIS-SSISDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_Process_CheckStatus] @SessionID INT
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]				
	Database:	DBSSIS.SSISDB
	Revisions:
		- 20130831@Bobby: Init
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @isClosed BIT;

	WHILE 1 = 1
	BEGIN
		IF EXISTS (
				SELECT 1
				FROM dbo.SSIS_PackageRuntime WITH (NOLOCK)
				WHERE RuntimeID = @SessionID
					AND STATUS = 'Closed'
				)
		BEGIN
			SET @isClosed = 1;

			BREAK;
		END
		ELSE
			WAITFOR DELAY '00:01:00'
	END

	-- RETURN:
	SELECT @isClosed AS [IsClosed]
		,SUM(CASE 
				WHEN rt.Error > 0
					THEN 1
				ELSE 0
				END) AS [FailedCount]
		,SUM(CASE 
				WHEN rt.Error = 0
					THEN 1
				ELSE 0
				END) AS [SuccessCount]
	FROM dbo.SSIS_PackageRuntime rt WITH (NOLOCK)
	WHERE rt.SessionID = @SessionID
		AND rt.DynamicMappingID > 0
END
GO


