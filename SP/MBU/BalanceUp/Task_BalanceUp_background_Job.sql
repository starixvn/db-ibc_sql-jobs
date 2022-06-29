/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Task_BalanceUp_background_Job
/*
    Created by: 20220602@Patrick
    Task: Task_BalanceUp_background_Job
    DB: DBTXN/BODB02 

	Revisions:
		- 20220602@Patrick: Revise BalanceUp background to support 247 [Redmine:#173554]
*/
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @__currBalanceUpDate SMALLDATETIME
		, @__fdate SMALLDATETIME
		, @__doing VARCHAR(300)

	IF EXISTS (
		SELECT TOP 1 1
		FROM dbo.SystemSettings
		WHERE VName = 'BeingBalanceUpDate' AND VValue IS NULL
	)
	BEGIN
		EXEC dbo.NAP_Admin_GetBalanceUpDate @BalanceUpDate = @__currBalanceUpDate OUTPUT
		SET @__fdate = DATEADD(DAY, 7, @__currBalanceUpDate)
		PRINT '@fdate = ' + CONVERT(VARCHAR(10), @__fdate, 120)

	END

	IF @__fdate IS NULL OR @__fdate >= CAST(GETDATE() AS DATE)
	BEGIN
		RAISERROR ('ERROR: Please check a balance-up date value. (1)', 16, 1);
		RETURN
	END

	SET @__doing = 'Task_BalanceUp_background_Job: calculate being balance up date, @__currBalanceUpDate: '+ CONVERT(VARCHAR(10), @__currBalanceUpDate, 121) +', @__fdate: ' + CONVERT(VARCHAR(10), @__fdate, 121)
	EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @__doing

	--verify with old way
	DECLARE @__verifyDate SMALLDATETIME
	SELECT TOP(1) @__verifyDate = DATEADD(DAY, 7, winlostdate)
	FROM dbo.Transfer WITH(NOLOCK)
	WHERE bettype = 20000
	ORDER BY transid

	IF @__verifyDate <> @__fdate
	BEGIN
		RAISERROR ('ERROR: Please check a balance-up date value. (2)', 16, 1);
		RETURN
	END

	DECLARE @__errorMessage VARCHAR(1024)

	/*
		if a step have an error then terminated job and return that error
	*/
	--//1: update being balance-up date
	BEGIN TRY
		SET @__errorMessage = ''
		EXEC dbo.Task_BalanceUp_background @fdate = @__fdate, @step = 1
	
	END TRY
	BEGIN CATCH
		SET @__errorMessage = ERROR_MESSAGE()
		SET @__doing = 'Task_BalanceUp_background: Error at step: ' + CAST(1 AS VARCHAR(10)) + ', errMsg: ' + @__errorMessage
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @__doing
		
		--throw exception and terminated process
		RAISERROR (@__errorMessage, 16, 1)
		RETURN
	END CATCH

	--//2: data verify
	BEGIN TRY
		SET @__errorMessage = ''
		EXEC dbo.Task_BalanceUp_background @fdate = @__fdate, @step = 2
	
	END TRY
	BEGIN CATCH
		SET @__errorMessage = ERROR_MESSAGE()
		SET @__doing = 'Task_BalanceUp_background: Error at step: ' + CAST(2 AS VARCHAR(10)) + ', errMsg: ' + @__errorMessage
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @__doing
		
		--throw exception and terminated process
		RAISERROR (@__errorMessage, 16, 1)
		RETURN
	END CATCH

	--//3: backup databases
	BEGIN TRY
		SET @__errorMessage = ''
		EXEC dbo.Task_BalanceUp_background @fdate = @__fdate, @step = 3
	
	END TRY
	BEGIN CATCH
		SET @__errorMessage = ERROR_MESSAGE()
		SET @__doing = 'Task_BalanceUp_background: Error at step: ' + CAST(3 AS VARCHAR(10)) + ', errMsg: ' + @__errorMessage
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @__doing
		
		--throw exception and terminated process
		RAISERROR (@__errorMessage, 16, 1)
		RETURN
	END CATCH

	--//4: calculate balance
	BEGIN TRY
		SET @__errorMessage = ''
		EXEC dbo.Task_BalanceUp_background @fdate = @__fdate, @step = 4
	
	END TRY
	BEGIN CATCH
		SET @__errorMessage = ERROR_MESSAGE()
		SET @__doing = 'Task_BalanceUp_background: Error at step: ' + CAST(4 AS VARCHAR(10)) + ', errMsg: ' + @__errorMessage
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @__doing
		
		--throw exception and terminated process
		RAISERROR (@__errorMessage, 16, 1)
		RETURN
	END CATCH

	--//5: insert new 20k
	BEGIN TRY
		SET @__errorMessage = ''
		EXEC dbo.Task_BalanceUp_background @fdate = @__fdate, @step = 5
	
	END TRY
	BEGIN CATCH
		SET @__errorMessage = ERROR_MESSAGE()
		SET @__doing = 'Task_BalanceUp_background: Error at step: ' + CAST(5 AS VARCHAR(10)) + ', errMsg: ' + @__errorMessage
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @__doing
		
		--throw exception and terminated process
		RAISERROR (@__errorMessage, 16, 1)
		RETURN
	END CATCH

	--//6: wait for replicated servers perform done and then go to update balanceUp date flag
	BEGIN TRY
		SET @__errorMessage = ''
		EXEC dbo.Task_BalanceUp_background @fdate = @__fdate, @step = 6
	
	END TRY
	BEGIN CATCH
		SET @__errorMessage = ERROR_MESSAGE()
		SET @__doing = 'Task_BalanceUp_background: Error at step: ' + CAST(6 AS VARCHAR(10)) + ', errMsg: ' + @__errorMessage
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @__doing
		
		--throw exception and terminated process
		RAISERROR (@__errorMessage, 16, 1)
		RETURN
	END CATCH

	--//7: --delete old data: old 20k, sum 19999 and transfer
	BEGIN TRY
		SET @__errorMessage = ''
		EXEC dbo.Task_BalanceUp_background @fdate = @__fdate, @step = 7
	
	END TRY
	BEGIN CATCH
		SET @__errorMessage = ERROR_MESSAGE()
		SET @__doing = 'Task_BalanceUp_background: Error at step: ' + CAST(7 AS VARCHAR(10)) + ', errMsg: ' + @__errorMessage
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @__doing
		
		--throw exception and terminated process
		RAISERROR (@__errorMessage, 16, 1)
		RETURN
	END CATCH

	--//8: ----turn off trigger | flag and completed balanceUP
	BEGIN TRY
		SET @__errorMessage = ''
		EXEC dbo.Task_BalanceUp_background @fdate = @__fdate, @step = 8
	
	END TRY
	BEGIN CATCH
		SET @__errorMessage = ERROR_MESSAGE()
		SET @__doing = 'Task_BalanceUp_background: Error at step: ' + CAST(8 AS VARCHAR(10)) + ', errMsg: ' + @__errorMessage
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @__doing
		
		--throw exception and terminated process
		RAISERROR (@__errorMessage, 16, 1)
		RETURN
	END CATCH
END
GO
