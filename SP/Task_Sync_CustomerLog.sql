USE [bodb_CustomerLog]
GO

/****** Object:  StoredProcedure [dbo].[Task_Sync_CustomerLog]    Script Date: 01/19/2015 02:41:43 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_Sync_CustomerLog]	
AS
/*   
 Task : copy CustomerLog data from active server to standby server
 DB: DB054.bodb_customerLog, DB052.bodb_customerLog  
 Revisions:   
  - 20130408@viet: create SP   
  - 20140526@Jamie: Add App Machine, App Category
*/  
SET NOCOUNT ON
BEGIN
	DECLARE @localServer sysname, @remoteServer sysname
	
	SET @localServer = @@servername
	SET @remoteServer = (SELECT * FROM OPENQUERY (DBLOG, 'select @@servername'))
	--SELECT @localServer, @remoteServer
	
	-- invalid remote server
	IF @localServer = @remoteServer RETURN -- same server, do nothing.
	
	
	DECLARE @max_id bigint, @startday smalldatetime, @logdate datetime
	SET @startday = DATEADD(dd, -7, CURRENT_TIMESTAMP)	


	---- [AppLog_Machine]
	SELECT	@max_id = ISNULL(MAX(MachineId),-1)
	FROM	[dbo].[AppLog_Machine] WITH (NOLOCK)

	IF @max_id <>-1
	BEGIN
		SET IDENTITY_INSERT [dbo].[AppLog_Machine] ON
		INSERT INTO [dbo].[AppLog_Machine]
           ([MachineId]
           ,[MachineName]
           ,[IsProduction]
           ,[TimeZone])
		SELECT	lm.*
		FROM	OPENQUERY(DBLOG,
				' SELECT [MachineId]
						,[MachineName]
						,[IsProduction]
						,[TimeZone]
				  FROM [bodb_CustomerLog].[dbo].[AppLog_Machine] WITH (NOLOCK) 
				'
		) AS lm 
		WHERE	lm.MachineId > @max_id

		SET IDENTITY_INSERT [dbo].[AppLog_Machine] OFF
	END 

	---- [AppLog_Category]
	SELECT	@max_id = ISNULL(MAX(CategoryID),-1)
	FROM	[dbo].AppLog_Category WITH (NOLOCK)

	IF @max_id <>-1
	BEGIN
		SET IDENTITY_INSERT [dbo].[AppLog_Category] ON
		INSERT INTO [bodb_CustomerLog].[dbo].[AppLog_Category]
				   ([CategoryID]
				   ,[CategoryName])
		SELECT	lc.*
		FROM	OPENQUERY(DBLOG,
				' SELECT	[CategoryID]
							,[CategoryName]
				  FROM		[bodb_CustomerLog].[dbo].[AppLog_Category] WITH (NOLOCK) 
				'
		) AS lc 
		WHERE	lc.[CategoryID] > @max_id

		SET IDENTITY_INSERT [dbo].[AppLog_Category] OFF
	END 

	
	---- UserLog_CasinoAPI ---
	select @max_id = isnull(max(logid),-1)
	FROM dbo.UserLog_CasinoAPI with(nolock)
	WHERE LogDate >= @startday
	
	IF @max_id <> -1
	BEGIN	
		SET IDENTITY_INSERT dbo.UserLog_CasinoAPI ON
		INSERT INTO dbo.UserLog_CasinoAPI (
			LogID, SystemID, UserID, FuncName, LogDate, CustID, ActionID, ReturnValue, ReturnCode, TrackingValue
		)
		SELECT a.*
		FROM OPENQUERY(DBLOG, 
			'SELECT LogID, SystemID, UserID, FuncName, LogDate, CustID, ActionID, ReturnValue, ReturnCode, cast(TrackingValue as nvarchar(max)) TrackingValue
			FROM bodb_customerLog.dbo.UserLog_CasinoAPI with(nolock)
			WHERE LogDate > DATEADD(dd, -7, CURRENT_TIMESTAMP)
			'
		) as a
		WHERE LogDate >= @startday
			and LogID > @max_id
		SET IDENTITY_INSERT dbo.UserLog_CasinoAPI OFF
	END	
	---- /UserLog_CasinoAPI ---
	
	---- UserLog_Credit ---
	select @max_id = isnull(max(logid),-1), @logdate = ISNULL(MAX(logdate),@startday)
	FROM dbo.UserLog_Credit with(nolock)
	WHERE LogDate >= @startday
	
	IF @max_id <> -1
	BEGIN	
		SET IDENTITY_INSERT dbo.UserLog_Credit ON
		INSERT INTO dbo.UserLog_Credit (
			logid, userid, custid, logdate, spname, OldValue, NewValue, ip, doing, ActionID
		)
		SELECT logid, userid, custid, logdate, spname, OldValue, NewValue, ip, doing, ActionID
		FROM DBLOG.bodb_customerLog.dbo.UserLog_Credit with(nolock)
		WHERE LogDate >= @logdate
			and LogID > @max_id		
		SET IDENTITY_INSERT dbo.UserLog_Credit OFF
	END	
	---- /UserLog_Credit ---
		
	---- UserLog_Exchange ---
	select @max_id = isnull(max(logid),-1), @logdate = ISNULL(MAX(logdate),@startday)
	FROM dbo.UserLog_Exchange with(nolock)
	WHERE LogDate >= @startday

	IF @max_id <> -1
	BEGIN	
		SET IDENTITY_INSERT dbo.UserLog_Exchange ON
		INSERT INTO dbo.UserLog_Exchange (
			LogID, UserID, ExchangeID, actualrate, doing, IP, LogDate
		)
		SELECT LogID, UserID, ExchangeID, actualrate, doing, IP, LogDate
		FROM DBLOG.bodb_customerLog.dbo.UserLog_Exchange with(nolock)
		WHERE LogDate >= @logdate
			and LogID > @max_id		
		SET IDENTITY_INSERT dbo.UserLog_Exchange OFF
	END	
	---- /UserLog_Exchange ---
	
	

	---- UserLog_Login ---
	select @max_id = isnull(max(logid),-1), @logdate = ISNULL(MAX(logdate),@startday)
	FROM dbo.UserLog_Login with(nolock)
	WHERE LogDate >= @startday
	
	IF @max_id <> -1
	BEGIN	
		SET IDENTITY_INSERT dbo.UserLog_Login ON
		INSERT INTO dbo.UserLog_Login (
			LogID, UserID, RoleID, SubAccID, ServerID, IP, LogDate, ActionID, Doing, DomainName, BrowserName, Platform, CountryCode, Duration, username2
		)
		SELECT LogID, UserID, RoleID, SubAccID, ServerID, IP, LogDate, ActionID, Doing, DomainName, BrowserName, Platform, CountryCode, Duration, username2
		FROM DBLOG.bodb_customerLog.dbo.UserLog_Login with(nolock)
		WHERE LogDate >= @logdate
			and LogID > @max_id		
		SET IDENTITY_INSERT dbo.UserLog_Login OFF
	END	
	---- /UserLog_Login ---

	---- UserLog_Login_Lrf ---
	select @max_id = isnull(max(logid),-1), @logdate = ISNULL(MAX(logdate),@startday)
	FROM dbo.UserLog_Login_Lrf with(nolock)
	WHERE LogDate >= @startday
	
	IF @max_id <> -1
	BEGIN	
		SET IDENTITY_INSERT dbo.UserLog_Login_Lrf ON
		INSERT INTO dbo.UserLog_Login_Lrf (
			LogID, UserID, ServerID, IP, LogDate, ActionID, Doing, DomainName, BrowserName, Platform, CountryCode, Duration
		)
		SELECT LogID, UserID, ServerID, IP, LogDate, ActionID, Doing, DomainName, BrowserName, Platform, CountryCode, Duration
		FROM DBLOG.bodb_customerLog.dbo.UserLog_Login_Lrf with(nolock)
		WHERE LogDate >= @logdate
			and LogID > @max_id		
		SET IDENTITY_INSERT dbo.UserLog_Login_Lrf OFF
	END	
	---- /UserLog_Login_Lrf ---

	---- UserLog_RunSP ---
	select @max_id = isnull(max(logid),-1), @logdate = ISNULL(MAX(logdate),@startday)
	FROM dbo.UserLog_RunSP with(nolock)
	WHERE LogDate >= @startday
	
	IF @max_id <> -1
	BEGIN	
		SET IDENTITY_INSERT dbo.UserLog_RunSP ON
		INSERT INTO dbo.UserLog_RunSP (
			logid, userid, spname, doing, logdate, custid, ActionID, TrackingValue, Duration, TrackingValue2
		)
		SELECT logid, userid, spname, doing, logdate, custid, ActionID, TrackingValue, Duration, TrackingValue2
		FROM DBLOG.bodb_customerLog.dbo.UserLog_RunSP with(nolock)
		WHERE LogDate >= @logdate
			and LogID > @max_id		
		SET IDENTITY_INSERT dbo.UserLog_RunSP OFF
	END	
	---- /UserLog_RunSP ---
	
	---- UserLog_Settle ---
	select @max_id = isnull(max(logid),-1), @logdate = ISNULL(MAX(logdate),@startday)
	FROM dbo.UserLog_Settle with(nolock)
	WHERE LogDate >= @startday
	
	IF @max_id <> -1
	BEGIN	
		SET IDENTITY_INSERT dbo.UserLog_Settle ON
		INSERT INTO dbo.UserLog_Settle (
			LogID, LogDate, UserID, MatchID, ActionID, finalhomescore, finalawayscore, 
			hthomescore, htawayscore, GoalRecord, betstatus, Remark, IP
		)
		SELECT LogID, LogDate, UserID, MatchID, ActionID, finalhomescore, finalawayscore, 
			hthomescore, htawayscore, GoalRecord, betstatus, Remark, IP
		FROM DBLOG.bodb_customerLog.dbo.UserLog_Settle with(nolock)
		WHERE LogDate >= @logdate
			and LogID > @max_id		
		SET IDENTITY_INSERT dbo.UserLog_Settle OFF
	END	
	---- /UserLog_Settle ---
	
	
	---- UserLog_Settle_Checking ---
	select @max_id = isnull(max(logid),-1), @logdate = ISNULL(MAX(logdate),@startday)
	FROM dbo.UserLog_Settle_Checking with(nolock)
	WHERE LogDate >= @startday
	
	IF @max_id <> -1
	BEGIN	
		SET IDENTITY_INSERT dbo.UserLog_Settle_Checking ON
		INSERT INTO dbo.UserLog_Settle_Checking (
			LogID, LogDate, UserID, MatchID, KeyID, ActionID, Remark
		)
		SELECT LogID, LogDate, UserID, MatchID, KeyID, ActionID, Remark
		FROM DBLOG.bodb_customerLog.dbo.UserLog_Settle_Checking with(nolock)
		WHERE LogDate >= @logdate
			and LogID > @max_id		
		SET IDENTITY_INSERT dbo.UserLog_Settle_Checking OFF
	END	
	---- /UserLog_Settle_Checking ---
	
	
	---- UserLog_Transaction ---
	select @max_id = isnull(max(logid),-1), @logdate = ISNULL(MAX(logdate),@startday)
	FROM dbo.UserLog_Transaction with(nolock)
	WHERE LogDate >= @startday
	
	IF @max_id <> -1
	BEGIN	
		SET IDENTITY_INSERT dbo.UserLog_Transaction ON
		INSERT INTO dbo.UserLog_Transaction (
			LogID, LogDate, ActionID, Refno, UserID, IP, Doing
		)
		SELECT LogID, LogDate, ActionID, Refno, UserID, IP, Doing
		FROM DBLOG.bodb_customerLog.dbo.UserLog_Transaction with(nolock)
		WHERE LogDate >= @logdate
			and LogID > @max_id		
		SET IDENTITY_INSERT dbo.UserLog_Transaction OFF
	END	
	---- /UserLog_Transaction ---
	
	
	---- UserLog_Transfer ---
	select @max_id = isnull(max(logid),-1), @logdate = ISNULL(MAX(logdate),@startday)
	FROM dbo.UserLog_Transfer with(nolock)
	WHERE LogDate >= @startday
	
	IF @max_id <> -1
	BEGIN	
		SET IDENTITY_INSERT dbo.UserLog_Transfer ON
		INSERT INTO dbo.UserLog_Transfer (
			LogID, LogDate, UserID, FromCustID, ToCustID, IP, Doing
		)
		SELECT LogID, LogDate, UserID, FromCustID, ToCustID, IP, Doing
		FROM DBLOG.bodb_customerLog.dbo.UserLog_Transfer with(nolock)
		WHERE LogDate >= @logdate
			and LogID > @max_id		
		SET IDENTITY_INSERT dbo.UserLog_Transfer OFF
	END	
	---- /UserLog_Transfer ---
	
	---- UserLog_UserControl ---
	select @max_id = isnull(max(logid),-1), @logdate = ISNULL(MAX(logdate),@startday)
	FROM dbo.UserLog_UserControl with(nolock)
	WHERE LogDate >= @startday
	
	IF @max_id <> -1
	BEGIN	
		SET IDENTITY_INSERT dbo.UserLog_UserControl ON
		INSERT INTO dbo.UserLog_UserControl (
			LogID, CustID, LogDate, UserID, TypeID, ActionID, Duration, Doing
		)
		SELECT LogID, CustID, LogDate, UserID, TypeID, ActionID, Duration, Doing
		FROM DBLOG.bodb_customerLog.dbo.UserLog_UserControl with(nolock)
		WHERE LogDate >= @logdate
			and LogID > @max_id		
		SET IDENTITY_INSERT dbo.UserLog_UserControl OFF
	END	
	---- /UserLog_UserControl ---
	
END
SET NOCOUNT OFF


GO


