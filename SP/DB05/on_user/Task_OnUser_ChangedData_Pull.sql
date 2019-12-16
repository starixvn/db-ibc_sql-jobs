/*<info serverAlias="DBONUSER-on_user" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Task_OnUser_ChangedData_Pull]
(
	@targetTable VARCHAR(100) = '',
	@lastTstamp TIMESTAMP = 0x0000000000000000,
	@maxTstamp TIMESTAMP OUTPUT
)
AS
/*
	created: 20191126@Lukas
	Task: manually sync data of on_user tables in AA mode project
	DB: DBONUSER.on_user

	Revisions:
*/
BEGIN
	
	SET NOCOUNT ON 
	
	SET @maxTstamp = 0x0000000000000000
	
	IF @targetTable = 'MESSAGE_NOTICE'
	BEGIN
		
		SELECT @maxTstamp = MAX(tstamp) FROM MESSAGE_NOTICE WITH(NOLOCK)
		
		IF @lastTstamp IS NULL OR @lastTstamp = 0x0000000000000000
			SET @lastTstamp = @maxTstamp
			
		SELECT  custID, userID, TypeID, msgID, modifiedDate, modifiedValue, isViewed
		FROM MESSAGE_NOTICE WITH(NOLOCK)
		WHERE tstamp > @lastTstamp AND tstamp <= @maxTstamp 
		
	END
	ELSE IF @targetTable = 'msg'
	BEGIN
		
		SELECT @maxTstamp = MAX(tstamp) FROM msg WITH(NOLOCK)
		IF @lastTstamp IS NULL OR @lastTstamp = 0x0000000000000000
			SET @lastTstamp = @maxTstamp
			
		SELECT  MessageId, TargetId, MessageType
		FROM msg WITH(NOLOCK)
		WHERE tstamp > @lastTstamp AND tstamp <= @maxTstamp
		
	END
	ELSE IF @targetTable = 'RobotUsers'
	BEGIN
		
		SELECT @maxTstamp = MAX(tstamp) FROM RobotUsers WITH(NOLOCK)
		IF @lastTstamp IS NULL OR @lastTstamp = 0x0000000000000000
			SET @lastTstamp = @maxTstamp
			
		SELECT  custid, IP, LastChangeTime, site, counter, serverip, RobotDate, remark, Creator 
		FROM RobotUsers WITH(NOLOCK)
		WHERE tstamp > @lastTstamp AND tstamp <= @maxTstamp
		
		
	END
	ELSE IF @targetTable = 'RobotUsers_DelLog'
	BEGIN
		
		SELECT @maxTstamp = MAX(tstamp) FROM RobotUsers_DelLog WITH(NOLOCK)
		IF @lastTstamp IS NULL OR @lastTstamp = 0x0000000000000000
			SET @lastTstamp = @maxTstamp
			
		SELECT DelLogDate, custid, IP, LastChangeTime, site, counter, serverip, RobotDate, remark, Creator
		FROM RobotUsers_DelLog WITH(NOLOCK)
		WHERE tstamp > @lastTstamp AND tstamp <= @maxTstamp
		
		
	END
	ELSE 
	BEGIN
		RAISERROR('not defined yet.',16,1)
	END
	--SELECT @lastTstamp ,
	--		@maxTstamp
END
