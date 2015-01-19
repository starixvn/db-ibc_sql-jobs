USE [bodb_RMS]
GO

/****** Object:  StoredProcedure [dbo].[Task_STDBY_Sync_RMS]    Script Date: 01/16/2015 03:24:49 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_STDBY_Sync_RMS]

AS 
/*
	Created by: Jamie 
	Date: 2013-04-10
	Task: Synchronize data bodb_RMS 
			+ rmCustomer 
			+ rmAgent 
			
	Revisions:
		- 20140517@Jamie: Add rmAgent 

*/
BEGIN
	SET NOCOUNT ON
	DECLARE	 @ctCurrentVersion			BIGINT
			,@ctLastSyncVersion			BIGINT
			,@ctMinVersionRMCustomer	BIGINT
			,@ctMinVersionRMAgent		BIGINT
			,@rowcntRMCustomer			BIGINT
			,@rowcntRMAgent				BIGINT

	SELECT	 @ctCurrentVersion			= CHANGE_TRACKING_CURRENT_VERSION()
			,@ctMinVersionRMCustomer	= 0
			,@ctMinVersionRMAgent		= 679 
			
	SELECT	@ctLastSyncVersion = LastSyncVersion
	FROM	dbo.rmCTLastSyncVersion WITH (NOLOCK)
	WHERE	CTID = 1 
	
	IF	@ctLastSyncVersion >= @ctCurrentVersion RETURN	-- No changes 
	
	DECLARE	@tmpRMCustomer TABLE(
		 ChangedVersion		BIGINT
		,ChangedOperation	NVARCHAR(1)
		,CustID				INT
		,UserName			VARCHAR(30)
		,Level				TINYINT
		,CreatedDate		DATETIME NULL
		,Creator			INT	NULL
	)

	DECLARE	@tmprmAgent TABLE(
		ChangedVersion		BIGINT
	  ,[ChangedOperation]	NVARCHAR(1)
	  ,[AgentID]			INT
      ,[username]			NVARCHAR(50)
      ,[createdDate]		DATETIME
      ,[creator]			INT
	)
	
	INSERT INTO @tmpRMCustomer(
		 ChangedVersion
		,ChangedOperation
		,CustID
		,UserName
		,Level
		,CreatedDate
		,Creator	
	)
	
	SELECT   c.SYS_CHANGE_VERSION
			,c.SYS_CHANGE_OPERATION 
			,c.CustID
			,rmC.username
			,rmC.[level]
			,rmC.createdDate
			,rmC.creator
	FROM	CHANGETABLE(CHANGES dbo.rmCustomer,@ctLastSyncVersion) AS c
			LEFT JOIN dbo.rmCustomer rmC WITH (NOLOCK) ON c.CustID = rmC.custid
	WHERE	c.SYS_CHANGE_VERSION BETWEEN @ctMinVersionRMCustomer AND @ctCurrentVersion 
		
	SELECT	@rowcntRMCustomer = @@ROWCOUNT 
	
	IF @rowcntRMCustomer <> 0 
	BEGIN
		INSERT INTO DBRMS_STDBY.bodb_RMS.dbo.RMCustomer(
			 CustID
			,UserName
			,Level
			,CreatedDate
			,Creator	
		)
		SELECT  tc.CustID
				,tc.UserName
				,tc.Level
				,tc.CreatedDate
				,tc.Creator
		FROM	@tmpRMCustomer tc 
				LEFT JOIN DBRMS_STDBY.bodb_RMS.dbo.RMCustomer rmc WITH (NOLOCK) ON tc.CustID = rmc.CustID
		WHERE	tc.ChangedOperation ='I'
				AND rmc.CustID IS NULL
		
		
		UPDATE	rmc WITH (UPDLOCK,ROWLOCK)
		SET		 rmc.UserName		= tc.UserName
				,rmc.Level			= tc.Level
				,rmc.CreatedDate	= tc.CreatedDate
				,rmc.Creator		= tc.Creator 
		FROM	@tmpRMCustomer tc
				INNER JOIN DBRMS_STDBY.bodb_RMS.dbo.RMCustomer rmc ON tc.CustID = rmc.CustID
		WHERE	tc.ChangedOperation IN ('I','U')
				AND rmc.CustID IS NOT NULL 			
		
		DELETE	rmc WITH (UPDLOCK,ROWLOCK)
		FROM	@tmpRMCustomer tc
				INNER JOIN DBRMS_STDBY.bodb_RMS.dbo.RMCustomer rmc ON tc.CustID = rmc.CustID
		WHERE	tc.ChangedOperation IN ('D')
	
	END

	--rmAgent
	INSERT INTO @tmprmAgent(
			 ChangedVersion
			,ChangedOperation
			,[AgentID]			
			,[username]			
			,[createdDate]		
			,[creator]	
		)
	
	SELECT   c.SYS_CHANGE_VERSION
			,c.SYS_CHANGE_OPERATION 
			,c.AgentID
			,rma.username
			,rma.createdDate
			,rma.creator
	FROM	CHANGETABLE(CHANGES dbo.rmAgent,@ctLastSyncVersion) AS c
			LEFT JOIN dbo.rmAgent rmA WITH (NOLOCK) ON c.AgentID = rmA.AgentID
	WHERE	c.SYS_CHANGE_VERSION BETWEEN @ctMinVersionRMAgent AND @ctCurrentVersion 
		
	SELECT	@rowcntRMAgent = @@ROWCOUNT 
	
	IF @rowcntRMAgent <> 0 
	BEGIN
		INSERT INTO DBRMS_STDBY.[bodb_RMS].[dbo].[rmAgent]
           ([AgentID]
           ,[username]
           ,[createdDate]
           ,[creator])

		SELECT   tc.AgentID
				,tc.UserName
				,tc.CreatedDate
				,tc.Creator
		FROM	@tmprmAgent tc 
				LEFT JOIN DBRMS_STDBY.bodb_RMS.dbo.rmAgent rmc WITH (NOLOCK) ON tc.AgentID = rmc.AgentID
		WHERE	tc.ChangedOperation ='I'
				AND rmc.AgentID IS NULL


		UPDATE	rmc WITH (UPDLOCK,ROWLOCK)
		SET		Username		= tc.username
				,CreatedDate	= tc.createdDate
				,Creator		= tc.creator
		FROM	@tmprmAgent tc 
				INNER JOIN DBRMS_STDBY.bodb_RMS.dbo.rmAgent rmc ON tc.AgentID = rmc.AgentID
		WHERE	tc.ChangedOperation IN ('I','U')
				AND rmc.AgentID IS NOT NULL 	

		DELETE	rmc WITH (UPDLOCK,ROWLOCK)
		FROM	@tmprmAgent tc
				INNER JOIN DBRMS_STDBY.bodb_RMS.dbo.RMAgent rmc ON tc.AgentID = rmc.AgentID
		WHERE	tc.ChangedOperation IN ('D')
	END 

	UPDATE	dbo.rmCTLastSyncVersion WITH (UPDLOCK,ROWLOCK)
	SET		 LastSyncVersion = @ctCurrentVersion 
			,ExtractionDate	= GETDATE()
	WHERE	CTID = 1
	
	PRINT  @ctCurrentVersion

END
GO


