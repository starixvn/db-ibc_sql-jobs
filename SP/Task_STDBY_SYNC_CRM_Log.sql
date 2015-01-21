USE [bodb_CRM]
GO

/****** Object:  StoredProcedure [dbo].[Task_STDBY_SYNC_CRM_Log]    Script Date: 01/20/2015 05:49:16 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_STDBY_SYNC_CRM_Log]

AS
/*
	Created: Jamie
	DB: DBCRM/bodb_CRM
	Task: Sync LOG ( Run on standby db)
		+ crmLogSetting
		+ crmLogRedemption
		+ crmLogFeedback
		+ crmLogCustomerRemark
		+ crmLogCustomer 
*/
BEGIN
	SET NOCOUNT ON 
	
	DECLARE	 @ServCurrent	SYSNAME
			,@ServRemote	SYSNAME
	
	SELECT	@ServCurrent = @@SERVERNAME
	SELECT	@ServRemote	 = (SELECT * FROM OPENQUERY(DBCRM,'SELECT @@SERVERNAME'))
	
	IF @ServCurrent = @ServRemote RETURN ---- In the same server 

	DECLARE  @max_id BIGINT
			,@startday SMALLDATETIME
			,@logdate DATETIME

	SET @startday = DATEADD(dd, -7, CURRENT_TIMESTAMP)

	---- [crmLogCustomer]
	SELECT	@max_id		= ISNULL(MAX(LogID),-1)
			,@logdate	= ISNULL(MAX(LogDate),@startday)
	FROM	[dbo].[crmLogCustomer] WITH (NOLOCK)
	WHERE	LogDate >= @startday

	IF @max_id <>-1
	BEGIN
		SET IDENTITY_INSERT [crmLogCustomer] ON
		INSERT INTO [bodb_CRM].[dbo].[crmLogCustomer]
			(	 [LogID]
				,[LogDate]
				,[CustID]
				,[UserID]
				,[ActionID]
				,[IP]
				,[Doing]
				,[OldValues]
			)
		SELECT	[LogID]
				,[LogDate]
				,[CustID]
				,[UserID]
				,[ActionID]
				,[IP]
				,CAST([Doing] AS XML)
				,CAST([OldValues] AS XML)
		FROM	OPENQUERY(DBCRM,
					'	SELECT	 [LogID]
								,[LogDate]
								,[CustID]
								,[UserID]
								,[ActionID]
								,[IP]
								,[Doing] = CAST([Doing] AS NVARCHAR(MAX))
								,[OldValues] = CAST([OldValues] AS NVARCHAR(MAX))
						FROM	[bodb_CRM].[dbo].[crmLogCustomer] WITH (NOLOCK)	
					') AS crmLog
		WHERE	LogID > @max_id
				AND LogDate >=@logdate 
		SET IDENTITY_INSERT [crmLogCustomer] OFF
	END

	---- [crmLogCustomerRemark]
	SELECT	@max_id		= ISNULL(MAX(LogID),-1)
			,@logdate	= ISNULL(MAX(LogDate),@startday)
	FROM	[dbo].[crmLogCustomerRemark] WITH (NOLOCK)
	WHERE	LogDate >= @startday

	IF @max_id <>-1
	BEGIN
		SET IDENTITY_INSERT [crmLogCustomerRemark] ON
		INSERT INTO [bodb_CRM].[dbo].[crmLogCustomerRemark]
			(	 [LogID]
				,[LogDate]
				,[CustID]
				,[UserID]
				,[ActionID]
				,[IP]
				,[NewValues]
				,[OldValues]
			)	
		SELECT	[LogID]
				,[LogDate]
				,[CustID]
				,[UserID]
				,[ActionID]
				,[IP]
				,CAST([NewValues] AS XML)
				,CAST([OldValues] AS XML)
		FROM	OPENQUERY(DBCRM,
				'	SELECT	[LogID]
							,[LogDate]
							,[CustID]
							,[UserID]
							,[ActionID]
							,[IP]
							,[NewValues] = CAST([NewValues] AS NVARCHAR(MAX))
							,[OldValues] = CAST([OldValues] AS NVARCHAR(MAX))
					FROM	[bodb_CRM].[dbo].[crmLogCustomerRemark] WITH (NOLOCK)
				'
				)
		WHERE	LogID > @max_id
				AND LogDate >=@logdate
		SET IDENTITY_INSERT [crmLogCustomerRemark] OFF
	END	

	---- [crmLogFeedback]
	SELECT	@max_id		= ISNULL(MAX(LogID),-1)
			,@logdate	= ISNULL(MAX(LogDate),@startday)
	FROM	[dbo].[crmLogFeedback] WITH (NOLOCK)
	WHERE	LogDate >= @startday

	IF @max_id <>-1
	BEGIN
		SET IDENTITY_INSERT [crmLogFeedback] ON
		INSERT INTO [bodb_CRM].[dbo].[crmLogFeedback]
			(	 [LogID]
				,[LogDate]
				,[FeedbackID]
				,[CustID]
				,[UserID]
				,[ActionID]
				,[IP]
				,[Description]
				,[Solution]
				,[Review]
				,[Doing]
				,[OldValues]
			)
		SELECT	 [LogID]
				,[LogDate]
				,[FeedbackID]
				,[CustID]
				,[UserID]
				,[ActionID]
				,[IP]
				,[Description]
				,[Solution]
				,[Review]
				,CAST([Doing] AS XML)
				,CAST([OldValues] AS XML)
		FROM	OPENQUERY(DBCRM,
					'	SELECT	 [LogID]
								,[LogDate]
								,[FeedbackID]
								,[CustID]
								,[UserID]
								,[ActionID]
								,[IP]
								,[Description]
								,[Solution]
								,[Review]
								,[Doing] = CAST([Doing] AS NVARCHAR(MAX))
								,[OldValues] = CAST([OldValues] AS NVARCHAR(MAX))
						FROM	[bodb_CRM].[dbo].[crmLogFeedback] WITH (NOLOCK)
					'
				)
		WHERE	LogID > @max_id
				AND LogDate >=@logdate
		SET IDENTITY_INSERT [crmLogFeedback] OFF
	END

	---- [crmLogRedemption]
	SELECT	@max_id		= ISNULL(MAX(LogID),-1)
			,@logdate	= ISNULL(MAX(LogDate),@startday)
	FROM	[dbo].[crmLogRedemption] WITH (NOLOCK)
	WHERE	LogDate >= @startday

	IF @max_id <>-1
	BEGIN
		SET IDENTITY_INSERT [crmLogRedemption] ON
		INSERT INTO [bodb_CRM].[dbo].[crmLogRedemption]
			(	 [LogID]
				,[LogDate]
				,[RedemptionID]
				,[CustID]
				,[UserID]
				,[ActionID]
				,[IP]
				,[NewValues]
				,[OldValues]
			 )
		SELECT	 [LogID]
				,[LogDate]
				,[RedemptionID]
				,[CustID]
				,[UserID]
				,[ActionID]
				,[IP]
				,CAST([NewValues] AS XML)
				,CAST([OldValues] AS XML)
		FROM	OPENQUERY(DBCRM,
					'	SELECT	 [LogID]
								,[LogDate]
								,[RedemptionID]
								,[CustID]
								,[UserID]
								,[ActionID]
								,[IP]
								,[NewValues] = CAST([NewValues] AS NVARCHAR(MAX))
								,[OldValues] =  CAST([OldValues] AS NVARCHAR(MAX))
						FROM	[bodb_CRM].[dbo].[crmLogRedemption] WITH (NOLOCK)
					'
				)
		WHERE	LogID > @max_id
				AND LogDate >=@logdate
		SET IDENTITY_INSERT [crmLogRedemption] OFF
	END
	---- [crmLogSetting]
	SELECT	@max_id		= ISNULL(MAX(LogID),-1)
			,@logdate	= ISNULL(MAX(LogDate),@startday)
	FROM	[dbo]. [crmLogSetting] WITH (NOLOCK)
	WHERE	LogDate >= @startday

	IF @max_id <>-1
	BEGIN
		SET IDENTITY_INSERT  [crmLogSetting] ON
		INSERT INTO [bodb_CRM].[dbo]. [crmLogSetting]
			(	 [LogID]
				,[LogDate]
				,[SettingID]
				,[ParentID]
				,[UserID]
				,[ActionID]
				,[IP]
				,[Doing]
				,[OldValues]
				)
		SELECT	 [LogID]
				,[LogDate]
				,[SettingID]
				,[ParentID]
				,[UserID]
				,[ActionID]
				,[IP]
				,CAST([Doing] AS XML)
				,CAST([OldValues] AS XML)
		FROM	OPENQUERY(DBCRM,
					'	SELECT	 [LogID]
								,[LogDate]
								,[SettingID]
								,[ParentID]
								,[UserID]
								,[ActionID]
								,[IP]
								,[Doing] = CAST([Doing] AS NVARCHAR(MAX))
								,[OldValues] = CAST([OldValues] AS NVARCHAR(MAX))
						FROM	[bodb_CRM].[dbo]. [crmLogSetting] WITH (NOLOCK)			
					'
				)
		WHERE	LogID > @max_id
				AND LogDate >=@logdate
		SET IDENTITY_INSERT  [crmLogSetting] OFF
	END

END
GO


