/*<info serverAlias="DBCUST-CUSTDB" executers="" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[Task_ClearCredit_CustomerClearCredit]	
AS
/*
	Created: 20190509@Elodie
	Task : Clear given credit for new created SMAs
	DB: DBCust/CustDB

	Revisions:    
		- 20190509@Elodie: Initial SP [Redmine:#112458]

	Param's Explanation:
		
*/
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #CustomerList (custid INT PRIMARY KEY, roleid TINYINT, username VARCHAR(30), credit MONEY, srecommend INT, mrecommend INT)
	CREATE TABLE #MasterList (custid INT PRIMARY KEY, username VARCHAR(30), credit MONEY, srecommend INT, mrecommend INT)
	CREATE TABLE #AgentList (custid INT PRIMARY KEY, username VARCHAR(30), credit MONEY, srecommend INT, mrecommend INT)
	DECLARE @Today DATETIME = CONVERT(date, GETDATE())

	------------------------------STEP 1: Get Customer list--------------------------------------------------------------
	--Get customer list
	INSERT INTO #CustomerList (custid, roleid, username, credit, srecommend, mrecommend)
	SELECT c.custid, ci.roleid, c.username, ci.credit, c.srecommend, c.mrecommend
	FROM vw_Customer c WITH (NOLOCK) 
		INNER JOIN dbo.custInfo ci WITH (NOLOCK) ON ci.CustID = c.custid
		INNER JOIN dbo.CustLoginInfo li WITH (NOLOCK) ON c.CustID = li.custid
	WHERE NOT EXISTS (SELECT 1 FROM dbo.Dep_CustSuper s WITH (NOLOCK) WHERE s.custid = c.srecommend)
		AND c.currency <> 20
		AND c.site <> 'CN88'
		AND c.creator = CASE WHEN c.roleid = 3 THEN c.srecommend ELSE c.mrecommend END
		AND c.roleid IN (2, 3)
		AND ci.credit > 0
		AND c.creatdate < DATEADD(dd,-7, @Today) 
		AND li.isFirstLogin = 1

	--Get masters don't have downlines
	INSERT INTO #MasterList (custid)
	SELECT c.mrecommend 
	FROM dbo.Custinfo c WITH (NOLOCK) 
		INNER JOIn #CustomerList m WITH (NOLOCK) ON c.mrecommend = m.custid
	WHERE c.roleid IN (2,3) AND m.roleid = 3
	GROUP BY c.mrecommend 
	HAVING COUNT(1) = 1

	--Get agents don't have downlines
	INSERT INTO #AgentList (custid)
	SELECT c.recommend 
	FROM dbo.Custinfo c WITH (NOLOCK) 
		INNER JOIn #CustomerList m WITH (NOLOCK) ON c.recommend = m.custid
	WHERE c.roleid IN (1,2) AND m.roleid = 2
	GROUP BY c.recommend 
	HAVING COUNT(1) = 1

	----------------
	UPDATE m 
	SET m.username = c.username,
		m.credit = c.credit,
		m.srecommend = c.srecommend,
		m.mrecommend = c.mrecommend
	FROM #MasterList m 
		INNER JOIN #CustomerList c ON c.custid = m.custid

	UPDATE a 
	SET a.username = c.username,
		a.credit = c.credit,
		a.srecommend = c.srecommend,
		a.mrecommend = c.mrecommend
	FROM #AgentList a 
		INNER JOIN #CustomerList c ON c.custid = a.custid

	--exclude direct accounts
	DELETE m 
	FROM #MasterList m 
		INNER JOIN dbo.CustDirectAccount da WITH (NOLOCK) ON da.CustID = m.custid

	DELETE a 
	FROM #AgentList a 
		INNER JOIN dbo.CustDirectAccount da WITH (NOLOCK) ON da.CustID = a.custid

	DELETE a 
	FROM #AgentList a 
		INNER JOIN dbo.CustDirectAccount da WITH (NOLOCK) ON da.CustID = a.mrecommend

	--exclude exception list used by OPS/Finance (bodb_report.dbo.Task_Cust_ArchiveAcc_Exception)
	DELETE m 
	FROM #MasterList m 
		INNER JOIN DBACC.bodb_report.dbo.Task_Cust_ArchiveAcc_Exception e WITH (NOLOCK) ON e.CustID = m.custid

	DELETE a 
	FROM #AgentList a 
		INNER JOIN DBACC.bodb_report.dbo.Task_Cust_ArchiveAcc_Exception e WITH (NOLOCK) ON e.CustID = a.custid

	--exclude internal accounts
	DELETE m 
	FROM #MasterList m 
		INNER JOIN dbo.CustMaster cm WITH (NOLOCK) ON cm.custid = m.custid
	WHERE cm.IsInternal = 1

	DELETE m 
	FROM #MasterList m 
		INNER JOIN dbo.CustSuper cs WITH (NOLOCK) ON cs.custid = m.srecommend
	WHERE cs.IsInternal = 1

	DELETE a 
	FROM #AgentList a
		INNER JOIN dbo.CustAgent ca WITH (NOLOCK) ON ca.custid = a.custid
	WHERE ca.IsInternal = 1

	DELETE a 
	FROM #AgentList a 
		INNER JOIN dbo.CustSuper cs WITH (NOLOCK) ON cs.custid = a.srecommend
	WHERE cs.IsInternal = 1

	DELETE a 
	FROM #AgentList a 
		INNER JOIN dbo.CustMaster cm WITH (NOLOCK) ON cm.custid = a.mrecommend
	WHERE cm.IsInternal = 1

	------------------------------STEP 2: Clear credit and write log--------------------------------------------------------------
	DECLARE @tmpCust TABLE (custid INT PRIMARY KEY, Credit MONEY, srecommend INT, mrecommend INT)
	DECLARE @Log XML = '', @SB_Error BIT = 0, @LogData VARCHAR(1000), @ActionId INT = 1221
	DECLARE @UserId INT = 10278938, @ITName VARCHAR(50) = 'starixIT'

	SELECT @LogData = 'Removed the unused account''s given credit by System'

	--Clear credit for master
	WHILE(1=1)
	BEGIN
		DELETE TOP (3000) t
		OUTPUT DELETED.custid, DELETED.credit, DELETED.srecommend, DELETED.mrecommend
		INTO @tmpCust 
		FROM #MasterList t
		
		IF @@rowcount = 0 
			BREAK;
			
		UPDATE	ci 
		SET	ci.credit = 0
		FROM dbo.custInfo AS ci WITH(ROWLOCK,UPDLOCK)
			INNER JOIN @tmpCust c ON c.custid = ci.custid		
		
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
		SELECT GETDATE(), custid, 3, srecommend, mrecommend, 0, credit
		FROM @tmpCust

		DELETE @tmpCust

		WAITFOR DELAY '00:00:05'

	END

	--Clear credit for agent
	WHILE(1=1)
	BEGIN
		DELETE TOP (3000) t
		OUTPUT DELETED.custid, DELETED.credit, DELETED.srecommend, DELETED.mrecommend
		INTO @tmpCust 
		FROM #AgentList t
		
		IF @@rowcount = 0 
			BREAK;
			
		UPDATE	ci 
		SET	ci.credit = 0
		FROM dbo.custInfo AS ci WITH(ROWLOCK,UPDLOCK)
			INNER JOIN @tmpCust c ON c.custid = ci.custid		
		
		SELECT @log = (
							SELECT @UserID as UserID, t.CustID, t.credit as OldValue, 0 as NewValue, '' as IP, @LogData as Doing, @ActionId as ActionID, getdate() as LogDate
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
		SELECT GETDATE(), custid, 2, srecommend, mrecommend, custid, credit
		FROM @tmpCust

		DELETE @tmpCust

		WAITFOR DELAY '00:00:05'

	END
END
