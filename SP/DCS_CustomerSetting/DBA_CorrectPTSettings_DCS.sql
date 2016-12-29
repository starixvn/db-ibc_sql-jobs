--Agent S56EH7750
UPDATE cs
SET apositiontaking = 0.2
FROM custSetting cs WITH (UPDLOCK,ROWLOCK)
	INNER JOIN custInfo ci WITH(NOLOCK) ON cs.custid = ci.custid
WHERE ci.recommend = 6387504
	AND cs.sporttype = 1
	AND cs.bettype = 9999
GO
--correct downlines
EXEC dbo.Acc_CustSetting_07 @srecommend = 877768, @mrecommend = 921636, @roleid = 3
GO

--master S32EH6899
UPDATE custSetting WITH(UPDLOCK,ROWLOCK)
SET mpositiontaking =  0.7
WHERE custid = 3955349
	AND sporttype = 1 
	AND bettype = 9999
GO

--member B6TAKT5777,B6TAKT5888 
UPDATE custSetting WITH(UPDLOCK,ROWLOCK)
SET spositiontaking = 0.5, mpositiontaking =  0
WHERE custid IN (12300829,12300833)
	AND sporttype = 1 
	AND bettype = 9999
GO

--master IDOOOO 
UPDATE custSetting WITH(UPDLOCK,ROWLOCK)
SET mpositiontaking =  0.75
WHERE custid IN (15524153)
	AND sporttype = 1 
	AND bettype = 9999
GO

--member IDOOOOAK2,IDOOOOGL1, IDOOOOAK1,IDOOOO123, IDOOOOCEN
UPDATE custSetting WITH(UPDLOCK,ROWLOCK)
SET mpositiontaking =  0.05, spositiontaking = 0.05
WHERE custid IN (15524556,15524567,15524548,15624195,15691144)
	AND sporttype = 1 
	AND bettype = 9999
GO

--agent UM8837
UPDATE custSetting WITH(UPDLOCK,ROWLOCK)
SET apositiontaking =  0.5
WHERE custid IN (8198209)
	AND sporttype = 1 
	AND bettype = 9999
GO

--agent 2AH8D00
UPDATE custSetting WITH(UPDLOCK,ROWLOCK)
SET apositiontaking =  0.3
WHERE custid IN (10395117)
	AND sporttype = 1 
	AND bettype = 9999
GO

--master B38T66
UPDATE custSetting WITH(UPDLOCK,ROWLOCK)
SET mpositiontaking =  0.75, autopositiontaking = 0.8, isautopositiontaking = 1
WHERE custid IN (12245095)
	AND sporttype = 1 
	AND bettype = 9999
GO
