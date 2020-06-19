/*<info serverAlias="DBSUM-bodb_Summary" executers="" viewers="" isFunction="0" isNested="1"></info>*/

CREATE PROCEDURE [dbo].[Task_DailySum_Winloss_Extra]
	@WinlostDate SMALLDATETIME
AS
/*
	Created: 20200618@Malcolm
	Task: SP Gen data for Task_DailySum_Winloss_Extra [Redmine: #135593]
	DB: DBSUM.bodb_Summary
	
	Revisions:
		- 20200618@Malcolm: Initialize SP [RedmineID: #135593]
 
	Param's Explanation:
*/

BEGIN
	CREATE TABLE #Bettype (typeID SMALLINT)

	INSERT INTO #Bettype
	(
		typeID
	)
	SELECT DISTINCT BetType
	FROM bodb02.dbo.SportBettypeMatrix m WITH(NOLOCK)
	WHERE ProductID = 46

	CREATE TABLE #Sum_Winloss_Extra 
	(
		WinlostDate		DATETIME,
		CustId			INT,
		ProductId		SMALLINT,
		Bettype			SMALLINT,
		RoleID			INT,
		Recommend		INT,
		MRecommend		INT,
		SRecommend		INT,
		BetCount		INT,
		Turnover		MONEY,
		NetTurnover		MONEY,
		TunroverNoDraw	MONEY,
		WinLoss			MONEY,
		AgWinLoss		MONEY,
		MAgWinLoss		MONEY,
		SAgWinLoss		MONEY,
		ExtraWinloss	MONEY,
		PlayerComm		MONEY,
		AgComm			MONEY,
		MAgComm			MONEY,
		SAgComm			MONEY,
		ExtraComm		MONEY,
		GrossComm		MONEY
	)
	-- for member , roleid = 1
	INSERT INTO #Sum_Winloss_Extra
	(
		WinlostDate,
		CustId,
		ProductId,
		Bettype,
		RoleID,
		Recommend,
		MRecommend,
		SRecommend,
		BetCount,
		Turnover,
		NetTurnover,
		TunroverNoDraw,
		WinLoss,
		AgWinLoss,		
		MAgWinLoss,
		SAgWinLoss,
		ExtraWinloss,
		PlayerComm,
		AgComm,
		MAgComm,
		SAgComm,
		ExtraComm,
		GrossComm
	)
	SELECT @WinlostDate, 1,
		
		
	FROM bodb02.dbo.bettrans bt WITH(NOLOCK)
	WHERE bt.winlostdate = @WinlostDate 
		AND bt.statusID NOT IN (0,1,102,101,103)
		AND bt.bettype < 19000


END