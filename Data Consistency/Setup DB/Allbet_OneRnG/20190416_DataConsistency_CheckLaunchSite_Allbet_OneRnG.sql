/*
	Created: Helen
	Task: insert task for AllBet & OneRnG Bettype
	DB: DBTP/bodb_Consistency
	Date: 20190416
*/
USE [bodb_Consistency]
GO

------------------------------------------------------------------------------------------------------------------------------------------------------------
SET IDENTITY_INSERT DBA_Tasks ON

INSERT INTO DBA_Tasks (TaskId, RuleId, Command)
VALUES

	 (39,17,'EXEC DBA_Consistency_LaunchedSiteChecking @ProductId=211,@bettype = 2406, @sites=''Indo,KORIBC'', @IsLaunched = 1, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')
	,(40,17,'EXEC DBA_Consistency_LaunchedSiteChecking @ProductId=211,@bettype = 2406, @sites=''Indo,KORIBC,12Bet'',@IsLicenseeOffer = 0, @IsLaunched = 1, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')
	
	,(41,17,'EXEC DBA_Consistency_LaunchedSiteChecking @ProductId=209,@bettype = 2207, @sites=''Indo,KORIBC'',@IsLaunched = 1, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')
	
SET IDENTITY_INSERT DBA_Tasks OFF