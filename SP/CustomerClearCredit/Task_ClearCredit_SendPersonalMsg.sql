/*<info serverAlias="DBCUST-CustDB" executers="" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[Task_ClearCredit_SendPersonalMsg]	
AS
/*
	Created: 20190509@Elodie
	Task : Send message for SMAs who cleared given credit
	DB: DBCUST/CustDB

	Revisions:    
		- 20190509@Elodie: Initial SP [Redmine:#112458]
		- 20221121@Tacy: adjust [Dot_Msg_xxx] --> [Age_Msg_xxx] [RedmineID: #180704]

	Param's Explanation:
		
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @Content_en NVARCHAR(4000), @Content_vn NVARCHAR(4000), @Content_ch NVARCHAR(4000), @Content_cs NVARCHAR(4000), @Content_th NVARCHAR(4000)
	DECLARE @MessageID INT, @MessageID1 INT, @MessageID2 INT, @Creator INT = 10278938, @CreatorName VARCHAR(50) = 'starixIT', @Max INT, @i INT, @CustID INT, @UserName VARCHAR(30), @UplineRoleId INT
	DECLARE @PostTime DATETIME = GETDATE()
	DECLARE @Today DATETIME = CONVERT(date, GETDATE())
	CREATE TABLE #UplineList (ID INT IDENTITY(1,1), CustId INT, MsgId INT)

	--Send personal message for super
	-- English
	SET @Content_en = 'Dear valued agents, some of your Masters did not login to agency site within 7 days after creation. The system has already removed these unused accounts'' credit. This is to prevent your unused downlines from being taken advantage by third party. Thank you.'	

	-- VietNamese
	SET @Content_vn = N'Kính gửi quý khách hàng, Một số Master của bạn không đăng nhập vào trang Agency trong vòng 7 ngày sau khi tạo. Hệ thống đã thu hồi tín dụng của những tài khoản không sử dụng này. Điều này nhằm ngăn chặn bên thứ ba lợi dụng tuyến dưới không sử dụng của bạn. Trân trọng.'

	-- Chinese Traditional
	SET @Content_ch = N'敬愛的客戶，由於某些總代理在帳號建立後的7天內都不曾登入，系統已清除這些未曾使用帳號的餘額。這是為了防範您下線無使用的空白賬號讓第三方有機可乘。'
	
	-- Chinese Simplified
	SET @Content_cs = N'敬爱的客户，由于某些总代理在账号创建后的7天内都不曾登入，系统已清除这些未曾使用账号的余额。这是为了防范您下线无使用的空白账号让第三方有机可乘。'
	
	-- Thai
	SET @Content_th = N'เรียน ลูกค้าที่เคารพ เนื่องจากบางบัญชีของมาสเตอร์ ที่สร้างขึ้นใหม่และไม่ได้ลงชื่อเข้าใช้เว็ปไซต์ตัวแทนภายใน7วันนับจากวันสร้างบัญชี ระบบจะล้างวงเงินเครดิตทั้งหมดออกจากบัญชี เพื่อความปลอดภัยและป้องกันบัญชีของดาวน์ไลน์ถูกใช้โดยบุคคลที่สาม ขอบพระคุณ'	

	-- Insert message
	EXEC DBMSG.bodb_Message.dbo.Age_Msg_SetMessage2 
		@MessageId	= @MessageID1 OUTPUT,
		@Content_en = @Content_en,
		@Content_ch = @Content_ch,
		@Content_cs = @Content_cs,
		@Content_th = @Content_th,
		@Content_vn = @Content_vn,
		@MsgType	= 1,			 -- message to customer (personal)
		@IsSticky	= 0,			 -- Is special Message or not 
		@Creator	= @Creator,
		@CreatorName = @CreatorName,
		@IsTest		= 0,			 -- Is test or not 
		@IsBatch	= 0			 -- normal message (no need to replace the symbol @@ by transid when display)
		
	-- Insert Message Target	
	INSERT INTO #UplineList( CustId, MsgId)
	SELECT DISTINCT m.srecommend, @MessageID1
	FROM dbo.CustomerClearCredit m
	WHERE m.roleid = 3 AND m.LogDate >= @Today AND m.IsSend = 0

	DELETE t 
	FROM dbo.CustomerClearCredit m WITH (NOLOCK)
		INNER JOIN #UplineList t ON t.CustId = m.srecommend 
	WHERE m.IsSend = 1 AND m.roleid = 3 AND m.LogDate >= @Today

	--Send personal message for master
	-- English
	SET @Content_en = 'Dear valued agents, some of your Agents did not login to agency site within 7 days after creation. System has already removed these unused accounts'' credit. This is to prevent your unused downlines from being taken advantage by third party. Thank you.'	

	-- VietNamese
	SET @Content_vn = N'Kính gửi quý khách hàng, Một số Agent của bạn không đăng nhập vào trang Agency trong vòng 7 ngày sau khi tạo. Hệ thống đã thu hồi tín dụng của những tài khoản không sử dụng này. Điều này nhằm ngăn chặn bên thứ ba lợi dụng tuyến dưới không sử dụng của bạn. Trân trọng.'	

	-- Chinese Traditional
	SET @Content_ch = N'敬愛的客戶，由於某些代理在帳號建立後的7天內都不曾登入，系統已清除這些未曾使用帳號的餘額。這是為了防範您下線無使用的空白賬號讓第三方有機可乘。'	
	
	-- Chinese Simplified
	SET @Content_cs = N'敬爱的客户，由于某些代理在账号创建后的7天内都不曾登入，系统已清除这些未曾使用账号的余额。这是为了防范您下线无使用的空白账号让第三方有机可乘。'	
	
	-- Thai
	SET @Content_th = N'เรียน ลูกค้าที่เคารพ เนื่องจากบางบัญชีของเอเย่นต์ ที่สร้างขึ้นใหม่และไม่ได้ลงชื่อเข้าใช้เว็ปไซต์ตัวแทนภายใน7วันนับจากวันสร้างบัญชี ระบบจะล้างวงเงินเครดิตทั้งหมดออกจากบัญชี เพื่อความปลอดภัยและป้องกันบัญชีของดาวน์ไลน์ถูกใช้โดยบุคคลที่สาม ขอบพระคุณ'

	-- Insert message
	EXEC DBMSG.bodb_Message.dbo.Age_Msg_SetMessage2 
		@MessageId	= @MessageID2 OUTPUT,
		@Content_en = @Content_en,
		@Content_ch = @Content_ch,
		@Content_cs = @Content_cs,
		@Content_th = @Content_th,
		@Content_vn = @Content_vn,
		@MsgType	= 1,			 -- message to customer (personal)
		@IsSticky	= 0,			 -- Is special Message or not 
		@Creator	= @Creator,
		@CreatorName = @CreatorName,
		@IsTest		= 0,			 -- Is test or not 
		@IsBatch	= 0			 -- normal message (no need to replace the symbol @@ by transid when display)
			
	-- Insert Message Target	
	INSERT INTO #UplineList (CustId, MsgId)	
	SELECT DISTINCT a.mrecommend, @MessageID2
	FROM dbo.CustomerClearCredit a
	WHERE a.roleid = 2 AND a.LogDate >= @Today AND a.IsSend = 0

	DELETE t 
	FROM dbo.CustomerClearCredit a WITH (NOLOCK)
		INNER JOIN #UplineList t ON t.CustId = a.mrecommend 
	WHERE a.IsSend = 1 AND a.roleid = 2 AND a.LogDate >= @Today

	--Send message for user
	SET @i = 1
	SELECT @Max = COUNT(ID) FROM #UplineList

	WHILE @i <= @Max
	BEGIN
		SELECT @CustID = t.custid, @UserName = c.username, @UplineRoleId = c.roleid, @MessageId = MsgId 
		FROM #UplineList t
			INNER JOIN dbo.Customer c WITH (NOLOCK) ON t.CustId = c.custid
		WHERE ID = @i

		EXEC DBMSG.bodb_Message.dbo.Age_Msg_SetUsrMessage
		@MessageId	= @MessageId,
		@TargetId	= @CustID,
		@TargetName = @UserName,
		@PostTime	= @PostTime,
		@isRead		= 0		
		
		UPDATE c 
		SET IsSend = 1
		FROM dbo.CustomerClearCredit c WITH (ROWLOCK) 
		WHERE c.LogDate >= @Today AND @CustID = CASE WHEN @UplineRoleId = 4 THEN c.srecommend WHEN @UplineRoleId = 3 THEN c.mrecommend END

		SELECT @i = @i + 1
	END

END
