/*<info serverAlias="DBTP-bodb_SSIS" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_PackageRuntime_PreInit]
	@minDate smalldatetime
	,@maxdate smalldatetime
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]				
	Database:	DBTP.bodb_SSIS
	Revisions:
		- 20130831@Bobby: Init
*/
BEGIN
	SET NOCOUNT ON;

	WITH cte (Winlostdate)
	AS (
		SELECT @minDate
	
		UNION ALL

		SELECT DATEADD(DAY, 1, Winlostdate)
		FROM cte
		WHERE Winlostdate < @maxdate
	)
	SELECT Winlostdate
	FROM cte
	WHERE @minDate <= @maxdate
	ORDER BY Winlostdate ASC;

END
GO
