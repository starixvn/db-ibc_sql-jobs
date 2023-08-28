/*<info serverAlias="DBCUST-custdb" executers="repl_ap" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Repl_GetSportBettypeSettingMatrix]
	@start DATETIME2,
	@count INT,
	@back_fix INT = 0
AS
/*
	Task: In-House
	Revision:
		-- 20230817@Patrick: create SP for in-house replication use [Redmine:#189389]
*/

BEGIN
	SET NOCOUNT ON;

	DECLARE @__time_start DATETIME2 = DATEADD(MILLISECOND, -@back_fix, @start);
	DECLARE @__time_end DATETIME2;
	DECLARE @__time_upperbound DATETIME2 = DATEADD(MILLISECOND, -@back_fix, SYSDATETIME());

	SET LOCK_TIMEOUT 1000;

	WITH CTE_Timestamp ([RepUpdateTime]) AS (
		SELECT TOP (@count) [RepUpdateTime]
		FROM [dbo].[SportBettypeSettingMatrix] WITH (NOLOCK, INDEX = IX_SportBettypeSettingMatrix_RepUpdateTime)
		WHERE [RepUpdateTime] > @start AND [RepUpdateTime] < @__time_upperbound
		ORDER BY [RepUpdateTime]
	)
	SELECT @__time_end = ISNULL(MAX([RepUpdateTime]), @start) FROM CTE_Timestamp;

	SET LOCK_TIMEOUT -1;

	IF @__time_end > @start
	BEGIN
		SELECT [SportType]
				,[BetType]
				,[isLicensee]
				,[isLive]
				,[Site]
				,[isActive]
				,[SportTypeRefPT]
				,[BetTypeRefPT]
				,[isLivePT]
				,[TablePT]
				,[SportTypeRefComm]
				,[BetTypeRefComm]
				,[TableComm]
				,[SportTypeRefBetSetting]
				,[BetTypeRefBetSetting]
				,[TableBetSetting]
				,[IsLiveComm]
				,[IsLiveBetSetting]
				,[TableBettrans]
				,[RealProductId]
				,[SporttypeRefWinlossLimit]
				,[BettypeRefWinlossLimit]
				,[ProductID]
				,[isDeleted]
				,[RepUpdateTime]
				,SYSDATETIME() AS [_FetchedTime]
		FROM [dbo].[SportBettypeSettingMatrix]  WITH (NOLOCK, INDEX = IX_SportBettypeSettingMatrix_RepUpdateTime)
		WHERE [RepUpdateTime] > @__time_start AND [RepUpdateTime] <= @__time_end
		ORDER BY [RepUpdateTime];
	END;
END
GO
