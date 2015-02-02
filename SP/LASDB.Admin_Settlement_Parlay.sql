USE [LASDB]
GO

/****** Object:  StoredProcedure [dbo].[Admin_Settlement_Parlay]    Script Date: 01/27/2015 23:26:23 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[Admin_Settlement_Parlay] 
(
	@matchids	VARCHAR(2000)
	,@creator	INT
	,@action	VARCHAR(10) = 'CAL'
	,@IP		VARCHAR(15) = ''
	,@ErrCode	INT = 0 OUTPUT
	,@ErrMsg	NVARCHAR(200) = '' OUTPUT
	,@resultPS	NVARCHAR(10) = NULL
)
WITH RECOMPILE
AS
/*
Created		: 20140120@Don
Task		: Main SP for Parlay settlement
DB			: DBLAS.lasdb

Revisions:
	- 20141007@Don : Hot fix, [@betstatus <> 'Refund'] -> [@betstatus NOT LIKE 'Refund%']

Param's Explanation:

*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @start DATETIME, @stop DATETIME, @NotKeyScoreList VARCHAR(130)
	SELECT	@start = CURRENT_TIMESTAMP,
			@ErrCode = 0,
			@ErrMsg = ''	

	-- GET list of matchid(s)
	DECLARE @match TABLE (
		rn INT PRIMARY KEY IDENTITY(1,1), 
		matchid INT, 
		matchcode NVARCHAR(50),
		eventdate SMALLDATETIME, 
		fth SMALLINT, 
		fta SMALLINT, 
		hth SMALLINT, 
		hta SMALLINT,
		SportType SMALLINT, 
		betstatus NVARCHAR(50), 
		GoalRecord VARCHAR(50),	
		CalTime int,
		UNIQUE( matchid )
	)

	INSERT INTO @match(matchid,matchcode, eventdate,fth, fta, hth, hta, SportType, betstatus, GoalRecord)
		SELECT	matchid,matchcode, eventdate,	finalhomescore, finalawayscore, hthomescore, htawayscore,
				SportType, betstatus, GoalRecord
		FROM bodb02.dbo.Match WITH (ROWLOCK)
		WHERE matchid IN (SELECT val FROM bodb02.dbo.strSplit(@matchids,','))

	IF @action <> 'UNDO'
	BEGIN
		IF EXISTS (SELECT 1 FROM @match	WHERE fth is null or fta is null or hth is null or hta is null)
		BEGIN			
			SELECT @NotKeyScoreList  = COALESCE(@NotKeyScoreList + ',' + matchcode,matchcode)
			FROM @match
			WHERE fth IS NULL OR fta IS NULL OR hth IS NULL OR hta IS NULL

			-- exclude matches were not keyscore yet
			DELETE FROM @match
			WHERE fth IS NULL OR fta IS NULL OR hth IS NULL OR hta IS NULL
		END
	END

	DECLARE @rn INT,
			@subStart datetime, @CalTime int, @selTime int, @updTime int, @9Time int, @2Call int, @29Time int,
			@PreCal int, @Calculate int, @Summary int,
			@matchid INT, 
			@matchdate DATETIME,
			@finalhomescore INT,@finalawayscore INT,
			@hthomescore INT, @htawayscore INT, @GoalRecord VARCHAR(50),
			@sporttype TINYINT, @betstatus NVARCHAR(50),
			@TennisTotal SMALLINT, @T_Home SMALLINT, @T_Away SMALLINT,
			@tmp INT

	SET @rn = 1
	WHILE EXISTS (SELECT 1 FROM @match WHERE rn = @rn)
	BEGIN

		SELECT
			@subStart = CURRENT_TIMESTAMP,
			@matchid=matchid, @matchdate=eventdate,
			@finalhomescore=fth, @finalawayscore=fta, @hthomescore=hth, @htawayscore = hta,
			@sporttype=SportType, @betstatus=betstatus, @GoalRecord=GoalRecord
		FROM @match
		WHERE rn = @rn

		--IF (@SportType IN (5, 6, 9, 30)) and @action = 'CAL' and @betstatus NOT IN ('Refund', 'Refund;') -- Tennis/VolleyBall/Badminton/Squash: get TotalGamesPlayed
		IF (@SportType IN (5, 6, 9, 30)) and @action = 'CAL' and @betstatus NOT LIKE 'Refund%' -- Tennis/VolleyBall/Badminton/Squash: get TotalGamesPlayed
			EXEC dbo.Admin_Settlement_2
					@betstatus	= @betstatus,
					@Total		= @TennisTotal OUTPUT,
					@TotalHome	= @T_Home OUTPUT,
					@TotalAway	= @T_Away OUTPUT

		IF @SportType = 10 -- Golf, using Stroke count, so swap the score to make it become normal stype
		BEGIN
			SELECT @tmp = @finalhomescore, @finalhomescore = @finalawayscore
			SELECT @finalawayscore = @tmp
		END

		-- CALCULATE RESULT of mixparlay for each match
		---------------------------------------------------------------
		BEGIN TRANSACTION
			IF @action IN ('REFUND-FT','REFUND-HT') -- if REFUND-FT or REFUND-HT called, do 'CAL' first, before do 'REFUND-FT'
				EXEC dbo.Admin_Calculate_9m @matchid, @finalhomescore, @finalawayscore, @hthomescore, @htawayscore, @matchdate, 'CAL', @TennisTotal
		COMMIT TRANSACTION

		BEGIN TRANSACTION
			EXEC dbo.Admin_Calculate_9m @matchid, @finalhomescore, @finalawayscore, @hthomescore, @htawayscore, @matchdate, @action, @TennisTotal
		COMMIT TRANSACTION

		UPDATE @match
		SET CalTime = DATEDIFF(millisecond, @subStart, CURRENT_TIMESTAMP)
		WHERE rn = @rn

		SET @rn = @rn + 1
	END

	-- Generate data for BetParlayDetail/Result
	SET @subStart = CURRENT_TIMESTAMP
		EXEC dbo.Admin_Calculate_29_Precal @matchids
	SET @PreCal = DATEDIFF(millisecond, @subStart, CURRENT_TIMESTAMP)

	---------------------------------------------------------------
	SET @subStart = CURRENT_TIMESTAMP
	SELECT @selTime = 0, @updTime = 0, @9Time = 0, @2Call = 0, @29Time = 0

	Declare @subMatchIDs varchar(2000), @9Start datetime
	Declare @Ev TABLE (rn int PRIMARY KEY IDENTITY (1,1), EventDate smalldatetime)
	INSERT INTO @Ev (EventDate)
	SELECT DISTINCT EventDate
	FROM @match
	ORDER BY EventDate

	SET @rn = 1
	WHILE EXISTS (SELECT 1 FROM @Ev WHERE rn = @rn)
	BEGIN
		SELECT @matchdate = EventDate FROM @Ev WHERE rn = @rn

		SET @subMatchIDs = (
				SELECT CAST(matchid as varchar(20)) + ','
				FROM @match
				WHERE EventDate = @matchdate
				FOR XML PATH('')
			)
		SET @subMatchIDs = SUBSTRING(@subMatchIDs, 1, LEN(@subMatchIDs)-1)
		
		/* --
		DECLARE @strXML_modds varchar(MAX)
		SET @strXML_modds = ''
		BEGIN TRANSACTION
			SET @9Start = CURRENT_TIMESTAMP
			EXEC dbo.Admin_Calculate_9  
				@matchids = @subMatchIDs, 
				@matchdate = @matchdate, 
				@targetserver = 'TRANSDB', -- calculate at TRANSDB only
				@strXML = @strXML_modds OUTPUT,
				@selTime = @selTime OUTPUT, 
				@updTime = @updTime OUTPUT
			SET @9Time = @9Time + DATEDIFF(millisecond, @9Start, CURRENT_TIMESTAMP)
		COMMIT TRANSACTION

		WAITFOR DELAY '000:00:00.280' -- wait for log reader before calculating at replicated servers

		SET @9Start = CURRENT_TIMESTAMP
		EXEC dbo.Admin_Calculate_9  
			@matchids = @subMatchIDs, 
			@matchdate = @matchdate, 
			@targetserver = '', -- calculate at all replicated servers
			@strXML = @strXML_modds
		SET @2Call = @2Call + DATEDIFF(millisecond, @9Start, CURRENT_TIMESTAMP)
		*/

		BEGIN TRANSACTION
			SET @9Start = CURRENT_TIMESTAMP
			EXEC dbo.Admin_Calculate_29 @matchids = @subMatchIDs, @matchdate = @matchdate
			SET @29Time = @29Time + DATEDIFF(millisecond, @9Start, CURRENT_TIMESTAMP)
		COMMIT TRANSACTION

		SET @rn = @rn + 1
	END

	SET @Calculate = DATEDIFF(millisecond, @subStart, CURRENT_TIMESTAMP)

	--- insert sub-ticket into bettrans
	SET @subStart = CURRENT_TIMESTAMP
	SET @Summary = DATEDIFF(millisecond, @subStart, CURRENT_TIMESTAMP)

	SELECT @stop = CURRENT_TIMESTAMP

