SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE	[dbo].[Task_ParlayMovement] @Winlostdate SMALLDATETIME
	, @LimitRowAffected INT = 5000
AS
/*
	Created: 20161214@Patrick
	Task: Daily parlay movement
	DB: DBTRANS/BODB02

	Revisions:
		- 20170220@Patrick: Exclude UUS account
*/
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #TransIds (RowId INT IDENTITY(1,1), TransId BIGINT)

	DECLARE @Today_Winlostdate SMALLDATETIME
	SET @Today_Winlostdate = CONVERT(VARCHAR(12), GETDATE(), 112)

	INSERT INTO #TransIds(TransId)
	SELECT TransId
	FROM dbo.bettrans b WITH(NOLOCK)
	WHERE b.winlostdate < @Winlostdate
		AND b.statusID = 0
		AND b.bettype IN (9,29)
		AND b.matchid IN (9,29)
		AND b.currency <> 20

	IF @@ROWCOUNT <= @LimitRowAffected --auto fix
	BEGIN
		UPDATE dbo.bettrans WITH(ROWLOCK, UPDLOCK)
		SET winlostdate = @Today_Winlostdate
		WHERE transid IN (SELECT t.TransId FROM #TransIds t)
		
		--write log
		DECLARE @RowId INT, @Doing VARCHAR(300)
		SELECT @RowId = 1, @Doing = ''
		WHILE EXISTS (SELECT TOP 1 1 FROM #TransIds WHERE RowId = @RowId)
		BEGIN
			IF @Doing = ''
				SET @Doing = '[Task_ParlayMovement] - TransIds: '

			SELECT @Doing = @Doing + CAST(TransId AS VARCHAR(50)) + ','
			FROM #TransIds WHERE RowId = @RowId

			SET @RowId = @RowId + 1

			IF DATALENGTH(@Doing) >= 280
			BEGIN
				SET @Doing = SUBSTRING(@Doing, 1, DATALENGTH(@Doing) - 1)
				--print @Doing
				EXEC dbo.WriteLog_UserLog @UserID = 862400, @Doing = @Doing
				SET @Doing = ''
			END
		END
		IF @Doing <> '' --for last round
		BEGIN
			SET @Doing = SUBSTRING(@Doing, 1, DATALENGTH(@Doing) - 1)
			--print @Doing
			EXEC dbo.WriteLog_UserLog @UserID = 862400, @Doing = @Doing
		END
	END
	DROP TABLE #TransIds
END
GO
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/