USE [bodb_Report]
GO
ALTER PROCEDURE [dbo].[TASK_DailyArchiveDepData]
AS
	/*
		Created By: Francis
		Created Date: 20160815
		Task: Daily Archive data for Deposit summary system
		DB: DBRPT.bodb_Report
		Revisions:
		Input Params:	
	*/
BEGIN
	SET NOCOUNT ON
	DECLARE @CurrentDate DATE,
			@CurrentHour TINYINT,
			@LogDesc VARCHAR(8000) = 'Date generated: ',
			@MinSumDate DATE,
			@MaxArchiveDate DATE,
			@MaxSumDate DATE,
			@LogID BIGINT,
			@isSuccessful BIT = 0,
			@NumberofCus INT
			
	SELECT @CurrentDate = CONVERT(DATE,CURRENT_TIMESTAMP,112)
	SELECT @CurrentHour = DATEPART(HOUR,CURRENT_TIMESTAMP)
	SELECT @MinSumDate = MIN(winlostdate) FROM dbo.rptDepWinlost_Main WITH (NOLOCK) 
	SELECT @MaxArchiveDate = CONVERT(DATE,DATEADD(DAY,-15,CURRENT_TIMESTAMP),112) 
	SELECT @MaxSumDate = CONVERT(DATE,DATEADD(DAY,-6,CURRENT_TIMESTAMP),112)
		
	--1.Insert Log
	INSERT INTO dbo.rptDepWinlost_Log(Logdate, LogHour, LogType, StartTime)
		SELECT @CurrentDate, @CurrentHour, 2, CURRENT_TIMESTAMP AS StartTime
		
	SELECT @LogID = @@IDENTITY

	--2.Update SystemSettings
	UPDATE bodb02.dbo.SystemSettings WITH (ROWLOCK, UPDLOCK) 
	SET VValue = '1'
	WHERE VName = 'isArchivingDEPdata'
	
	
	WHILE @MinSumDate <= @MaxSumDate
	BEGIN
		IF @MinSumDate <= @MaxArchiveDate
			BEGIN
				--3.Copy data for rptDepWinlost
				IF NOT EXISTS (SELECT TOP 1 1 FROM rptDepWinlost_bk WITH (NOLOCK) WHERE winlostdate = @MinSumDate)
					INSERT INTO dbo.rptDepWinlost_bk (
						winlostdate, custid, currency, OpeningBalance, Deposit, Withdrawal, Aff2MemTransfer, Bonus, Adjustment, Turnover, Outstanding, Winloss, 
						ClosingBalance, recommend, mrecommend, srecommend, actualrate, Transfer3rd, DrawGame, Turnover_tdate, Turnover_BA, Comm_BA, 
						AmountDueTo_BA, playercomm, Transfer3rdOthers, comm_bettrade, amountdueto_bettrade)
					SELECT winlostdate, custid, currency, OpeningBalance, Deposit, Withdrawal, Aff2MemTransfer, Bonus, Adjustment, Turnover, Outstanding, Winloss, 
							ClosingBalance, recommend, mrecommend, srecommend, actualrate, Transfer3rd, DrawGame, NULL, Turnover_BA, Comm_BA, 
							AmountDueTo_BA, playercomm, Transfer3rdOthers, comm_bettrade, amountdueto_bettrade
					FROM dbo.rptDepWinlost WITH (NOLOCK)
					WHERE winlostdate = @MinSumDate
							
				--3.Copy data for rptDepWinlostByProduct
				IF NOT EXISTS (SELECT TOP 1 1 FROM rptDepWinlostByProduct_bk WITH (NOLOCK) WHERE winlostdate = @MinSumDate)
					INSERT INTO dbo.rptDepWinlostByProduct_bk (
						winlostdate, custid, sporttype, currency, turnover, drawTO, winlost, playercomm, BetCount, outstanding)
					SELECT winlostdate, custid, sporttype, currency, turnover, drawTO, winlost, playercomm, BetCount, outstanding
					FROM dbo.rptDepWinlostByProduct WITH (NOLOCK) 
					WHERE winlostdate = @MinSumDate 
					
				--3.Copy data for rptDepWinlost_Transfer3rdOthers
				IF NOT EXISTS (SELECT TOP 1 1 FROM rptDepWinlost_Transfer3rdOthers_bk WITH (NOLOCK) WHERE winlostdate = @MinSumDate)
					INSERT INTO dbo.rptDepWinlost_Transfer3rdOthers_Bk (
							winlostdate,CustId,Currency,PartnerId,Recommend,MRecommend,SRecommend,TransferAmount,TransferIn,TransferOut)
					SELECT winlostdate,CustId,Currency,PartnerId,Recommend,MRecommend,SRecommend,TransferAmount,TransferIn,TransferOut
					FROM dbo.rptDepWinlost_Transfer3rdOthers WITH (NOLOCK)
					WHERE winlostdate = @MinSumDate

				--4.Delete data for related tables
				DELETE FROM dbo.rptDepWinlost_Log WITH (ROWLOCK) 
				WHERE Logdate <= @MinSumDate
				
				DELETE FROM dbo.rptDepWinlost_Manual WITH (ROWLOCK) 
				WHERE Winlostdate <= @MinSumDate AND IsSummarized = 1
				
				DELETE FROM dbo.rptDepWinlost_Trans WITH (PAGLOCK)
				WHERE Winlostdate = @MinSumDate
				
				DELETE FROM dbo.rptDepWinlost_Main WITH (PAGLOCK)
				WHERE Winlostdate = @MinSumDate
				
				SELECT @NumberofCus = @@ROWCOUNT
				--Update LogDesc
				SELECT @LogDesc = @LogDesc + CONVERT(VARCHAR(20),@MinSumDate) + ' (No. of Customer affected: ' + CONVERT(VARCHAR(20), @NumberofCus) + 
						CASE WHEN @MinSumDate < @MaxArchiveDate THEN '), ' ELSE ')' END
			END
		--5.Call sp 'Task_DepWinlostSUM' to regen data for 9 days (from the minimum winlostdate of rptDepWinlost)
		EXEC dbo.Task_DepWinlostSUM @date = @MinSumDate 	
		
		SELECT @MinSumDate = DATEADD(DAY,1,@MinSumDate)
	END
	
	--6.Call sp to sum data from the latest day in bettrans14 til today
	EXEC dbo.TASK_HourlySummaryDepData @isDailyArc = 1, @isSuccessful = @isSuccessful OUTPUT
	
	--7.Update SystemSettings
	UPDATE bodb02.dbo.SystemSettings WITH (ROWLOCK, UPDLOCK) 
	SET VValue = '0'
	WHERE VName = 'isArchivingDEPdata'
				
	--8.Update Log
	--SELECT @LogDesc = LEFT(@LogDesc,LEN(@LogDesc)-1)
	SELECT @LogDesc = @LogDesc + '; Type: daily'
	UPDATE dbo.rptDepWinlost_Log WITH (ROWLOCK, UPDLOCK) 
	SET EndTime = CURRENT_TIMESTAMP, LogDesc = @LogDesc, StatusID = @isSuccessful
	WHERE LogID = @LogID
END