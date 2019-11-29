/*<info serverAlias="DB042-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_Archive_SettleTickets]
AS
/*
	Create By: 20180625@Patrick
	Task: Remove data after movebet days
	DB: DB042/bodb02
	Revisions: 
		-20190911@Patrick: Add more table BettransInfo
		-20191127@Patrick: Setup sync status ticket on DB052 -> DB054 - [Redmine: #124482]
	
	Para's explaination
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @__MovebetDays TABLE(rowId INT IDENTITY(1,1), winlostdate SMALLDATETIME)

	INSERT INTO @__MovebetDays(winlostdate)
	SELECT winlostdate FROM dbo.Task_ArchiveBet WITH(NOLOCK) ORDER BY winlostdate

	IF @@ROWCOUNT = 0
		RETURN
	
	DECLARE	@__tmpTransId AS TABLE (transid BIGINT PRIMARY KEY CLUSTERED)
	DECLARE @affectedRow INT

	DECLARE @rowId INT = 1, @winlostdate SMALLDATETIME
	WHILE EXISTS (SELECT TOP 1 1 FROM @__MovebetDays WHERE rowId = @rowId)
	BEGIN
		SELECT @winlostdate = winlostdate FROM @__MovebetDays WHERE rowId = @rowId
		SET @rowId += 1

		WHILE (1 = 1) --bettrans
		BEGIN 
			DELETE	@__tmpTransId

			DELETE TOP (3000) dbo.bettrans WITH(ROWLOCK)
			OUTPUT	Deleted.transid INTO @__tmpTransId (transid)
			WHERE winlostdate = @winlostdate

			SET @affectedRow = @@ROWCOUNT

			DELETE FROM dbo.BettransInfo WITH (ROWLOCK)
			WHERE EXISTS (SELECT TOP 1 1 FROM @__tmpTransId t WHERE t.transid = BettransInfo.transid)

			IF @affectedRow < 3000 BREAK

			WAITFOR DELAY '00:00:00.010'
		END

		WHILE (1 = 1) --bettransRnG
		BEGIN 
	
			DELETE TOP (3000) dbo.bettransRnG WITH(ROWLOCK)
			WHERE winlostdate = @winlostdate

			IF @@ROWCOUNT < 3000 BREAK
			WAITFOR DELAY '00:00:00.010'
		END

		WHILE (1 = 1) --translog
		BEGIN 	
			DELETE TOP (3000) dbo.translog WITH(ROWLOCK)
			WHERE winlostdate = @winlostdate

			IF @@ROWCOUNT < 3000 BREAK
			WAITFOR DELAY '00:00:00.010'
		END

		WHILE (1 = 1) --bettransLC
		BEGIN 	
			DELETE TOP (3000) dbo.bettransLC WITH(ROWLOCK)
			WHERE winlostdate = @winlostdate

			IF @@ROWCOUNT < 3000 BREAK
			WAITFOR DELAY '00:00:00.010'
		END

		WHILE (1 = 1) --bettransG
		BEGIN 	
			DELETE TOP (3000) dbo.bettransG WITH(ROWLOCK)
			WHERE winlostdate = @winlostdate

			IF @@ROWCOUNT < 3000 BREAK
			WAITFOR DELAY '00:00:00.010'
		END

		--//bettransm
		EXEC [dbo].[Task_Archive_SettleTickets_bettransM] @winlostdate = @winlostdate

	END
END

GO


