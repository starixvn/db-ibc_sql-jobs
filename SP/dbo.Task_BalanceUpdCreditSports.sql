/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" selecters="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_BalanceUpdCreditSports]
AS
/*
    Created: @Joe
    Task: 
    DB: DBTXN/bodb02
    Revisions:
		- 20210810@Kathy: support update balance for multiple cust  [Redmine:#159486]
		- 20220927@Helen: Enhancement - avoid wrong balance value due to DBTrans got issue [Redmine:#178231]
	
	Notes:	
		capture info
		update info
		update state = 1   (lock rmax: next is create SUM)

		calculate SUM
		update ID = 0
		update state = 2   (done create SUM: next is update)

		loop
		update to Balance
		update ID = <max of that round>
		update state = 3  (done update: next is delete)

		loop
		delete pending
		update state = 0   (done delete: finished)
	
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Version			SMALLMONEY 
			,@StartSP			DATETIME2
			,@StartProcess		DATETIME2
			,@MinPendingTime	DATETIME2
			,@totalCustID		INT
			,@loopCnt			INT
			,@i					INT
			,@BatchNoUpd		INT
			,@BatchNoDel		INT
			,@minrn				BIGINT
			,@maxrn				BIGINT			
			,@Retry				INT
			,@TotalRetryUpd		INT
			,@TotalRetryDel		INT
			,@Success			BIT			
			,@secUpdate			SMALLMONEY = 0
			,@secDelete			SMALLMONEY = 0
			,@Top				INT
			,@ErrMsg			VARCHAR(300)
	
	DECLARE @del_StartRow INT = 1, @del_StopRow INT 

	SELECT	@Version = 3.1
			,@StartSP = SYSDATETIME()
			,@BatchNoUpd = 100
			,@BatchNoDel = 3000
			,@TotalRetryUpd = 0
			,@TotalRetryDel = 0
			,@Top = 100000

	Declare @Process_State BIGINT
	SELECT @Process_State = VValue FROM dbo.BalanceUpdateSetting WITH (NOLOCK) WHERE VName = 'PendingCS_State'

-- Job resume : begin
	IF @Process_State = 3
	BEGIN
		SELECT @minrn = VValue FROM dbo.BalanceUpdateSetting WITH (NOLOCK) WHERE VName = 'PendingCS_rnMIN'
		SELECT @maxrn = VValue FROM dbo.BalanceUpdateSetting WITH (NOLOCK) WHERE VName = 'PendingCS_rnMAX'
		SELECT @MinPendingTime = VValue FROM dbo.BalanceUpdateSetting WITH (NOLOCK) WHERE VName = 'PendingCS_tstamp'
		SELECT @totalCustID = VValue FROM dbo.BalanceUpdateSetting WITH (NOLOCK) WHERE VName = 'PendingCS_TotalCust'

		GOTO DeleteSection
	END

	IF @Process_State = 2
	BEGIN
		SELECT @totalCustID = VValue FROM dbo.BalanceUpdateSetting WITH (NOLOCK) WHERE VName = 'PendingCS_TotalCust'
		SELECT @i = VValue FROM dbo.BalanceUpdateSetting  WITH (NOLOCK) WHERE VName = 'PendingCS_updID'
		SELECT @MinPendingTime = VValue FROM dbo.BalanceUpdateSetting  WITH (NOLOCK) WHERE VName = 'PendingCS_tstamp'
		SELECT @maxrn = VValue FROM BalanceUpdateSetting WITH (NOLOCK) WHERE VName = 'PendingCS_rnMAX'
		SELECT @minrn = VValue FROM BalanceUpdateSetting WITH (NOLOCK) WHERE VName = 'PendingCS_rnMIN'

		SET @loopCnt = @totalCustID 
		SET @i = @i + 1

		GOTO UpdateSection
	END

	IF @Process_State = 1
	BEGIN
		--print 'prepare to go CreateSum'
		SELECT @MinPendingTime = VValue FROM dbo.BalanceUpdateSetting  WITH (NOLOCK) WHERE VName = 'PendingCS_tstamp'
		SELECT @maxrn = VValue FROM BalanceUpdateSetting WITH (NOLOCK) WHERE VName = 'PendingCS_rnMAX'
		SELECT @minrn = VValue FROM BalanceUpdateSetting WITH (NOLOCK) WHERE VName = 'PendingCS_rnMIN'
		GOTO CreateSum
	END

-- Job resume : end
	IF @Process_State = 0 -- capture rn min/max
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.BalCreditSportsPending)
		BEGIN
			WAITFOR DELAY '000:00:01.000'
			RETURN -- no data to be update.
		END

		;WITH ctePending
		AS(
			SELECT	TOP (@Top) rn, tstamp
			FROM	dbo.BalCreditSportsPending WITH(NOLOCK)
			ORDER BY rn
		)
		SELECT TOP (@Top)
				@minrn = MIN(rn)	
				,@maxrn = MAX(rn)
				,@MinPendingTime = MIN(tstamp)
		FROM	ctePending

		BEGIN TRANSACTION
			UPDATE dbo.BalanceUpdateSetting WITH (ROWLOCK) SET VValue = @minrn WHERE VName = 'PendingCS_rnMIN'
			UPDATE dbo.BalanceUpdateSetting WITH (ROWLOCK) SET VValue = @maxrn WHERE VName = 'PendingCS_rnMAX'
			UPDATE dbo.BalanceUpdateSetting WITH (ROWLOCK) SET VValue = CONVERT(VARCHAR(50), @MinPendingTime, 121) WHERE VName = 'PendingCS_tstamp'
			UPDATE dbo.BalanceUpdateSetting WITH (ROWLOCK) SET VValue = 1 WHERE VName = 'PendingCS_State'
			
		COMMIT TRANSACTION

		WAITFOR DELAY '00:00:00.020'
	END

CreateSUM:
	TRUNCATE TABLE BalCreditSportsPending_Staging

	--PRINT 'CreateSum'
	BEGIN TRANSACTION

		INSERT INTO dbo.BalCreditSportsPending_Staging (custid, balance)
		SELECT custid, SUM(balance)
		FROM dbo.BalCreditSportsPending with (ROWLOCK)
		WHERE rn >= @minrn AND rn <= @maxrn
		GROUP BY custid
		ORDER BY MIN(rn)

		SET @totalCustID = @@ROWCOUNT
		SET @i = 1
		SET @loopCnt = @totalCustID

		UPDATE dbo.BalanceUpdateSetting WITH (ROWLOCK) SET VValue = 0 WHERE VName = 'PendingCS_updID'
		UPDATE dbo.BalanceUpdateSetting WITH (ROWLOCK) SET VValue = @totalCustID WHERE VName = 'PendingCS_TotalCust'
		UPDATE dbo.BalanceUpdateSetting WITH (ROWLOCK) SET VValue = 2 WHERE VName = 'PendingCS_State'
		UPDATE dbo.BalanceUpdateSetting WITH (ROWLOCK) SET VValue =CONVERT(VARCHAR(50), GETDATE(),121) WHERE VName = 'PendingCS_CreatedDate'

	COMMIT TRANSACTION

UpdateSection:
	SET @StartProcess = SYSDATETIME()
	-- SELECT @i as i, @loopCnt as loopCnt
	WHILE @i <= @loopCnt
	BEGIN
		SET @Retry = 0
		SET @Success = 0

		-- perform update
		WHILE @Success = 0
		BEGIN
			BEGIN TRY
				SET @Success = 1
				SET @ErrMsg = ''

				BEGIN TRANSACTION	
					--PRINT 'updating'
					UPDATE b
						SET Balance = b.Balance + t.balance
					FROM	dbo.BalCreditSports b WITH (ROWLOCK, UPDLOCK)
						INNER JOIN dbo.BalCreditSportsPending_Staging t (NOLOCK)
							ON b.custid = t.custId	
					WHERE Id BETWEEN @i AND @i + @BatchNoUpd - 1

					UPDATE dbo.BalanceUpdateSetting WITH (ROWLOCK) SET VValue = @i + @BatchNoUpd - 1 WHERE VName = 'PendingCS_updID'

				COMMIT TRANSACTION
				
			END TRY
			BEGIN CATCH
				SET @Retry = @Retry + 1
				SET @Success = 0
				SET @ErrMsg = ERROR_MESSAGE()
				ROLLBACK TRANSACTION

				WAITFOR DELAY '00:00:00:010'
			END CATCH
		END
		SET @i = @i + @BatchNoUpd
		
	END

	UPDATE dbo.BalanceUpdateSetting WITH (ROWLOCK) SET VValue = 3 WHERE VName = 'PendingCS_State'
	
	SET @secUpdate = DATEDIFF(ms, @StartProcess, SYSDATETIME())/1000.00

DeleteSection:
	SET @StartProcess = SYSDATETIME()

	-- SET param for the first batch of deleting
	SET @del_StartRow = @minrn 
	SET @del_StopRow = @minrn + @BatchNoDel 

	IF @del_StopRow > @maxrn
		SET @del_StopRow = @maxrn
	
	-- remove data which already updated.
	WHILE (1=1)
	BEGIN
		BEGIN TRY
			
			DELETE 
			FROM	dbo.BalCreditSportsPending
			WHERE	rn BETWEEN @del_StartRow AND @del_StopRow

			IF @del_StopRow = @maxrn BREAK

			SET @del_StartRow = @del_StopRow + 1
			SET @del_StopRow = @del_StopRow + @BatchNoDel
			
			IF @del_StopRow > @maxrn
				SET @del_StopRow = @maxrn
			
		END TRY
		BEGIN CATCH
			SET @i = 1
			SET @TotalRetryDel = @TotalRetryDel + 1
		END CATCH
	END

	UPDATE dbo.BalanceUpdateSetting WITH (ROWLOCK) SET VValue = 0 WHERE VName = 'PendingCS_State'
	
	SET @secDelete = DATEDIFF(ms, @StartProcess, SYSDATETIME())/1000.00
	
LogProcess:
	-- log process
	INSERT INTO dbo.BalancePendingProcessed (byVersion, secPending, totalCustID
		, retryCnt, retryDelCnt, secUpdate, secDelete, secProcess, Operation, tableSet)
	SELECT @Version * 100,
		DATEDIFF(ms, @MinPendingTime, @StartSP)/1000.00, @totalCustID
		,@TotalRetryUpd
		,@TotalRetryDel
		,@secUpdate
		,@secDelete
		,DATEDIFF(ms, @StartSP, SYSDATETIME())/1000.00, 'C', 1
END
GO