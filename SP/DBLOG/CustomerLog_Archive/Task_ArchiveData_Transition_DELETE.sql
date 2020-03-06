ALTER TRIGGER [dbo].[Task_ArchiveData_Transition_DELETE]
   ON  [dbo].[Task_ArchiveData_Transition]
   AFTER DELETE
AS 
/*
	Created: 20190227@Patrick
	Task : Implement archiving data for customer log
	DB: DBLog.bodb_CustomerLog

	Revisions: 
		- 20190227@Patrick: Initalize [RedmineId: #110208] 	
		- 20190620@Elodie: Apply new structure for CN88's log [Redmine: #113198]
		- 20200107@Elodie: Add CreateDate column for CN88's log [Redmine: #113198]
		- 20200303@Elodie: Apply new structure for MBC's log [Redmine: #127446]
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @tableName VARCHAR(200), @custid int
	SELECT TOP (1) @tableName = TableName, @custid = custid
	FROM deleted

	IF @tableName = 'UserLog_RunSP'
	BEGIN
		IF @custid IS NULL
		BEGIN
			INSERT INTO bodb_CustomerLog_Archive.dbo.UserLog_RunSP([logid], [userid], [spname], [doing]
				, [logdate], [custid], [ActionID], [TrackingValue], [Duration], [TrackingValue2])
			SELECT [logid], [userid], [spname], [doing], [logdate], [custid], [ActionID], [TrackingValue]
				, [Duration], [TrackingValue2]
			FROM dbo.UserLog_RunSP l WITH(NOLOCK)
			WHERE EXISTS (SELECT TOP 1 1 FROM deleted WHERE deleted.LogId = l.logid AND deleted.LogDate = l.logdate AND l.custid IS NULL)
		END
		ELSE
		BEGIN
			INSERT INTO bodb_CustomerLog_Archive.dbo.UserLog_RunSP([logid], [userid], [spname], [doing]
				, [logdate], [custid], [ActionID], [TrackingValue], [Duration], [TrackingValue2])
			SELECT [logid], [userid], [spname], [doing], [logdate], [custid], [ActionID], [TrackingValue]
				, [Duration], [TrackingValue2]
			FROM dbo.UserLog_RunSP l WITH(NOLOCK)
			WHERE EXISTS (SELECT TOP 1 1 FROM deleted WHERE deleted.LogId = l.logid AND deleted.LogDate = l.logdate AND l.custid = deleted.custid)
		END
	END
	ELSE IF @tableName = 'UserLog_Login'
	BEGIN
		INSERT INTO bodb_CustomerLog_Archive.dbo.UserLog_Login([LogID], [UserID], [RoleID], [SubAccID], [ServerID], [IP], [LogDate], [ActionID], [Doing], [DomainName], [BrowserName], [Platform], [CountryCode], [Duration], [username2], [CreatedDate])
		SELECT [LogID], [UserID], [RoleID], [SubAccID], [ServerID], [IP], [LogDate], [ActionID], [Doing], [DomainName], [BrowserName], [Platform], [CountryCode], [Duration], [username2], [CreatedDate]
		FROM dbo.UserLog_Login l WITH(NOLOCK)
		WHERE EXISTS (SELECT TOP 1 1 FROM deleted WHERE deleted.LogId = l.logid AND deleted.LogDate = l.logdate AND l.userid = deleted.custid)
	END	
	ELSE IF @tableName = 'UserLog_Settle'
	BEGIN
		INSERT INTO bodb_CustomerLog_Archive.dbo.UserLog_Settle([LogID], [LogDate], [UserID], [MatchID], [ActionID], [finalhomescore], [finalawayscore], [hthomescore], [htawayscore], [GoalRecord], [betstatus], [Remark], [IP])
		SELECT [LogID], [LogDate], [UserID], [MatchID], [ActionID], [finalhomescore], [finalawayscore], [hthomescore], [htawayscore], [GoalRecord], [betstatus], [Remark], [IP]
		FROM dbo.UserLog_Settle l WITH(NOLOCK)
		WHERE EXISTS (SELECT TOP 1 1 FROM deleted WHERE deleted.LogId = l.logid AND deleted.LogDate = l.logdate)
	END	
	ELSE IF @tableName = 'UserLog_Transaction'
	BEGIN
		INSERT INTO bodb_CustomerLog_Archive.dbo.UserLog_Transaction([LogID], [LogDate], [ActionID], [Refno], [UserID], [IP], [Doing])
		SELECT [LogID], [LogDate], [ActionID], [Refno], [UserID], [IP], [Doing]
		FROM dbo.UserLog_Transaction l WITH(NOLOCK)
		WHERE EXISTS (SELECT TOP 1 1 FROM deleted WHERE deleted.LogId = l.logid AND deleted.LogDate = l.logdate)
	END	
	ELSE IF @tableName = 'UserLog_Transfer'
	BEGIN
		INSERT INTO bodb_CustomerLog_Archive.dbo.UserLog_Transfer([LogID], [LogDate], [UserID], [FromCustID], [ToCustID], [IP], [Doing])
		SELECT [LogID], [LogDate], [UserID], [FromCustID], [ToCustID], [IP], [Doing]
		FROM dbo.UserLog_Transfer l WITH(NOLOCK)
		WHERE EXISTS (SELECT TOP 1 1 FROM deleted WHERE deleted.LogId = l.logid AND deleted.LogDate = l.logdate)
	END	
	ELSE IF @tableName = 'UserLog_CasinoAPI'
	BEGIN
		INSERT INTO bodb_CustomerLog_Archive.dbo.UserLog_CasinoAPI([LogID], [SystemID], [UserID], [FuncName], [LogDate], [CustID], [ActionID], [ReturnValue], [ReturnCode], [TrackingValue])
		SELECT [LogID], [SystemID], [UserID], [FuncName], [LogDate], [CustID], [ActionID], [ReturnValue], [ReturnCode], [TrackingValue]
		FROM dbo.UserLog_CasinoAPI l WITH(NOLOCK)
		WHERE EXISTS (SELECT TOP 1 1 FROM deleted WHERE deleted.LogId = l.logid AND deleted.LogDate = l.logdate AND deleted.custid = l.CustID)

		UNION ALL
		SELECT [LogID], [SystemID], [UserID], [FuncName], [LogDate], [CustID], [ActionID], [ReturnValue], [ReturnCode], [TrackingValue]
		FROM dbo.UserLog_CasinoAPI l WITH(NOLOCK)
		WHERE EXISTS (SELECT TOP 1 1 FROM deleted WHERE deleted.LogId = l.logid AND deleted.LogDate = l.logdate AND l.CustID IS NULL AND deleted.CustId IS NULL)
	END	
	ELSE IF @tableName = 'UserLog_Credit'
	BEGIN
		INSERT INTO bodb_CustomerLog_Archive.dbo.UserLog_Credit([logid], [userid], [custid], [logdate], [spname], [OldValue], [NewValue], [ip], [doing], [ActionID], [ActualRate], [CreatedDate])
		SELECT [logid], [userid], [custid], [logdate], [spname], [OldValue], [NewValue], [ip], [doing], [ActionID], [ActualRate], [CreatedDate]
		FROM dbo.UserLog_Credit l WITH(NOLOCK)
		WHERE EXISTS (SELECT TOP 1 1 FROM deleted WHERE deleted.LogId = l.logid AND deleted.LogDate = l.logdate AND deleted.custid = l.custid)

		UNION ALL
		SELECT [logid], [userid], [custid], [logdate], [spname], [OldValue], [NewValue], [ip], [doing], [ActionID], [ActualRate], [CreatedDate]
		FROM dbo.UserLog_Credit l WITH(NOLOCK)
		WHERE EXISTS (SELECT TOP 1 1 FROM deleted WHERE deleted.LogId = l.logid AND deleted.LogDate = l.logdate AND l.custid IS NULL AND deleted.CustId IS NULL)
	END	
	ELSE IF @tableName = 'UserLog_Dep_CustSetting'
	BEGIN
		INSERT INTO bodb_CustomerLog_Archive.dbo.UserLog_Dep_CustSetting([LogID], [UserID], [CustID], [logDate], [ActionID], [TrackingValue], [TrackingValue2], [Duration], [Language], [IP])
		SELECT [LogID], [UserID], [CustID], [logDate], [ActionID], [TrackingValue], [TrackingValue2], [Duration], [Language], [IP]
		FROM dbo.UserLog_Dep_CustSetting l WITH(NOLOCK)
		WHERE EXISTS (SELECT TOP 1 1 FROM deleted WHERE deleted.LogId = l.logid AND deleted.LogDate = l.logdate AND deleted.custid = l.CustID)

		UNION ALL
		SELECT [LogID], [UserID], [CustID], [logDate], [ActionID], [TrackingValue], [TrackingValue2], [Duration], [Language], [IP]
		FROM dbo.UserLog_Dep_CustSetting l WITH(NOLOCK)
		WHERE EXISTS (SELECT TOP 1 1 FROM deleted WHERE deleted.LogId = l.logid AND deleted.LogDate = l.logdate AND l.CustID IS NULL AND deleted.CustId IS NULL)
	END	
	ELSE IF @tableName = 'UserLog_ExternalAPI'
	BEGIN
		INSERT INTO bodb_CustomerLog_Archive.dbo.UserLog_ExternalAPI([LogID], [LogDate], [SystemID], [ProductID], [UserID], [FuncName], [CustID], [ActionID], [TrackingValue], [ModifiedDate], [StatusID], [isNotified], [ReturnCode], [ReturnValue])
		SELECT [LogID], [LogDate], [SystemID], [ProductID], [UserID], [FuncName], [CustID], [ActionID], [TrackingValue], [ModifiedDate], [StatusID], [isNotified], [ReturnCode], [ReturnValue]
		FROM dbo.UserLog_ExternalAPI l WITH(NOLOCK)
		WHERE EXISTS (SELECT TOP 1 1 FROM deleted WHERE deleted.LogId = l.logid AND deleted.LogDate = l.logdate AND deleted.custid = l.CustID)

		UNION ALL
		SELECT [LogID], [LogDate], [SystemID], [ProductID], [UserID], [FuncName], [CustID], [ActionID], [TrackingValue], [ModifiedDate], [StatusID], [isNotified], [ReturnCode], [ReturnValue]
		FROM dbo.UserLog_ExternalAPI l WITH(NOLOCK)
		WHERE EXISTS (SELECT TOP 1 1 FROM deleted WHERE deleted.LogId = l.logid AND deleted.LogDate = l.logdate AND l.CustID IS NULL AND deleted.CustId IS NULL)
	END	
	IF @tableName = 'CS_UserLog_RunSP'
	BEGIN
		INSERT INTO bodb_CustomerLog_Archive.dbo.CS_UserLog_RunSP(LogID, UserID, LogDate, CustID, SubAccID, ActionID, TrackingValue, Duration, TrackingValue2)
		SELECT LogID, UserID, LogDate, CustID, SubAccID, ActionID, TrackingValue, Duration, TrackingValue2
		FROM dbo.CS_UserLog_RunSP l WITH(NOLOCK)
		WHERE EXISTS (SELECT TOP 1 1 FROM deleted WHERE deleted.LogId = l.logid AND deleted.LogDate = l.logdate AND l.custid = deleted.custid)
	END
	IF @tableName = 'CS_UserLog_RunSP_LogTarget'
	BEGIN
		INSERT INTO bodb_CustomerLog_Archive.dbo.CS_UserLog_RunSP_LogTarget(LogID, LogDate, CustID)
		SELECT l.LogID, l.LogDate, l.CustID
		FROM dbo.CS_UserLog_RunSP_LogTarget l WITH(NOLOCK)
		WHERE EXISTS (SELECT TOP 1 1 FROM deleted WHERE deleted.LogId = l.logid AND deleted.CustID = l.CustID)
	END
	IF @tableName = 'CS_UserLog_RunSP_MultiTarget'
	BEGIN
		INSERT INTO bodb_CustomerLog_Archive.dbo.CS_UserLog_RunSP_MultiTarget(LogID, UserID, LogDate, ActionID, TrackingValue, Duration, TrackingValue2, MainLogID)
		SELECT LogID, UserID, LogDate, ActionID, TrackingValue, Duration, TrackingValue2, MainLogID
		FROM dbo.CS_UserLog_RunSP_MultiTarget l WITH(NOLOCK)
		WHERE EXISTS (SELECT TOP 1 1 FROM deleted WHERE deleted.LogId = l.logid AND deleted.LogDate = l.logdate)
	END
	ELSE IF @tableName = 'CS_UserLog_Login'
	BEGIN
		INSERT INTO bodb_CustomerLog_Archive.dbo.CS_UserLog_Login(LogID, UserID, RoleID, SubAccID, ServerID, IP, LogDate, ActionID, Doing, DomainName, BrowserName, Platform, CountryCode, Duration, username2,CreatedDate)
		SELECT LogID, UserID, RoleID, SubAccID, ServerID, IP, LogDate, ActionID, Doing, DomainName, BrowserName, Platform, CountryCode, Duration, username2,CreatedDate
		FROM dbo.CS_UserLog_Login l WITH(NOLOCK)
		WHERE EXISTS (SELECT TOP 1 1 FROM deleted WHERE deleted.LogId = l.logid AND deleted.LogDate = l.logdate AND l.userid = deleted.custid)
	END	
	ELSE IF @tableName = 'CS_UserLog_Credit'
	BEGIN
		INSERT INTO bodb_CustomerLog_Archive.dbo.CS_UserLog_Credit(LogID, UserID, CustID, SubAccID, LogDate, OldValue, NewValue, IP, Doing, ActionID, ActualRate,CreatedDate)
		SELECT LogID, UserID, CustID, SubAccID, LogDate, OldValue, NewValue, IP, Doing, ActionID, ActualRate,CreatedDate
		FROM dbo.CS_UserLog_Credit l WITH(NOLOCK)
		WHERE EXISTS (SELECT TOP 1 1 FROM deleted WHERE deleted.LogId = l.logid AND deleted.LogDate = l.logdate AND l.CustID = deleted.custid)
	END	
	IF @tableName = 'UserLog_RunSP_LogTarget'
	BEGIN
		INSERT INTO bodb_CustomerLog_Archive.dbo.UserLog_RunSP_LogTarget(LogID, LogDate, CustID)
		SELECT l.LogID, l.LogDate, l.CustID
		FROM dbo.UserLog_RunSP_LogTarget l WITH(NOLOCK)
		WHERE EXISTS (SELECT TOP 1 1 FROM deleted WHERE deleted.LogId = l.logid AND deleted.CustID = l.CustID)
	END
	IF @tableName = 'UserLog_RunSP_MultiTarget'
	BEGIN
		INSERT INTO bodb_CustomerLog_Archive.dbo.UserLog_RunSP_MultiTarget(LogID, UserID, LogDate, ActionID, TrackingValue, Duration, TrackingValue2, MainLogID)
		SELECT LogID, UserID, LogDate, ActionID, TrackingValue, Duration, TrackingValue2, MainLogID
		FROM dbo.UserLog_RunSP_MultiTarget l WITH(NOLOCK)
		WHERE EXISTS (SELECT TOP 1 1 FROM deleted WHERE deleted.LogId = l.logid AND deleted.LogDate = l.logdate)
	END
END