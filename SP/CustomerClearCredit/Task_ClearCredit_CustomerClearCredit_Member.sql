/*<info serverAlias="DBCUST-CUSTDB" executers="" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[Task_ClearCredit_CustomerClearCredit_Member]	
AS
/*
	Created: 20190514@Elodie
	Task : Clear given credit for new created member
	DB: DBCust/CustDB

	Revisions:    
		- 20190514@Elodie: Initial SP [Redmine:#112458]

	Param's Explanation:
		
*/
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #CustomerList (custid INT PRIMARY KEY, roleid TINYINT, username VARCHAR(30), credit MONEY, srecommend INT, mrecommend INT, recommend INT)
	DECLARE @CustIdList XML, @CustIdStr VARCHAR(MAX)
	DECLARE @Today DATETIME = CONVERT(date, GETDATE())

	------------------------------STEP 1: Get Customer list--------------------------------------------------------------
	--Get customer list
	INSERT INTO #CustomerList (custid, roleid, username, credit, srecommend, mrecommend, recommend)
	SELECT c.custid, ci.roleid, c.username, ci.credit, c.srecommend, c.mrecommend, c.recommend
	FROM Customer c WITH (NOLOCK) 
		INNER JOIN dbo.custInfo ci WITH (NOLOCK) ON ci.CustID = c.custid
		INNER JOIN dbo.Customer a WITH (NOLOCK) ON ci.recommend = a.custid
	WHERE NOT EXISTS (SELECT 1 FROM dbo.Dep_CustSuper s WITH (NOLOCK) WHERE s.custid = c.srecommend)
		AND c.currency <> 20
		AND a.site <> 'CN88'
		AND c.creator = c.recommend
		AND c.roleid = 1
		AND ci.credit > 0
		AND c.creatdate < DATEADD(dd,-7, @Today) 
		AND c.lastlogged IS NULL

	--exclude direct accounts
	DELETE m 
	FROM #CustomerList m 
		INNER JOIN dbo.CustDirectAccount da WITH (NOLOCK) ON da.CustID = m.custid	

	DELETE a 
	FROM #CustomerList a 
		INNER JOIN dbo.CustDirectAccount da WITH (NOLOCK) ON da.CustID = a.mrecommend

	DELETE a 
	FROM #CustomerList a 
		INNER JOIN dbo.CustDirectAccount da WITH (NOLOCK) ON da.CustID = a.recommend

	--exclude exception list used by OPS/Finance (bodb_report.dbo.Task_Cust_ArchiveAcc_Exception)
	DELETE m 
	FROM #CustomerList m 
		INNER JOIN DBACC.bodb_report.dbo.Task_Cust_ArchiveAcc_Exception e WITH (NOLOCK) ON e.CustID = m.custid	

	--exclude internal accounts	
	DELETE m 
	FROM #CustomerList m 
		INNER JOIN dbo.CustSuper cs WITH (NOLOCK) ON cs.custid = m.srecommend
	WHERE cs.IsInternal = 1		

	DELETE a 
	FROM #CustomerList a 
		INNER JOIN dbo.CustMaster cm WITH (NOLOCK) ON cm.custid = a.mrecommend
	WHERE cm.IsInternal = 1

	DELETE m 
	FROM #CustomerList m 
		INNER JOIN dbo.CustAgent ca WITH (NOLOCK) ON ca.custid = m.recommend
	WHERE ca.IsInternal = 1

	------------------------------STEP 2: Clear credit and write log--------------------------------------------------------------
	DECLARE @tmpCust TABLE (custid INT PRIMARY KEY, Credit MONEY, srecommend INT, mrecommend INT, recommend INT)
	DECLARE @Log XML = '', @SB_Error BIT = 0, @LogData VARCHAR(1000), @ActionId INT = 1221
	DECLARE @UserId INT = 10278938, @ITName VARCHAR(50) = 'starixIT'

	SELECT @LogData = 'Remove the unused account''s credit by IT Admin'

	--Clear credit for master
	WHILE(1=1)
	BEGIN
		DELETE TOP (3000) t
		OUTPUT DELETED.custid, DELETED.credit, DELETED.srecommend, DELETED.mrecommend, DELETED.recommend
		INTO @tmpCust 
		FROM #CustomerList t
		
		IF @@rowcount = 0 
			BREAK;
			
		SELECT @CustIdList = (SELECT (
									SELECT  t.custid	AS '@ID'
									FROM @tmpCust t
									FOR XML PATH('C'), 
									TYPE
								)
						FOR XML PATH('R'), 
						TYPE)
	
		SELECT @CustIdStr = CONVERT(VARCHAR(MAX), @CustIdList)

		EXEC Acc_CustomerInfo_Execrep_11 @CustList = @CustIdStr	
		
		SELECT @log = (
							SELECT @UserID as UserID, t.CustID, t.credit as OldValue, 0 as NewValue, '' as IP, @LogData as Doing, @ActionId as ActionID, GETDATE() as LogDate
							FROM @tmpCust t
							FOR XML RAW('Row')
						)

		EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @log, 
														@MessageType='MessageType_CustomerLog_UserLog_Credit', 
														@functionName = 'UserLog_Others',
														@SB_Error = @SB_Error out

		--if ssb error
		IF @SB_Error = 1
		BEGIN
			-- Write log
			BEGIN TRY
				INSERT INTO DBLOG.bodb_CustomerLog.dbo.Userlog_Credit (userid, custid, OldValue, NewValue, ip, doing, ActionID)
				SELECT	@UserID, custid, credit, 0, '', @LogData, @ActionId 
				FROM	@tmpCust 
			END TRY
			BEGIN CATCH
				SELECT @LogData = @LogData + ' ErrMsg=' + ERROR_MESSAGE()
		
				INSERT INTO bodb_CustomerLog.dbo.userlog_Credit(userid, custid, OldValue, NewValue, ip, doing, ActionID)
				SELECT	@UserID, custid, credit, 0, '', @LogData, @ActionId 
				FROM	@tmpCust 
			END CATCH						
		END			
		
		INSERT INTO dbo.CustomerClearCredit (LogDate, custid, roleid, srecommend, mrecommend, recommend, Oldcredit)
		SELECT GETDATE(), custid, 1, srecommend, mrecommend, recommend, credit
		FROM @tmpCust

		DELETE @tmpCust

		WAITFOR DELAY '00:00:05'

	END
END
