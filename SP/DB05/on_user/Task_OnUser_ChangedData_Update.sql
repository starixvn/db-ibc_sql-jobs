/*<info serverAlias="DBONUSER-on_user" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Task_OnUser_ChangedData_Update]
AS
/*
	created: 20191126@Lukas
	Task: manually sync data of on_user tables in AA mode project
	DB: DBONUSER.on_user

	Revisions:
*/
BEGIN
	SET NOCOUNT ON 
	DECLARE @lastTstamp TIMESTAMP,
			@maxTstamp TIMESTAMP
			
	---sync data on MESSAGE_NOTICE table
	SELECT @lastTstamp = 0X00, @maxTstamp = 0X00
	SELECT @lastTstamp = CAST(VValue AS TIMESTAMP)
	FROM SystemSettings WITH(NOLOCK)
	WHERE VID = 1 AND VName = 'MESSAGE_NOTICE'
	
	DECLARE @MESSAGE_NOTICE TABLE(custId INT, userID INT, msgID	TINYINT,modifiedDate DATETIME,modifiedValue	SMALLMONEY,isViewed	BIT,TypeID TINYINT)
	INSERT INTO @MESSAGE_NOTICE(custID, userID, TypeID, msgID, modifiedDate, modifiedValue, isViewed)
	EXEC DB05.on_user.dbo.Task_OnUser_ChangedData_Pull @targetTable = 'MESSAGE_NOTICE', @lastTstamp = @lastTstamp,@maxTSTAMP = @maxTSTAMP OUTPUT
	
	MERGE MESSAGE_NOTICE AS tg
	USING @MESSAGE_NOTICE AS sr
	ON tg.custID = sr.CustID AND tg.userID = sr.userID AND tg.TypeID = sr.TypeID
	WHEN MATCHED 
		THEN UPDATE SET tg.msgID = sr.msgID, tg.modifiedDate = sr.modifiedDate, tg.modifiedValue = sr.modifiedValue, tg.isViewed = sr.isViewed
	WHEN NOT MATCHED BY TARGET 
		THEN INSERT (custID, userID, TypeID, msgID, modifiedDate, modifiedValue, isViewed) 
				VALUES(sr.custID, sr.userID, sr.TypeID, sr.msgID, sr.modifiedDate, sr.modifiedValue, sr.isViewed);		
	UPDATE SystemSettings SET VValue = CAST(@maxTstamp AS BINARY(8)) WHERE VID = 1 AND VName = 'MESSAGE_NOTICE'
	
	---sync data on msg table
	SELECT @lastTstamp = 0X00, @maxTstamp = 0X00
	SELECT @lastTstamp = CAST(VValue AS TIMESTAMP)
	FROM SystemSettings WITH(NOLOCK)
	WHERE VID = 2 AND VName = 'msg'
	
	DECLARE @msg TABLE(MessageId INT, TargetId INT, MessageType	TINYINT)
	INSERT INTO @msg(MessageId, TargetId, MessageType)
	EXEC DB05.on_user.dbo.Task_OnUser_ChangedData_Pull @targetTable = 'msg', @lastTstamp = @lastTstamp,@maxTSTAMP = @maxTSTAMP OUTPUT
	
	MERGE msg AS tg
	USING @msg AS sr
	ON tg.MessageId = sr.MessageId AND tg.TargetId = sr.TargetId 
	WHEN MATCHED 
		THEN UPDATE SET tg.MessageType = sr.MessageType 
	WHEN NOT MATCHED BY TARGET 
		THEN INSERT  (MessageId, TargetId, MessageType)
				VALUES(sr.MessageId, sr.TargetId, sr.MessageType);		
	UPDATE SystemSettings SET VValue = CAST(@maxTstamp AS BINARY(8)) WHERE VID = 2 AND VName = 'msg'
	
	---sync data on RobotUsers table
	SELECT @lastTstamp = 0X00, @maxTstamp = 0X00
	SELECT @lastTstamp = CAST(VValue AS TIMESTAMP)
	FROM SystemSettings WITH(NOLOCK)
	WHERE VID = 3 AND VName = 'RobotUsers'
	
	DECLARE @RobotUsers TABLE (custid int,IP varchar(15),LastChangeTime smalldatetime,site varchar(15),counter int,
		serverip varchar(50),RobotDate smalldatetime,remark nvarchar(500),Creator int)
	INSERT INTO @RobotUsers(custid, IP, LastChangeTime, site, counter, serverip, RobotDate, remark, Creator)
	EXEC DB05.on_user.dbo.Task_OnUser_ChangedData_Pull @targetTable = 'RobotUsers', @lastTstamp = @lastTstamp,@maxTSTAMP = @maxTSTAMP OUTPUT
	
	MERGE RobotUsers AS tg
	USING @RobotUsers AS sr
	ON tg.custid = sr.custid 
	WHEN MATCHED 
		THEN UPDATE SET tg.IP = sr.IP, tg.LastChangeTime = sr.LastChangeTime,tg.site = sr.site,tg.counter = sr.counter,
			tg.serverip = sr.serverip,tg.RobotDate = sr.RobotDate,tg.remark = sr.remark,tg.Creator = sr.Creator
	WHEN NOT MATCHED BY TARGET 
		THEN INSERT  (custid, IP, LastChangeTime, site, counter, serverip, RobotDate, remark, Creator)
				VALUES(sr.custid, sr.IP, sr.LastChangeTime, sr.site, sr.counter, sr.serverip, sr.RobotDate, sr.remark, sr.Creator);		
	UPDATE SystemSettings SET VValue = CAST(@maxTstamp AS BINARY(8)) WHERE VID = 3 AND VName = 'RobotUsers'
	
	---sync data on RobotUsers_DelLog table
	SELECT @lastTstamp = 0X00, @maxTstamp = 0X00
	SELECT @lastTstamp = CAST(VValue AS TIMESTAMP)
	FROM SystemSettings WITH(NOLOCK)
	WHERE VID = 4 AND VName = 'RobotUsers_DelLog'
	
	DECLARE @RobotUsers_DelLog TABLE(DelLogDate DATETIME, custid INT, IP VARCHAR(15), LastChangeTime SMALLDATETIME, site VARCHAR(15), 
		counter INT, serverip VARCHAR(50), RobotDate SMALLDATETIME, remark NVARCHAR(500), Creator INT)
	INSERT INTO @RobotUsers_DelLog(DelLogDate, custid, IP, LastChangeTime, site, counter, serverip, RobotDate, remark, Creator)
	EXEC DB05.on_user.dbo.Task_OnUser_ChangedData_Pull @targetTable = 'RobotUsers_DelLog', @lastTstamp = @lastTstamp,@maxTSTAMP = @maxTSTAMP OUTPUT
	-- try to delete custid that removed out of RobotUsers 
	DELETE FROM RobotUsers 
	WHERE custid IN (SELECT t.custid 
					FROM @RobotUsers_DelLog t 
						LEFT JOIN RobotUsers_DelLog ru ON t.DelLogDate = ru.DelLogDate AND t.custid = ru.custid
					WHERE ru.custid IS NULL)
											
	MERGE RobotUsers_DelLog AS tg
	USING @RobotUsers_DelLog AS sr
	ON tg.DelLogDate = sr.DelLogDate AND tg.custid = sr.custid 
	WHEN MATCHED 
		THEN UPDATE SET tg.IP = sr.IP,tg.LastChangeTime = sr.LastChangeTime,tg.site = sr.site,tg.counter = sr.counter,
			tg.serverip = sr.serverip,tg.RobotDate = sr.RobotDate,tg.remark = sr.remark,tg.Creator = sr.Creator 
	WHEN NOT MATCHED BY TARGET 
		THEN INSERT  (DelLogDate, custid, IP, LastChangeTime, site, counter, serverip, RobotDate, remark, Creator)
				VALUES(sr.DelLogDate, sr.custid, sr.IP, sr.LastChangeTime, sr.site, sr.counter, sr.serverip, sr.RobotDate, sr.remark, sr.Creator);		
	UPDATE SystemSettings SET VValue = CAST(@maxTstamp AS BINARY(8)) WHERE VID = 4 AND VName = 'RobotUsers_DelLog'
	
 
END
