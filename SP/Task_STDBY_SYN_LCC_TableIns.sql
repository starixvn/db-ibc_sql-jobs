USE [bodb_LCC]
GO

/****** Object:  StoredProcedure [dbo].[Task_STDBY_SYN_LCC_TableIns]    Script Date: 01/20/2015 22:55:28 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_STDBY_SYN_LCC_TableIns]
AS
/*
	Created by: Jamie
	Date: 20140602
	Task: LCC sync (RUN ONLY ON STANDBY SERVER)
	DB: DBLCC/bodb_LCC
		+ Match_queue

	Param's Explanation:
		+ @Type = 1: Match_queue

*/
BEGIN
	SET NOCOUNT ON 
	DECLARE	 @ctCurrentVersion			BIGINT
			,@ctLastSyncVersion			BIGINT
			,@Type						INT 

	EXEC DBLCC.bodb_LCC.dbo.[Task_STDBY_SYNC_LCC_currentVersion] @ctCurrentVersion = @ctCurrentVersion OUTPUT 

	PRINT @ctCurrentVersion 

	SELECT	@ctLastSyncVersion = LastSyncVersion
	FROM	DBLCC.bodb_LCC.dbo.CTLastSyncVersion WITH (NOLOCK)
	WHERE	CTID = 1 

	PRINT @ctLastSyncVersion

	IF	@ctLastSyncVersion >= @ctCurrentVersion RETURN	-- No changes 

	
	--- Match_queue = 1: WEB ADD /TASK UPDATE & DEL 
	CREATE TABLE #tmpMatch_Queue(
		ChangedOperation NVARCHAR(1),
		[matchid] [int] NOT NULL,
		[leagueid] [int] NULL,
		[homeid] [int] NULL,
		[awayid] [int] NULL,
		[eventdate] [datetime] NULL,
		[kickofftime] [datetime] NULL,
		[isPendingSyncTicket] [bit] NULL,
		[isPendingSyncOdds] [bit] NULL,
		[homescore] [smallint] NULL,
		[awayscore] [smallint] NULL,
		[hthomescore] [smallint] NULL,
		[htawayscore] [smallint] NULL,
		[homeredcard] [tinyint] NULL,
		[awayredcard] [tinyint] NULL,
		[matchstatus] [varchar](50) NULL,
		[liveperiod] [tinyint] NULL,
		[confirmHT] [int] NULL,
		[confirmFT] [int] NULL,
		[livetimer] [datetime] NULL,
		[chartshowingstatus] [tinyint] NULL)	
	INSERT INTO #tmpMatch_Queue(
		ChangedOperation
		,[matchid]
		,[leagueid]
		,[homeid]
		,[awayid]
		,[eventdate]
		,[kickofftime]
		,[isPendingSyncTicket]
		,[isPendingSyncOdds]
		,[homescore]
		,[awayscore]
		,[hthomescore]
		,[htawayscore]
		,[homeredcard]
		,[awayredcard]
		,[matchstatus]
		,[liveperiod]
		,[confirmHT]
		,[confirmFT]
		,[livetimer]
		,[chartshowingstatus]		
	)
	EXEC DBLCC.bodb_LCC.dbo.[Task_STDBY_SYN_LCC_TableSel] @Type = 1 ,@ctCurrentVersion = @ctCurrentVersion ,@ctLastSyncVersion = @ctLastSyncVersion
	IF @@ROWCOUNT <>0
	BEGIN
		MERGE Match_Queue AS TARGET
		USING #tmpMatch_Queue AS SOURCE ON (TARGET.MatchID = SOURCE.MatchID)
		WHEN NOT MATCHED BY TARGET AND SOURCE.ChangedOperation IN ('I') THEN 
			INSERT(
				 [matchid]
				,[leagueid]
				,[homeid]
				,[awayid]
				,[eventdate]
				,[kickofftime]
				,[isPendingSyncTicket]
				,[isPendingSyncOdds]
				,[homescore]
				,[awayscore]
				,[hthomescore]
				,[htawayscore]
				,[homeredcard]
				,[awayredcard]
				,[matchstatus]
				,[liveperiod]
				,[confirmHT]
				,[confirmFT]
				,[livetimer]
				,[chartshowingstatus]			
			)
			VALUES(
				 SOURCE.[matchid]
				,SOURCE.[leagueid]
				,SOURCE.[homeid]
				,SOURCE.[awayid]
				,SOURCE.[eventdate]
				,SOURCE.[kickofftime]
				,SOURCE.[isPendingSyncTicket]
				,SOURCE.[isPendingSyncOdds]
				,SOURCE.[homescore]
				,SOURCE.[awayscore]
				,SOURCE.[hthomescore]
				,SOURCE.[htawayscore]
				,SOURCE.[homeredcard]
				,SOURCE.[awayredcard]
				,SOURCE.[matchstatus]
				,SOURCE.[liveperiod]
				,SOURCE.[confirmHT]
				,SOURCE.[confirmFT]
				,SOURCE.[livetimer]
				,SOURCE.[chartshowingstatus]			
			); 
	END

	UPDATE	DBLCC.bodb_LCC.dbo.CTLastSyncVersion WITH (UPDLOCK,ROWLOCK)
	SET		 LastSyncVersion = @ctCurrentVersion 
			,ExtractionDate	= GETDATE()
	WHERE	CTID = 1
	
	PRINT  @ctCurrentVersion

	DROP TABLE #tmpMatch_Queue
END 
GO


