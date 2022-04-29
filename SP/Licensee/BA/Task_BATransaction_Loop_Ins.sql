/*<info serverAlias="DBEXT-bodb02,DBACC-bodb02,DBBOF-bodb02,DBBAL-bodb02" executers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].Task_BATransaction_Loop_Ins
AS
/*
	Created by: Sol 
	Date: 20220429
	Task: Loop to call Insert BA Transaction (exec)
	DB: DBEXT-bodb02,DBACC-bodb02,DBBOF-bodb02,DBBAL-bodb02
	
	Revisions:
		- 20220427@Sol: SQL Server Upgrade to 2019 for DBMSG & enhance related jobs on replicated servers - [RedmineID: #171913]
*/
BEGIN
	
	SET NOCOUNT ON

	DECLARE @start DATETIME
	SELECT @start = CURRENT_TIMESTAMP

	WHILE (DATEDIFF(SECOND,@start, CURRENT_TIMESTAMP) <= 600) --loop 10 mins and then break
	BEGIN
		EXEC dbo.Task_BATransaction_Ins

		----run sp below depend on servers
		--local
		IF (@@SERVERNAME IN ('TESTDB053', 'TESTDB061'))
		BEGIN
			EXEC bodb_Licensee.dbo.Task_DetectBAMemberBreakRules
		END

		--SIT
		IF (@@SERVERNAME IN ('SITDB052', 'SITDB06', 'SITDBBAL'))
		BEGIN
			EXEC bodb_Licensee.dbo.Task_DetectBAMemberBreakRules
		END

		--PROD
		IF (@@SERVERNAME IN ('DB052', 'DB053', 'DB061', 'DB062', 'DBBAL'))
		BEGIN
			EXEC bodb_Licensee.dbo.Task_DetectBAMemberBreakRules
		END

		WAITFOR DELAY '00:00:01' -- waifor delay for [Retrieve BA Transaction] job
	END

END
GO