USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Task_Archive_SettleTickets]
AS
/*
	Create By: 20180625@Patrick
	Task: Remove data after movebet days
	DB: DB042/bodb02
	
	Para's explaination
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @__MovebetDays TABLE(rowId INT IDENTITY(1,1), winlostdate SMALLDATETIME)

	INSERT INTO @__MovebetDays(winlostdate)
	SELECT winlostdate FROM dbo.Task_ArchiveBet WITH(NOLOCK) ORDER BY winlostdate

	IF @@ROWCOUNT = 0
		RETURN
	
	DECLARE @rowId INT = 1, @winlostdate SMALLDATETIME
	WHILE EXISTS (SELECT TOP 1 1 FROM @__MovebetDays WHERE rowId = @rowId)
	BEGIN
		SELECT @winlostdate = winlostdate FROM @__MovebetDays WHERE rowId = @rowId
		SET @rowId += 1

		WHILE (1 = 1) --bettrans
		BEGIN 
	
			DELETE TOP (4000) dbo.bettrans WITH(ROWLOCK)	
			WHERE winlostdate = @winlostdate

			IF @@ROWCOUNT < 4000 BREAK
			WAITFOR DELAY '00:00:00.010'
		END

		WHILE (1 = 1) --bettransRnG
		BEGIN 
	
			DELETE TOP (4000) dbo.bettransRnG WITH(ROWLOCK)
			WHERE winlostdate = @winlostdate

			IF @@ROWCOUNT < 4000 BREAK
			WAITFOR DELAY '00:00:00.010'
		END

		WHILE (1 = 1) --translog
		BEGIN 	
			DELETE TOP (4000) dbo.translog WITH(ROWLOCK)
			WHERE winlostdate = @winlostdate

			IF @@ROWCOUNT < 4000 BREAK
			WAITFOR DELAY '00:00:00.010'
		END

		WHILE (1 = 1) --bettransLC
		BEGIN 	
			DELETE TOP (4000) dbo.bettransLC WITH(ROWLOCK)
			WHERE winlostdate = @winlostdate

			IF @@ROWCOUNT < 4000 BREAK
			WAITFOR DELAY '00:00:00.010'
		END

		WHILE (1 = 1) --bettransG
		BEGIN 	
			DELETE TOP (4000) dbo.bettransG WITH(ROWLOCK)
			WHERE winlostdate = @winlostdate

			IF @@ROWCOUNT < 4000 BREAK
			WAITFOR DELAY '00:00:00.010'
		END

		--//bettransm
		EXEC [dbo].[Task_Archive_SettleTickets_bettransM] @winlostdate = @winlostdate

	END
END
