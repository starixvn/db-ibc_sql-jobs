USE [bodb_AGE]
GO

/****** Object:  StoredProcedure [dbo].[Task_STDBY_Sync_AGE]    Script Date: 01/20/2015 23:21:30 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Task_STDBY_Sync_AGE]

AS 
/*
	Create by: Jamie 
	Task: Sync data of bodb_Age 
		+ Acc_CustGroup
	DB: DBAGE/bodb_Age

	Revisions:
		- 20130722@Jamie: Remove Age//CustGroup
		- 20140515@Jamie: Add CustProfile
*/
BEGIN
	SET NOCOUNT ON 
	
	DECLARE	@rvCurrentVersion			VARBINARY(8)
			,@rvLastSyncVersion			VARBINARY(8)
			
			,@rowcntAcc_CustGroup			INT
			,@rowcntAge_CustProfilePicture	INT

	SELECT	@rvCurrentVersion		= @@DBTS
			,@rowcntAcc_CustGroup	= 0 
	
	SELECT	@rvLastSyncVersion = LastSyncVersion
	FROM	dbo.AgeRWLastSyncVersion WITH (NOLOCK)
	WHERE	rvID = 1 
	
	IF @rvLastSyncVersion >= @rvCurrentVersion  RETURN -- No changes 
	
	DECLARE	@tmpAcc_CustGroup TABLE(
		CustID		INT
		,RoleID		INT
		,GroupName	VARCHAR(10)
		,rv			VARBINARY(8)
	)
	
	DECLARE @tmpAge_CustProfilePicture TABLE(
		CustID		INT
		,[Image]	VARBINARY(MAX)
		,[Modified]	DATETIME
		,rv			VARBINARY(8)
	)

	INSERT INTO @tmpAcc_CustGroup(
		CustID
		,RoleID
		,GroupName
		,rv	
	)
	SELECT	CustID
			,RoleID
			,GroupName
			,rv	
	FROM	dbo.Acc_CustGroup WITH (NOLOCK)
	WHERE	rv BETWEEN @rvLastSyncVersion AND @rvCurrentVersion
	
	SELECT @rowcntAcc_CustGroup = @@ROWCOUNT 
	
	IF @rowcntAcc_CustGroup <> 0 
	BEGIN
		INSERT INTO DBAGE_STDBY.bodb_AGE.dbo.Acc_CustGroup(
			 CustID
			,RoleID
			,GroupName
		)
		SELECT	
				 tc.CustID
				,tc.RoleID
				,tc.GroupName
		FROM	@tmpAcc_CustGroup tc 
				LEFT JOIN DBAGE_STDBY.bodb_AGE.dbo.Acc_CustGroup ag WITH (NOLOCK) ON tc.CustID = ag.CustID AND tc.GroupName = ag.GroupName
		WHERE	ag.CustID IS NULL 
				AND ag.GroupName IS NULL
				
		UPDATE	ag WITH (ROWLOCK,UPDLOCK)
		SET		ag.RoleID = tc.RoleID
		FROM	@tmpAcc_CustGroup tc 
				INNER JOIN DBAGE_STDBY.bodb_AGE.dbo.Acc_CustGroup ag ON tc.CustID = ag.CustID AND tc.GroupName = ag.GroupName 
	END


	INSERT INTO @tmpAge_CustProfilePicture (
		[custid]
		,[image]
		,[modified]
		)
	SELECT	[custid]
			,[image]
			,[modified]
	FROM	dbo.Age_CustProfilePicture WITH (NOLOCK)
	WHERE	rv BETWEEN @rvLastSyncVersion AND @rvCurrentVersion

	SELECT	@rowcntAge_CustProfilePicture = @@ROWCOUNT

	IF @rowcntAge_CustProfilePicture <>0
	BEGIN
		INSERT INTO DBAGE_STDBY.bodb_AGE.dbo.Age_CustProfilePicture(
			 [custid]
			,[image]
			,[modified]
		)
		SELECT	
				 tc.CustID
				,tc.[image]
				,tc.[modified]
		FROM	@tmpAge_CustProfilePicture tc 
				LEFT JOIN DBAGE_STDBY.bodb_AGE.dbo.Age_CustProfilePicture ag WITH (NOLOCK) ON tc.CustID = ag.CustID 
		WHERE	ag.CustID IS NULL 
				
		UPDATE	ag WITH (ROWLOCK,UPDLOCK)
		SET		[image]		= tc.[image]
				,[modified] = tc.[modified]
		FROM	@tmpAge_CustProfilePicture tc 
				INNER JOIN DBAGE_STDBY.bodb_AGE.dbo.Age_CustProfilePicture ag ON tc.CustID = ag.CustID 
	END


	UPDATE	AgeRWLastSyncVersion WITH (UPDLOCK,ROWLOCK)
	SET		LastSyncVersion			= @rvCurrentVersion
			,ExtractionDate	= GETDATE()
	WHERE	rvID = 1 
	

END
GO

GRANT VIEW DEFINITION ON [dbo].[Task_STDBY_Sync_AGE] TO [vnteam] AS [dbo]
GO


