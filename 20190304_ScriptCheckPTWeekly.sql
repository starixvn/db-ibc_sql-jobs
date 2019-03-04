/*
	Created: Winnie
	Task: check PT setting weekly
	DB: DBCheck/CheckCustDB
	Date: 20190304
*/ 
USE CheckCustDB
GO

USE CheckResultDB
GO

DECLARE @srecommend INT
CREATE TABLE #supers (custid int,isfinished bit default(0))	
INSERT INTO #supers(custid)
SELECT ci.custid
FROM Deposit_Supers ci

WHILE (1 = 1)
BEGIN
	UPDATE TOP (1) #Supers
	SET isfinished = 1
		,@srecommend = custid			
	WHERE isfinished = 0
	
	IF @@ROWCOUNT = 0 BREAK	
		
	EXEC DBA_CheckPositionTaking_DepCustsetting @srecommend=@srecommend,@RuleID=0	
END

UPDATE #supers
	SET isfinished=0

WHILE (1 = 1)
BEGIN
	UPDATE TOP (1) #Supers
	SET isfinished = 1
		,@srecommend = custid			
	WHERE isfinished = 0
	
	IF @@ROWCOUNT = 0 BREAK	
		
	EXEC DBA_CheckPositionTaking_DepCustSetting3rd @srecommend=@srecommend,@RuleID=0	
END

UPDATE #supers
	SET isfinished=0

WHILE (1 = 1)
BEGIN
	UPDATE TOP (1) #Supers
	SET isfinished = 1
		,@srecommend = custid			
	WHERE isfinished = 0
	
	IF @@ROWCOUNT = 0 BREAK	
		
	EXEC DBA_CheckPositionTaking_DepCustSettingGame @srecommend=@srecommend,@RuleID=0	
END

UPDATE #supers
	SET isfinished=0

WHILE (1 = 1)
BEGIN
	UPDATE TOP (1) #Supers
	SET isfinished = 1
		,@srecommend = custid			
	WHERE isfinished = 0
	
	IF @@ROWCOUNT = 0 BREAK	
		
	EXEC DBA_CheckPositionTaking_Deposit_DCS @srecommend=@srecommend,@RuleID=0	
END

DROP TABLE #supers
