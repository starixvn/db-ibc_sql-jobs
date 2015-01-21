USE [bodb_CustomerLog]
GO

/****** Object:  StoredProcedure [dbo].[SYNC_Log_FROM_DB052]    Script Date: 01/21/2015 00:14:04 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SYNC_Log_FROM_DB052]
AS
SET NOCOUNT ON
	
declare @maxID_DB054 bigint, @maxID_DB052 bigint
-- userlog_credit -----------------------------
	SELECT @maxID_DB054 =0, @maxID_DB052 = 0	
	
	SELECT @maxID_DB054 = MAX(logid)+1 
	FROM dbo.userlog_credit WITH(NOLOCK)
	WHERE logdate > '2013-01-04' -- MUST-HAVE condition, in order to use filtered index IF_LogID
	
	SELECT @maxID_DB052 = MAX(logid) 
	FROM DB052.bodb_customerLog.dbo.userlog_credit WITH(NOLOCK)
	WHERE logdate > '2013-01-04' -- MUST-HAVE condition, in order to use filtered index IF_LogID		
		
	SET IDENTITY_INSERT dbo.userlog_credit ON
	INSERT INTO dbo.userlog_credit (
		logid, userid, custid, logdate, spname, OldValue, NewValue, ip, doing, ActionID
	)
	SELECT logid, userid, custid, logdate, spname, OldValue, NewValue, ip, doing, ActionID
	FROM DB052.bodb_customerLog.dbo.userlog_credit WITH(NOLOCK)
	WHERE logdate > '2013-01-04' -- MUST-HAVE condition, in order to use filtered index IF_LogID		
		and logid between @maxID_DB054 and @maxID_DB052	 
	SET IDENTITY_INSERT dbo.userlog_credit OFF				
-- /userlog_credit -----------------------------		


-- UserLog_Exchange -----------------------------
	SELECT @maxID_DB054 =0, @maxID_DB052 = 0	
	
	SELECT @maxID_DB054 = MAX(logid)+1 
	FROM dbo.UserLog_Exchange WITH(NOLOCK)
	WHERE logdate > '2013-01-04' -- MUST-HAVE condition, in order to use filtered index IF_LogID
	
	SELECT @maxID_DB052 = MAX(logid) 
	FROM DB052.bodb_customerLog.dbo.UserLog_Exchange WITH(NOLOCK)
	WHERE logdate > '2013-01-04' -- MUST-HAVE condition, in order to use filtered index IF_LogID		
		
	SET IDENTITY_INSERT dbo.UserLog_Exchange ON
	INSERT INTO dbo.UserLog_Exchange (
		LogID, UserID, ExchangeID, actualrate, doing, IP, LogDate
	)
	SELECT LogID, UserID, ExchangeID, actualrate, doing, IP, LogDate
	FROM DB052.bodb_customerLog.dbo.UserLog_Exchange WITH(NOLOCK)
	WHERE logdate > '2013-01-04' -- MUST-HAVE condition, in order to use filtered index IF_LogID		
		and logid between @maxID_DB054 and @maxID_DB052	 
	SET IDENTITY_INSERT dbo.UserLog_Exchange OFF				
-- /UserLog_Exchange -----------------------------	
	

-- UserLog_Login -----------------------------
	SELECT @maxID_DB054 =0, @maxID_DB052 = 0	
	
	SELECT @maxID_DB054 = MAX(logid)+1 
	FROM dbo.UserLog_Login WITH(NOLOCK)
	WHERE logdate > '2013-01-04' -- MUST-HAVE condition, in order to use filtered index IF_LogID
	
	SELECT @maxID_DB052 = MAX(logid) 
	FROM DB052.bodb_customerLog.dbo.UserLog_Login WITH(NOLOCK)
	WHERE logdate > '2013-01-04' -- MUST-HAVE condition, in order to use filtered index IF_LogID		
			
	SET IDENTITY_INSERT dbo.UserLog_Login ON
	INSERT INTO dbo.UserLog_Login (
		LogID, UserID, RoleID, SubAccID, ServerID, IP, LogDate, ActionID, Doing, DomainName, 
		BrowserName, Platform, CountryCode, Duration, username2
	)
	SELECT LogID, UserID, RoleID, SubAccID, ServerID, IP, LogDate, ActionID, Doing, DomainName, 
		BrowserName, Platform, CountryCode, Duration, username2
	FROM DB052.bodb_customerLog.dbo.UserLog_Login WITH(NOLOCK)
	WHERE logdate > '2013-01-04' -- MUST-HAVE condition, in order to use filtered index IF_LogID		
		and logid between @maxID_DB054 and @maxID_DB052	 
	SET IDENTITY_INSERT dbo.UserLog_Login OFF				
-- /UserLog_Login -----------------------------	


-- UserLog_Login_Lrf -----------------------------
	SELECT @maxID_DB054 =0, @maxID_DB052 = 0	
	
	SELECT @maxID_DB054 = MAX(logid)+1 
	FROM dbo.UserLog_Login_Lrf WITH(NOLOCK)
	WHERE logdate > '2013-01-04' -- MUST-HAVE condition, in order to use filtered index IF_LogID
	
	SELECT @maxID_DB052 = MAX(logid) 
	FROM DB052.bodb_customerLog.dbo.UserLog_Login_Lrf WITH(NOLOCK)
	WHERE logdate > '2013-01-04' -- MUST-HAVE condition, in order to use filtered index IF_LogID		
			
	SET IDENTITY_INSERT dbo.UserLog_Login_Lrf ON
	INSERT INTO dbo.UserLog_Login_Lrf (
		LogID, UserID, ServerID, IP, LogDate, ActionID, Doing, DomainName, BrowserName, Platform, CountryCode, Duration
	)
	SELECT LogID, UserID, ServerID, IP, LogDate, ActionID, Doing, DomainName, BrowserName, Platform, CountryCode, Duration
	FROM DB052.bodb_customerLog.dbo.UserLog_Login_Lrf WITH(NOLOCK)
	WHERE logdate > '2013-01-04' -- MUST-HAVE condition, in order to use filtered index IF_LogID		
		and logid between @maxID_DB054 and @maxID_DB052	 
	SET IDENTITY_INSERT dbo.UserLog_Login_Lrf OFF				
-- /UserLog_Login_Lrf -----------------------------	
	

-- UserLog_runSP -----------------------------
	SELECT @maxID_DB054 =0, @maxID_DB052 = 0	
	
	SELECT @maxID_DB054 = MAX(logid)+1 
	FROM dbo.UserLog_runSP WITH(NOLOCK)
	WHERE logdate > '2013-01-04' -- MUST-HAVE condition, in order to use filtered index IF_LogID
	
	SELECT @maxID_DB052 = MAX(logid) 
	FROM DB052.bodb_customerLog.dbo.UserLog_runSP WITH(NOLOCK)
	WHERE logdate > '2013-01-04' -- MUST-HAVE condition, in order to use filtered index IF_LogID		
			
	SET IDENTITY_INSERT dbo.UserLog_runSP ON
	INSERT INTO dbo.UserLog_runSP (
		logid, userid, spname, doing, logdate, custid, ActionID, TrackingValue, Duration, TrackingValue2
	)
	SELECT logid, userid, spname, doing, logdate, custid, ActionID, TrackingValue, Duration, TrackingValue2
	FROM DB052.bodb_customerLog.dbo.UserLog_runSP WITH(NOLOCK)
	WHERE logdate > '2013-01-04' -- MUST-HAVE condition, in order to use filtered index IF_LogID		
		and logid between @maxID_DB054 and @maxID_DB052	 
	SET IDENTITY_INSERT dbo.UserLog_runSP OFF				
-- /UserLog_runSP -----------------------------	


-- UserLog_Settle -----------------------------
	SELECT @maxID_DB054 =0, @maxID_DB052 = 0	
	
	SELECT @maxID_DB054 = MAX(logid)+1 
	FROM dbo.UserLog_Settle WITH(NOLOCK)
	WHERE logdate > '2013-01-04' -- MUST-HAVE condition, in order to use filtered index IF_LogID
	
	SELECT @maxID_DB052 = MAX(logid) 
	FROM DB052.bodb_customerLog.dbo.UserLog_Settle WITH(NOLOCK)
	WHERE logdate > '2013-01-04' -- MUST-HAVE condition, in order to use filtered index IF_LogID		
		
	SET IDENTITY_INSERT dbo.UserLog_Settle ON
	INSERT INTO dbo.UserLog_Settle (
		LogID, LogDate, UserID, MatchID, ActionID, finalhomescore, finalawayscore, hthomescore, htawayscore, 
		goalRecord, betstatus, Remark, IP
	)
	SELECT LogID, LogDate, UserID, MatchID, ActionID, finalhomescore, finalawayscore, hthomescore, htawayscore, 
		goalRecord, betstatus, Remark, IP
	FROM DB052.bodb_customerLog.dbo.UserLog_Settle WITH(NOLOCK)
	WHERE logdate > '2013-01-04' -- MUST-HAVE condition, in order to use filtered index IF_LogID		
		and logid between @maxID_DB054 and @maxID_DB052	 
	SET IDENTITY_INSERT dbo.UserLog_Settle OFF				
-- /UserLog_Settle -----------------------------	
	

-- UserLog_Transaction -----------------------------
	SELECT @maxID_DB054 =0, @maxID_DB052 = 0	
	
	SELECT @maxID_DB054 = MAX(logid)+1 
	FROM dbo.UserLog_Transaction WITH(NOLOCK)
	WHERE logdate > '2013-01-04' -- MUST-HAVE condition, in order to use filtered index IF_LogID
	
	SELECT @maxID_DB052 = MAX(logid) 
	FROM DB052.bodb_customerLog.dbo.UserLog_Transaction WITH(NOLOCK)
	WHERE logdate > '2013-01-04' -- MUST-HAVE condition, in order to use filtered index IF_LogID		
			
	SET IDENTITY_INSERT dbo.UserLog_Transaction ON
	INSERT INTO dbo.UserLog_Transaction (
		LogID, LogDate, ActionID, Refno, UserID, IP, Doing
	)
	SELECT LogID, LogDate, ActionID, Refno, UserID, IP, Doing
	FROM DB052.bodb_customerLog.dbo.UserLog_Transaction WITH(NOLOCK)
	WHERE logdate > '2013-01-04' -- MUST-HAVE condition, in order to use filtered index IF_LogID		
		and logid between @maxID_DB054 and @maxID_DB052	 
	SET IDENTITY_INSERT dbo.UserLog_Transaction OFF				
-- /UserLog_Transaction -----------------------------	
	

-- UserLog_Transfer -----------------------------
	SELECT @maxID_DB054 =0, @maxID_DB052 = 0	
	
	SELECT @maxID_DB054 = MAX(logid)+1 
	FROM dbo.UserLog_Transfer WITH(NOLOCK)
	WHERE logdate > '2013-01-04' -- MUST-HAVE condition, in order to use filtered index IF_LogID
	
	SELECT @maxID_DB052 = MAX(logid) 
	FROM DB052.bodb_customerLog.dbo.UserLog_Transfer WITH(NOLOCK)
	WHERE logdate > '2013-01-04' -- MUST-HAVE condition, in order to use filtered index IF_LogID		
			
	SET IDENTITY_INSERT dbo.UserLog_Transfer ON
	INSERT INTO dbo.UserLog_Transfer (
		LogID, LogDate, UserID, FromCustID, ToCustID, IP, Doing
	)
	SELECT LogID, LogDate, UserID, FromCustID, ToCustID, IP, Doing
	FROM DB052.bodb_customerLog.dbo.UserLog_Transfer WITH(NOLOCK)
	WHERE logdate > '2013-01-04' -- MUST-HAVE condition, in order to use filtered index IF_LogID		
		and logid between @maxID_DB054 and @maxID_DB052	 
	SET IDENTITY_INSERT dbo.UserLog_Transfer OFF				
-- /UserLog_Transfer -----------------------------	
	

-- UserLog_UserControl -----------------------------
	SELECT @maxID_DB054 =0, @maxID_DB052 = 0	
	
	SELECT @maxID_DB054 = MAX(logid)+1 
	FROM dbo.UserLog_UserControl WITH(NOLOCK)
	WHERE logdate > '2013-01-04' -- MUST-HAVE condition, in order to use filtered index IF_LogID
	
	SELECT @maxID_DB052 = MAX(logid) 
	FROM DB052.bodb_customerLog.dbo.UserLog_UserControl WITH(NOLOCK)
	WHERE logdate > '2013-01-04' -- MUST-HAVE condition, in order to use filtered index IF_LogID		
			
	SET IDENTITY_INSERT dbo.UserLog_UserControl ON
	INSERT INTO dbo.UserLog_UserControl (
		LogID, CustID, LogDate, UserID, TypeID, ActionID, Duration, Doing
	)
	SELECT LogID, CustID, LogDate, UserID, TypeID, ActionID, Duration, Doing
	FROM DB052.bodb_customerLog.dbo.UserLog_UserControl WITH(NOLOCK)
	WHERE logdate > '2013-01-04' -- MUST-HAVE condition, in order to use filtered index IF_LogID		
		and logid between @maxID_DB054 and @maxID_DB052	 
	SET IDENTITY_INSERT dbo.UserLog_UserControl OFF				
-- /UserLog_UserControl -----------------------------	
	

-- rmUserLog_UserControl -----------------------------
	SELECT @maxID_DB054 =0, @maxID_DB052 = 0	
	
	SELECT @maxID_DB054 = MAX(logid)+1 
	FROM dbo.rmUserLog_UserControl WITH(NOLOCK)
	WHERE logdate > '2013-01-04' -- MUST-HAVE condition, in order to use filtered index IF_LogID
	
	SELECT @maxID_DB052 = MAX(logid) 
	FROM DB052.bodb_customerLog.dbo.rmUserLog_UserControl WITH(NOLOCK)
	WHERE logdate > '2013-01-04' -- MUST-HAVE condition, in order to use filtered index IF_LogID		
			
	SET IDENTITY_INSERT dbo.rmUserLog_UserControl ON
	INSERT INTO dbo.rmUserLog_UserControl (
		LogID, CustID, LogDate, UserID, TypeID, ActionID, Duration, Doing
	)
	SELECT LogID, CustID, LogDate, UserID, TypeID, ActionID, Duration, Doing
	FROM DB052.bodb_customerLog.dbo.rmUserLog_UserControl WITH(NOLOCK)
	WHERE logdate > '2013-01-04' -- MUST-HAVE condition, in order to use filtered index IF_LogID		
		and logid between @maxID_DB054 and @maxID_DB052	 
	SET IDENTITY_INSERT dbo.rmUserLog_UserControl OFF				
-- /rmUserLog_UserControl -----------------------------	
	

-- rmUserLog_RunSP -----------------------------
	SELECT @maxID_DB054 =0, @maxID_DB052 = 0	
	
	SELECT @maxID_DB054 = MAX(logid)+1 
	FROM dbo.rmUserLog_RunSP WITH(NOLOCK)
	WHERE logdate > '2013-01-04' -- MUST-HAVE condition, in order to use filtered index IF_LogID
	
	SELECT @maxID_DB052 = MAX(logid) 
	FROM DB052.bodb_customerLog.dbo.rmUserLog_RunSP WITH(NOLOCK)
	WHERE logdate > '2013-01-04' -- MUST-HAVE condition, in order to use filtered index IF_LogID		
			
	SET IDENTITY_INSERT dbo.rmUserLog_RunSP ON
	INSERT INTO dbo.rmUserLog_RunSP (
		LogID, UserID, Logdate, CustID, ActionID, TrackingValue, Duration, TrackingValue2
	)
	SELECT LogID, UserID, Logdate, CustID, ActionID, TrackingValue, Duration, TrackingValue2
	FROM DB052.bodb_customerLog.dbo.rmUserLog_RunSP WITH(NOLOCK)
	WHERE logdate > '2013-01-04' -- MUST-HAVE condition, in order to use filtered index IF_LogID		
		and logid between @maxID_DB054 and @maxID_DB052	 
	SET IDENTITY_INSERT dbo.rmUserLog_RunSP OFF				
-- /rmUserLog_RunSP -----------------------------	
	

-- rmUserLog_Login -----------------------------
	SELECT @maxID_DB054 =0, @maxID_DB052 = 0	
	
	SELECT @maxID_DB054 = MAX(logid)+1 
	FROM dbo.rmUserLog_Login WITH(NOLOCK)
	WHERE logdate > '2013-01-04' -- MUST-HAVE condition, in order to use filtered index IF_LogID
	
	SELECT @maxID_DB052 = MAX(logid) 
	FROM DB052.bodb_customerLog.dbo.rmUserLog_Login WITH(NOLOCK)
	WHERE logdate > '2013-01-04' -- MUST-HAVE condition, in order to use filtered index IF_LogID		
			
	SET IDENTITY_INSERT dbo.rmUserLog_Login ON
	INSERT INTO dbo.rmUserLog_Login (
		LogID, UserID, IP, LogDate, ActionID, Doing, DomainName, BrowserName, Platform, CountryCode, Duration
	)
	SELECT LogID, UserID, IP, LogDate, ActionID, Doing, DomainName, BrowserName, Platform, CountryCode, Duration
	FROM DB052.bodb_customerLog.dbo.rmUserLog_Login WITH(NOLOCK)
	WHERE logdate > '2013-01-04' -- MUST-HAVE condition, in order to use filtered index IF_LogID		
		and logid between @maxID_DB054 and @maxID_DB052	 
	SET IDENTITY_INSERT dbo.rmUserLog_Login OFF				
-- /rmUserLog_Login -----------------------------	
GO


