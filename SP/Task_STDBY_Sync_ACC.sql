USE [bodb_ACC]
GO

/****** Object:  StoredProcedure [dbo].[Task_STDBY_Sync_ACC]    Script Date: 01/21/2015 00:24:12 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_STDBY_Sync_ACC]

AS 
/*
	Created by:Jamie
	Date: 2013-07-29
	Task: Sync data for bodb_Acc
	DB: DBACC/bodb_ACC
	
	Revisions: 
	
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE	 @ctCurrentVersion				BIGINT
			,@ctMinVersionAcc_MailingList	BIGINT
			,@ctLastSyncVersion				BIGINT
			,@rowcntAcc_MailingList			INT

			
	SELECT	 @ctCurrentVersion				= CHANGE_TRACKING_CURRENT_VERSION()
			,@ctMinVersionAcc_MailingList	= 171
			,@rowcntAcc_MailingList			= 0
			
	SELECT	@ctLastSyncVersion = LastSyncVersion
	FROM	dbo.AccCTLastSyncVersion WITH (NOLOCK)
	WHERE	CTID = 1 
	
	IF	@ctLastSyncVersion >= @ctCurrentVersion RETURN	-- No changes 
	
	DECLARE	@tmpAcc_MailingList TABLE (
		 ChangedVersion		BIGINT
		,ChangedOperation	NVARCHAR(1)
		,SiteID				INT
		,FuncID				INT
		,ToList				VARCHAR(4000)
		,CcList				VARCHAR(4000)
		,BccList			VARCHAR(4000)
	)
	
	
	INSERT INTO @tmpAcc_MailingList(
		 ChangedVersion		
		,ChangedOperation	
		,SiteID				
		,FuncID				
		,ToList				
		,CcList				
		,BccList			
	)
	
	SELECT	 cl.SYS_CHANGE_VERSION
			,cl.SYS_CHANGE_OPERATION 
			,cl.SiteID
			,cl.FuncID
			,l.ToList
			,l.CcList
			,l.BccList
	FROM	CHANGETABLE (CHANGES dbo.Acc_MailingList,@ctLastSyncVersion) AS cl
			LEFT JOIN dbo.Acc_MailingList l ON cl.SiteID = l.SiteID AND cl.FuncID = l.FuncID 
	WHERE	cl.SYS_CHANGE_VERSION BETWEEN @ctMinVersionAcc_MailingList AND @ctCurrentVersion
			
	SELECT	@rowcntAcc_MailingList = @@ROWCOUNT 
	



	/* Synchronize data*/
	
	IF	@rowcntAcc_MailingList <> 0 
	BEGIN
	
		INSERT INTO DBACC_STDBY.bodb_ACC.dbo.Acc_MailingList(
			 SiteID				
			,FuncID				
			,ToList				
			,CcList				
			,BccList								
		)
		SELECT	 tc.SiteID
				,tc.FuncID
				,tc.ToList
				,tc.CcList
				,tc.BccList	
		FROM	@tmpAcc_MailingList tc 
				LEFT JOIN DBACC_STDBY.bodb_ACC.dbo.Acc_MailingList l WITH (NOLOCK) ON tc.SiteID = l.SiteID AND tc.FuncID = l.FuncID
		WHERE	tc.ChangedOperation = 'I'
				AND l.SiteID IS NULL 
				AND l.FuncID IS NULL 	

		UPDATE	l WITH (UPDLOCK,ROWLOCK)
		SET		ToList		= tc.ToList
				,CcList		= tc.CcList
				,BccList	= tc.BccList 
		FROM	@tmpAcc_MailingList tc 
				INNER JOIN DBACC_STDBY.bodb_ACC.dbo.Acc_MailingList l ON tc.SiteID = l.SiteID AND tc.FuncID = l.FuncID
		WHERE	tc.ChangedOperation IN ('I','U')
				AND l.SiteID IS NOT NULL 
				AND l.FuncID IS NOT NULL		
		
		DELETE	l  WITH (ROWLOCK)
		FROM	@tmpAcc_MailingList tc 
				INNER JOIN DBACC_STDBY.bodb_ACC.dbo.Acc_MailingList l ON tc.SiteID = l.SiteID AND tc.FuncID = l.FuncID
		WHERE	tc.ChangedOperation = 'D'
				AND l.SiteID IS NOT NULL 
				AND l.FuncID IS NOT NULL
 					
	END
	
			
	UPDATE	dbo.AccCTLastSyncVersion WITH (UPDLOCK,ROWLOCK)
	SET		 LastSyncVersion = @ctCurrentVersion 
			,ExtractionDate	= GETDATE()
	WHERE	CTID = 1
	
	PRINT  @ctCurrentVersion
END 
GO