-------------------------------------------------------------
---                      WRITE LOG                        ---
---------------------------VVVV------------------------------
/* -- For writing log, consider
	Declare @LogData nvarchar(200)
	DECLARE @ActionID varchar(30), @Remark varchar(200)

	SET @rn = 1
	WHILE EXISTS (SELECT 1 FROM @match WHERE rn = @rn)
	BEGIN

		select
			@CalTime=CalTime,
			@matchid=matchid, @matchdate=eventdate,
			@finalhomescore=fth, @finalawayscore=fta, @hthomescore=hth, @htawayscore = hta,
			@sporttype=SportType, @betstatus=betstatus, @GoalRecord=GoalRecord
		from @match
		where rn = @rn

		SELECT @LogData = 'Calculate Multiple (' + @action 
			+ ') for matchid:' + CAST(@matchid as nvarchar(10)) 
			+ ' (' + CAST(DATEDIFF(millisecond, @start, @stop) as nvarchar(50)) + ' ms)'
			+ ' mpcs=' + CAST(@CalTime as nvarchar(10)) + ':' + CAST(@PreCal as nvarchar(10)) + ':' + CAST(@Calculate as nvarchar(10)) + ':' + CAST(@Summary as nvarchar(10))
			+ ' tsu2s=' + CAST(@9Time as nvarchar(10)) + ':' + CAST(@selTime as varchar(10)) + ':' + CAST(@updTIme as varchar(10)) + ':' + CAST(@2Call as nvarchar(10)) + ':' + CAST(@29Time as nvarchar(10))
		EXEC dbo.WriteLog_UserLog_T @creator, @LogData

		--Write Log Settle
		SELECT @ActionID = CASE @Action 
				WHEN 'CAL' THEN 104
				WHEN 'UNDO' THEN 105
				WHEN 'REFUND-FT' THEN 106
				WHEN 'REFUND-HT' THEN 120
				WHEN 'REFUND' THEN 107
			END
		SELECT @Remark = 'Duration:' + CAST(DATEDIFF(millisecond, @start, @stop) as nvarchar(50)) + ' ms'
			+ ' mpcs=' + CAST(@CalTime as nvarchar(10)) + ':' + CAST(@PreCal as nvarchar(10)) + ':' + CAST(@Calculate as nvarchar(10)) + ':' + CAST(@Summary as nvarchar(10))
			+ ' tsu2s=' + CAST(@9Time as nvarchar(10)) + ':' + CAST(@selTime as varchar(10)) + ':' + CAST(@updTIme as varchar(10)) + ':' + CAST(@2Call as nvarchar(10)) + ':' + CAST(@29Time as nvarchar(10))

		BEGIN TRY
			EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Settle
				@UserID = @creator,
				@Matchid = @matchid,
				@ActionID = @ActionID,
				@finalhomescore = @finalhomescore,
				@finalawayscore = @finalawayscore,  
				@hthomescore = @hthomescore,
				@htawayscore = @htawayscore,
				@GoalRecord = @goalrecord,
				@betstatus = @betstatus,
				@Remark = @Remark,    
				@IP = @IP
		END TRY  
		BEGIN CATCH	
			SELECT @Remark = @Remark + ' ErrMsg=' + left(error_message(), 250)	
			EXEC LogDB.dbo.WriteLog_Settlement_Settle
				@UserID = @creator,
				@Matchid = @matchid,
				@ActionID = @ActionID,
				@finalhomescore = @finalhomescore,
				@finalawayscore = @finalawayscore,  
				@hthomescore = @hthomescore,
				@htawayscore = @htawayscore,
				@GoalRecord = @goalrecord,
				@betstatus = @betstatus,
				@Remark = @Remark,    
				@IP = @IP
		END CATCH

		SET @rn = @rn + 1

	END
*/
	
	IF @NotKeyScoreList IS NOT NULL AND @NotKeyScoreList <> ''
	BEGIN
		SELECT	@ErrCode = 1,
				@ErrMsg = 'Calculate successfully, exclude these non-keyscore matches: ' + 
				CASE WHEN LEN(@NotKeyScoreList) = 130 THEN @NotKeyScoreList + '...'
					 ELSE @NotKeyScoreList
				END
	END

END



/*GO
GRANT EXECUTE ON [dbo].[Admin_Settlement_Parlay] TO [aplweb] AS [dbo]*/



GO

GRANT VIEW DEFINITION ON [dbo].[Admin_Settlement_Parlay] TO [vnteam] AS [dbo]
GO


