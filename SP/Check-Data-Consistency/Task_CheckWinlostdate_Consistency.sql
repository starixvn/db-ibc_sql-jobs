ALTER PROCEDURE [dbo].[Task_CheckWinlostdate_Consistency] @ErrMessage VARCHAR(512) = '' OUTPUT
AS
/*
	Created: 20150216@Lukas
	Task: check data on replicated servers
	DB: DBTP/bodb02
	Revision:
		- 20160624@Patrick: Move SP to DBTP & Rearrange code [Redmine: #59643]
		
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @winlostdate SMALLDATETIME, @rowcount INT
	SELECT @winlostdate = DATEADD(DAY, - 1, CONVERT(VARCHAR(20), GETDATE(), 112)), @rowcount = 0, @ErrMessage = ''
	DECLARE @NOTbettype TABLE (bettype SMALLINT)

	INSERT INTO @NOTbettype
	SELECT 10 --- outright
		--UNION ALL
		--SELECT 18000 -- Colossus Bet

	-- CHECK ON DB054
	SELECT DISTINCT 'DB054' svr, matchid
	FROM DB054.bodb02.dbo.bettrans WITH (NOLOCK)
	WHERE winlostdate >= @winlostdate
		AND matchid > 1000 -- (exclude 29, 255)
		AND bettype NOT IN (
			SELECT bettype
			FROM @NOTbettype
			)
	GROUP BY matchid
	HAVING MIN(winlostdate) <> MAX(winlostdate)
	OPTION (MAXDOP 4)

	SET @rowcount = @rowcount + @@ROWCOUNT

	---- check on DB05
	SELECT DISTINCT 'DB05' svr, matchid
	FROM DB05.bodb02.dbo.bettrans WITH (NOLOCK)
	WHERE winlostdate >= @winlostdate
		AND matchid > 1000 -- (exclude 29, 255)
		AND bettype NOT IN (
			SELECT bettype
			FROM @NOTbettype
			)
	GROUP BY matchid
	HAVING MIN(winlostdate) <> MAX(winlostdate)

	SET @rowcount = @rowcount + @@ROWCOUNT

	-- check on DB052
	SELECT DISTINCT 'DB052' svr, matchid
	FROM DB052.bodb02.dbo.bettrans WITH (NOLOCK)
	WHERE winlostdate >= @winlostdate
		AND matchid > 1000 -- (exclude 29, 255)
		AND bettype NOT IN (
			SELECT bettype
			FROM @NOTbettype
			)
	GROUP BY matchid
	HAVING MIN(winlostdate) <> MAX(winlostdate)

	SET @rowcount = @rowcount + @@ROWCOUNT

	-- check on DB053
	SELECT DISTINCT 'DB053' svr, matchid
	FROM DB053.bodb02.dbo.bettrans WITH (NOLOCK)
	WHERE winlostdate >= @winlostdate
		AND matchid > 1000 -- (exclude 29, 255)
		AND bettype NOT IN (
			SELECT bettype
			FROM @NOTbettype
			)
	GROUP BY matchid
	HAVING MIN(winlostdate) <> MAX(winlostdate)

	SET @rowcount = @rowcount + @@ROWCOUNT

	-- check on DB06
	SELECT DISTINCT 'DB06' svr, matchid
	FROM DB06.bodb02.dbo.bettrans WITH (NOLOCK)
	WHERE winlostdate >= @winlostdate
		AND matchid > 1000 -- (exclude 29, 255)
		AND bettype NOT IN (
			SELECT bettype
			FROM @NOTbettype
			)
	GROUP BY matchid
	HAVING MIN(winlostdate) <> MAX(winlostdate)

	SET @rowcount = @rowcount + @@ROWCOUNT

	-- check on DBTP
	--select distinct 'DBTP' svr, matchid 
	--from DBTP.bodb02.dbo.bettrans with(nolock)
	--where winlostdate >= @winlostdate
	--	and matchid > 1000 -- (exclude 29, 255)
	--	and bettype not in (SELECT bettype FROM @NOTbettype)	
	--group by matchid 
	--having MIN(winlostdate) <> MAX(winlostdate)
	--set @rowcount = @rowcount + @@ROWCOUNT
	
	IF @rowcount <> 0
	BEGIN
		SET @ErrMessage = 'Got tickets have wrong winlostdate.'

		--raiserror(N'got tickets have wrong winlostdate.',16,1)
		RETURN
	END
END
