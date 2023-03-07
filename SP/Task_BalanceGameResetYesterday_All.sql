/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_BalanceGameResetYesterday_All] 
AS
/*
		Created: 20200309@Eden	
		Task: reset yesterday balance for All product 
		DB: DBTRANS.BODB02
		
		Revisions:
			- 20200309@Eden: Initial Version [#122743]
			- 20220110@Eden: Saba Casino use DCS Setting [RedmineID: #164280]
			- 20220714@Johnson: Declare structure for temp table [RedmineID: #174035]
			- 20221121@Eden: Unify RNG Lottery Customer Settings [RedmineID: #180640]

		Parameters Explanation:	
*/
----Reset yesterday balance for Non-DCS Products
--EXEC dbo.Task_BalanceGameResetYesterday @sporttype = 255, @bettype = 1701 -- Gold Deluxe
--EXEC dbo.Task_BalanceGameResetYesterday @sporttype = 208, @bettype = 2101 -- RNG Casino

--Reset yesterday balance for DCS Products
DECLARE @SportType SMALLINT , @Bettype SMALLINT
CREATE TABLE #SportBettypeDCS(SportType SMALLINT,Bettype SMALLINT,IsProcessed BIT)

CREATE TABLE #ProductSettingDetail(
		[SportType] [smallint],
		[BetType] [smallint]
)

INSERT INTO #ProductSettingDetail(SportType,BetType)
SELECT SportType,bettype 
FROM OPENQUERY (DBCUST, 'SELECT SportType,bettype 
						FROM CUSTDB.dbo.ProductSettingDetail WITH(NOLOCK) 
						WHERE SettingType IN (6,12) AND SettingStatus <> 2
						UNION 
						SELECT SportType,bettype 
						FROM CUSTDB.dbo.ProductSettingDetail_UAT WITH(NOLOCK) 
						WHERE SettingType IN (6,12) AND SettingStatus <> 2
						UNION 
						SELECT mt.SportType,mt.bettype 
						FROM CUSTDB.dbo.ProductSettingDetail t WITH(NOLOCK) 
							INNER JOIN CUSTDB.dbo.SportBettypeSettingMatrix mt WITH(NOLOCK)  
								ON t.SportType = mt.SporttypeRefWinlossLimit
								AND t.BetType = mt.BettypeRefWinlossLimit
								AND mt.isLicensee = 0 AND mt.Site = ''ALL''
						WHERE t.SettingType IN (22) AND SettingStatus <> 2
						UNION 
						SELECT mt.SportType,mt.bettype 
						FROM CUSTDB.dbo.ProductSettingDetail_UAT t WITH(NOLOCK) 
							INNER JOIN CUSTDB.dbo.SportBettypeSettingMatrix mt WITH(NOLOCK)  
								ON t.SportType = mt.SporttypeRefWinlossLimit
								AND t.BetType = mt.BettypeRefWinlossLimit
								AND mt.isLicensee = 0 AND mt.Site = ''ALL''
						WHERE t.SettingType IN (22) AND SettingStatus <> 2 '
				)


INSERT INTO #SportBettypeDCS(SportType,Bettype,IsProcessed)
SELECT DISTINCT b.SportType,b.BetType,CAST(0 AS BIT) AS IsProcessed
FROM dbo.WinLimit_ProductOffer a WITH(NOLOCK) 
	INNER JOIN  #ProductSettingDetail b WITH(NOLOCK) 
		ON a.BetType = b.bettype
WHERE a.isActive_SMA = 1

WHILE 1 = 1
BEGIN
	UPDATE TOP (1) #SportBettypeDCS
	SET @Bettype = Bettype
		,@SportType = SportType
		,IsProcessed = 1
	WHERE IsProcessed = 0

	IF @@ROWCOUNT = 0
		BREAK;

	EXEC dbo.Task_BalanceGameResetYesterday @sporttype = @SportType, @bettype = @Bettype
END
GO
