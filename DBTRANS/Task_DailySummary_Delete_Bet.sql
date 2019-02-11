/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb02]
GO
ALTER PROCEDURE [dbo].[Task_DailySummary_Delete_Bet]
	@winlostdate DATETIME,
	@tableName VARCHAR(200) = ''
AS
/*
	Created: Patrick@20190131
	Task: Deleting data warrper
	DB: DBTXN/BODB02
	Revisions:
		- 20190131@Patrick: Deleting data in bettransm batch by batch [RedmineID: #108581]

*/
BEGIN
	IF @tableName = 'bettransm'
	BEGIN
		DECLARE @rowId INT, @matchid INT, @delayTimeValueM VARCHAR(20)
		CREATE TABLE #m (rn int PRIMARY KEY IDENTITY(1,1), matchid INT)

		INSERT INTO #m (matchid)
		SELECT DISTINCT m.matchid
		FROM dbo.bettransm b WITH (NOLOCK)
			INNER JOIN dbo.match m WITH (NOLOCK) ON b.matchid = m.matchid
		WHERE winlostdate = @winlostdate

		SELECT @rowId = 1, @delayTimeValueM = '00:00:00:010'

		WHILE EXISTS (SELECT TOP 1 1 FROM #m WHERE rn = @rowId)
		BEGIN
		
			SELECT @matchid = matchid FROM #m WHERE rn = @rowId

			SET @rowId = @rowId + 1

			EXEC dbo.ExecRep_09 @recommend = 0
				, @winlostdate = @winlostdate, @parlay = 1
				, @tableName = 'bettransM', @matchid = @matchid

			SELECT @delayTimeValueM = dbo.f_BU_GetDelayTime('Key10')
			WAITFOR DELAY @delayTimeValueM
		END

		--last round
		EXEC dbo.ExecRep_09 @recommend = 0
				, @winlostdate = @winlostdate, @parlay = 1
				, @tableName = 'bettransM', @matchid = -1
	
		DROP TABLE #m
	END
END

GO