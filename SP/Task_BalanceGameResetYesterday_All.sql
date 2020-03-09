/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_BalanceGameResetYesterday_All] 
AS
/*
		Created: 20200309@Eden	
		Task: reset yesterday balance for All product 
		DB: DBTRANS.BODB02
		
		Revisions:
			- 20200309@Eden: Initial Version []

		Parameters Explanation:	
*/
--Reset yesterday balance for Non-DCS Products
EXEC dbo.Task_BalanceGameResetYesterday @sporttype = 255, @bettype = 1701 -- Gold Deluxe
EXEC dbo.Task_BalanceGameResetYesterday @sporttype = 208, @bettype = 2101 -- RNG Casino
EXEC dbo.Task_BalanceGameResetYesterday @sporttype = 219, @bettype = 1011 -- Fishing World

--Reset yesterday balance for DCS Products
DECLARE @SportType SMALLINT , @Bettype SMALLINT

SELECT DISTINCT b.SportType,b.BetType,CAST(0 AS BIT) AS IsProcessed
INTO #SportBettypeDCS
FROM dbo.WinLimit_ProductOffer a WITH(NOLOCK) 
	INNER JOIN  DBCUST.CUSTDB.dbo.ProductSettingDetail b WITH(NOLOCK) 
		ON b.SettingType IN (6,12) AND b.SettingStatus <> 2
		AND a.BetType = b.bettype
WHERE a.isActive_SMA = 1

WHILE 1 = 1
BEGIN
	UPDATE #SportBettypeDCS
	SET @Bettype = @Bettype
		,@SportType = SportType
		,IsProcessed = 1
	WHERE IsProcessed = 0

	IF @@ROWCOUNT = 0
		BREAK;

	EXEC dbo.Task_BalanceGameResetYesterday @sporttype = @SportType, @bettype = @Bettype
END
GO
