USE [bodb_LCC]
GO

/****** Object:  StoredProcedure [dbo].[Task_STDBY_SYN_LCC_TableSel]    Script Date: 01/27/2015 05:30:05 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_STDBY_SYN_LCC_TableSel]
 @Type				INT		= 0 
,@ctCurrentVersion	BIGINT	= 0 
,@ctLastSyncVersion	BIGINT	= 0
AS
/*
	Created by: Jamie
	Date: 20140602
	Task: LCC sync (RUN ONLY ON PRIMARY SERVER)
	DB: DBLCC/bodb_LCC
		+ Match_queue

	Param's Explanation:
		+ @Type = 1: Match_queue

*/
BEGIN
	SET NOCOUNT ON 

	DECLARE	 @ctMinVersionMatch_queue	BIGINT

	SELECT   @ctMinVersionMatch_queue	= 0

	---- Match_queue
	IF @Type = 1 
	BEGIN
		SELECT	 c.SYS_CHANGE_OPERATION 
				,c.[matchid]
				,m.[leagueid]
				,m.[homeid]
				,m.[awayid]
				,m.[eventdate]
				,m.[kickofftime]
				,1	--m.[isPendingSyncTicket]	
				,1  --m.[isPendingSyncOdds]
				,m.[homescore]
				,m.[awayscore]
				,m.[hthomescore]
				,m.[htawayscore]
				,m.[homeredcard]
				,m.[awayredcard]
				,m.[matchstatus]
				,m.[liveperiod]
				,m.[confirmHT]
				,m.[confirmFT]
				,m.[livetimer]
				,m.[chartshowingstatus]
		FROM	CHANGETABLE(CHANGES dbo.Match_queue,@ctLastSyncVersion) AS c
				LEFT JOIN dbo.Match_queue m WITH (NOLOCK) ON c.[matchid] = m.[matchid]
		WHERE	c.SYS_CHANGE_VERSION BETWEEN @ctMinVersionMatch_queue AND @ctCurrentVersion 

	END 


END 
GO


