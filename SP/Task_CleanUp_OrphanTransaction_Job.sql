/*<info serverAlias="DBCTG-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_CleanUp_OrphanTransaction_Job]
AS 
/*
Created by: 20220817@Victoria
Task: Clean Up custid equal to zero - DBTrans
DB: DBCTG-bodb02
Revisions:
	- 20220817@Victoria: Deleting records with custid equal to zero for the following tables: 
							bettrans/bettransLC/bettransRnG/Transfer/TransferInfo/Transfer_Coll [Redmine:#176760]
	
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @Days AS TABLE (ScheduleId TINYINT, RunningDay DATETIME)
	DECLARE @MovebetDate SMALLDATETIME = NULL, @batch_cnt INT = 2000
	INSERT INTO @Days (ScheduleId, RunningDay)
	EXEC dbo.Task_MoveBetsDayByScheduleSel 

	SET @MovebetDate = (SELECT MAX(runningDay) FROM @Days)
	
	IF @MovebetDate IS NULL 
		RETURN

	WHILE (1=1)
	BEGIN
		DELETE TOP(@batch_cnt) b
		FROM dbo.bettrans b WITH(ROWLOCK)
		WHERE b.winlostdate <= @MovebetDate AND b.custid = 0

		IF @@ROWCOUNT = 0 
			BREAK

		WAITFOR DELAY '00:00:00:050'
	END

	WHILE (1=1)
	BEGIN
		DELETE TOP(@batch_cnt) b
		FROM dbo.bettransLC b WITH(ROWLOCK)
		WHERE b.winlostdate <= @MovebetDate AND b.custid = 0

		IF @@ROWCOUNT = 0 
			BREAK

		WAITFOR DELAY '00:00:00:050'
	END

	WHILE (1=1)
	BEGIN
		DELETE TOP(@batch_cnt) b
		FROM dbo.bettransRnG b WITH(ROWLOCK)
		WHERE b.winlostdate <= @MovebetDate AND b.custid = 0

		IF @@ROWCOUNT = 0 
			BREAK

		WAITFOR DELAY '00:00:00:050'
	END

	
	WHILE (1=1)
	BEGIN
		DELETE TOP(@batch_cnt) binfo
		FROM dbo.TransferInfo binfo WITH(ROWLOCK)
			INNER JOIN dbo.Transfer b WITH(NOLOCK) ON b.TransId = binfo.TransId
		WHERE b.winlostdate <= @MovebetDate AND b.custid = 0

		IF @@ROWCOUNT = 0 
			BREAK

		WAITFOR DELAY '00:00:00:050'
	END
	
	WHILE (1=1)
	BEGIN
		DELETE TOP(@batch_cnt) b
		FROM dbo.Transfer b WITH(ROWLOCK)
		WHERE b.winlostdate <= @MovebetDate AND b.custid = 0

		IF @@ROWCOUNT = 0 
			BREAK

		WAITFOR DELAY '00:00:00:050'
	END
	
	WHILE (1=1)
	BEGIN
		DELETE TOP(@batch_cnt) b
		FROM dbo.Transfer_Coll b WITH(ROWLOCK)
		WHERE b.winlostdate <= @MovebetDate AND b.custid = 0

		IF @@ROWCOUNT = 0 
			BREAK

		WAITFOR DELAY '00:00:00:050'
	END
END

