/*<info serverAlias="DBAGE-bodb02" executers="" isFunction="0" isNested="0"></info>*/
USE [bodb02]
GO

CREATE PROCEDURE [dbo].[Task_bet14_CheckDataIsReady]
AS

/*
	Created: 20190416@Percy
	DB: DBAGE.bodb02
	Task: Check data bettrans/bettrans14 is ready (MBBU)

	Revisions:
		- 20190416@Percy: Initialize SP [RedmineID: #111937]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Days TABLE (ScheduleId TINYINT, winlostdate SMALLDATETIME, isFinished BIT DEFAULT(0))
	
	INSERT INTO @Days (ScheduleId, winlostdate)
	EXEC DBTXN.bodb02.dbo.Task_MoveBetsDayByScheduleSel

	DECLARE @winlostdate SMALLDATETIME, @ErrMsg VARCHAR(500)
	DECLARE @tmp TABLE (ServerName SYSNAME, TableName SYSNAME, RowCnt INT)

	WHILE 1 = 1
	BEGIN
		UPDATE @Days
		SET @winlostdate = winlostdate,
			isFinished = 1
		WHERE isFinished = 0

		IF @@ROWCOUNT = 0
			BREAK

		-- bettrans14
		INSERT INTO @tmp (ServerName, TableName, RowCnt)
		SELECT @@SERVERNAME, 'bettrans14', COUNT(1) FROM dbo.bettrans14 WITH (NOLOCK) WHERE winlostdate = @winlostdate

		INSERT INTO @tmp (ServerName, TableName, RowCnt)
		SELECT 'DB06', 'bettrans14', COUNT(1) FROM DB06.bodb02.dbo.bettrans14 WITH (NOLOCK) WHERE winlostdate = @winlostdate

		-- bettransm14
		INSERT INTO @tmp (ServerName, TableName, RowCnt)
		SELECT @@SERVERNAME, 'bettransm14', COUNT(1) FROM dbo.bettransm14 WITH (NOLOCK) WHERE winlostdate = @winlostdate

		INSERT INTO @tmp (ServerName, TableName, RowCnt)
		SELECT 'DB06', 'bettransm14', COUNT(1) FROM DB06.bodb02.dbo.bettransm14 WITH (NOLOCK) WHERE winlostdate = @winlostdate
	END

	DECLARE @TableList VARCHAR(200)

	SELECT  @TableList = COALESCE(@TableList + ',', '') + t1.TableName
	FROM @tmp t1
		INNER JOIN @tmp t2 ON t1.TableName = t2.TableName AND t1.ServerName = @@SERVERNAME AND t2.ServerName = 'DB06'
	WHERE t1.RowCnt <> t2.RowCnt

	IF @TableList IS NOT NULL
	BEGIN
		SELECT @ErrMsg = 'Data ' + @TableList + ' is consistency with DB06. Please help check!'
		
		RAISERROR(@ErrMsg, 16, 1)
		RETURN
	END
END
GO