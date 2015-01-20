USE [bodb_AGE]
GO

/****** Object:  StoredProcedure [dbo].[Task_LimitLoss_Setting_TotalBalanceUpd_Job]    Script Date: 01/20/2015 04:01:21 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.Task_LimitLoss_Setting_TotalBalanceUpd_Job    Script Date: 6/27/2014 1:18:44 PM ******/
CREATE PROCEDURE [dbo].[Task_LimitLoss_Setting_TotalBalanceUpd_Job]
AS
/*
	Created: Elodie
	Date: 20140522
	Task : Update total balance
	DB: DBAGE/bodb_AGE

	Revisions:
		2014-06-20@Dom: Support Yesterday balance [Redmine: #17906]
	Parameter's explaination: 
		
*/
BEGIN
	

	DECLARE @BalanceCust TABLE (CustID INT, NewTotalBalance MONEY, YesterdayTotalBalance MONEY, NewLevelID TINYINT)
	DECLARE @Cust_tmp TABLE (srecommend INT, mrecommend INT, recommend INT, roleid TINYINT)
	DECLARE @MaxLevel TINYINT, @i TINYINT
	SELECT @i = min(LevelID), @MaxLevel = max(LevelID) FROM LimitLoss_ActionConfig WITH (NOLOCK)

	INSERT INTO @Cust_tmp (srecommend, mrecommend, recommend, roleid)
	SELECT c.srecommend, c.mrecommend, c.recommend, c.roleid
	FROM LimitLoss_Setting s WITH (NOLOCK)
		INNER JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON s.custid = c.custid

	INSERT INTO @BalanceCust (CustID, NewTotalBalance, YesterdayTotalBalance, NewLevelID)
	SELECT Balance.srecommend, 
	sum(Balance.superCash + Balance.masterCash + Balance.agentCash + Balance.memberCash)	AS TotalBalance, 
	sum(Balance.superCash + Balance.masterCash + Balance.agentCash + Balance.memberCash)
		-sum(case when TodayBalance.srecommend is null then 0 else TodayBalance.superCash + TodayBalance.masterCash + TodayBalance.agentCash + TodayBalance.memberCash end)	AS YesterdayTotalBalance, 
	0
	FROM
		(
			SELECT	b.srecommend,
					sum(ISNULL(case when b.custid=b.srecommend then winlost-actual_stake else swinlost+scomm-acomm end,0)) superCash,
					sum(ISNULL(case when b.custid=b.mrecommend then winlost-actual_stake else mwinlost+acomm-comm end,0)) masterCash,
					sum(ISNULL(case when b.custid=b.recommend  then winlost-actual_stake else awinlost+comm-playercomm end,0)) agentCash,
					sum(ISNULL(case when b.custid <> b.recommend and b.custid <> b.mrecommend and b.custid <> b.srecommend and ruben=1 then winlost-actual_stake+playercomm else 0 end,0)) memberCash
	
			FROM bodb02.dbo.bettrans b WITH(NOLOCK) 
				INNER JOIN @Cust_tmp t ON (b.srecommend = t.srecommend AND t.roleid = 4)
			GROUP BY b.srecommend
		)Balance
	LEFT JOIN 
		(
			SELECT b.srecommend,
					sum(ISNULL(swinlost+scomm-acomm,0)) superCash,
					sum(ISNULL(mwinlost+acomm-comm,0)) masterCash,
					sum(ISNULL(awinlost+comm-playercomm,0)) agentCash,
					sum(ISNULL(winlost-actual_stake+playercomm,0)) memberCash
	
			FROM bodb02.dbo.bettrans b WITH(NOLOCK) 
				INNER JOIN @Cust_tmp t ON (b.srecommend = t.srecommend AND t.roleid = 4)
			WHERE ruben = 1 and bettype < 19001 
				AND b.winlostdate >= convert(varchar(10), CURRENT_TIMESTAMP, 120)		
			GROUP BY b.srecommend
		) TodayBalance ON TodayBalance.srecommend = Balance.srecommend
	GROUP BY Balance.srecommend

	UNION ALL
	SELECT Balance.mrecommend, 
	sum(Balance.masterCash + Balance.agentCash + Balance.memberCash)	AS TotalBalance, 
	sum(Balance.masterCash + Balance.agentCash + Balance.memberCash)
		-sum(case when TodayBalance.mrecommend is null then 0 else TodayBalance.masterCash + TodayBalance.agentCash + TodayBalance.memberCash end)	AS YesterdayTotalBalance, 
	0
	FROM
		(
			SELECT	b.mrecommend,
					sum(ISNULL(case when b.custid=b.mrecommend then winlost-actual_stake else mwinlost+acomm-comm end,0)) masterCash,
					sum(ISNULL(case when b.custid=b.recommend  then winlost-actual_stake else awinlost+comm-playercomm end,0)) agentCash,
					sum(ISNULL(case when b.custid <> b.recommend and b.custid <> b.mrecommend and b.custid <> b.srecommend and ruben=1 then winlost-actual_stake+playercomm else 0 end,0)) memberCash
	
			FROM bodb02.dbo.bettrans b WITH(NOLOCK) 
				INNER JOIN @Cust_tmp t ON (b.srecommend = t.srecommend AND b.mrecommend = t.mrecommend AND t.roleid = 3)
			GROUP BY b.mrecommend
		)Balance
	LEFT JOIN 
		(
			SELECT	b.mrecommend,
					sum(ISNULL(mwinlost+acomm-comm,0)) masterCash,
					sum(ISNULL(awinlost+comm-playercomm,0)) agentCash,
					sum(ISNULL(winlost-actual_stake+playercomm,0)) memberCash
	
			FROM bodb02.dbo.bettrans b WITH(NOLOCK) 
				INNER JOIN @Cust_tmp t ON (b.srecommend = t.srecommend AND b.mrecommend = t.mrecommend AND t.roleid = 3)
			WHERE ruben = 1 and bettype < 19001 
				AND b.winlostdate >= convert(varchar(10), CURRENT_TIMESTAMP, 120)		
			GROUP BY b.mrecommend
		) TodayBalance ON TodayBalance.mrecommend = Balance.mrecommend
	GROUP BY Balance.mrecommend

	UNION ALL
	SELECT Balance.recommend, 
	sum(Balance.agentCash + Balance.memberCash)	AS TotalBalance, 
	sum(Balance.agentCash + Balance.memberCash)
		-sum(case when TodayBalance.recommend is null then 0 else TodayBalance.agentCash + TodayBalance.memberCash end)	AS YesterdayTotalBalance, 
	0
	FROM
		(
			SELECT	b.recommend,
					sum(ISNULL(case when b.custid=b.recommend  then winlost-actual_stake else awinlost+comm-playercomm end,0)) agentCash,
					sum(ISNULL(case when b.custid <> b.recommend and b.custid <> b.mrecommend and b.custid <> b.srecommend and ruben=1 then winlost-actual_stake+playercomm else 0 end,0)) memberCash
	
			FROM bodb02.dbo.bettrans b WITH(NOLOCK) 
				INNER JOIN @Cust_tmp t ON (b.srecommend = t.srecommend AND b.mrecommend = t.mrecommend AND b.recommend = t.recommend AND t.roleid = 2)
			GROUP BY b.recommend
	)Balance
	LEFT JOIN 
		(
			SELECT	b.recommend,
					sum(ISNULL(awinlost+comm-playercomm,0)) agentCash,
					sum(ISNULL(winlost-actual_stake+playercomm,0)) memberCash
	
			FROM bodb02.dbo.bettrans b WITH(NOLOCK) 
				INNER JOIN @Cust_tmp t ON (b.srecommend = t.srecommend AND b.mrecommend = t.mrecommend AND b.recommend = t.recommend AND t.roleid = 2)
			WHERE ruben = 1 and bettype < 19001 
				AND b.winlostdate >= convert(varchar(10), CURRENT_TIMESTAMP, 120)		
			GROUP BY b.srecommend, b.mrecommend, b.recommend
		)TodayBalance  ON TodayBalance.recommend = Balance.recommend
	GROUP BY Balance.recommend

	--INSERT INTO @BalanceCust (CustID, NewTotalBalance, NewLevelID)
	--SELECT t.srecommend, sum(superCash + masterCash + agentCash + memberCash)	AS TotalBalance, 0
	--FROM 
	--	#Balance_tmp b
	--		INNER JOIN @Cust_tmp t ON (b.srecommend = t.srecommend AND t.roleid = 4)
	--GROUP BY t.srecommend
	
	--UNION ALL
	--SELECT t.mrecommend, sum(superCash + masterCash + agentCash + memberCash)	AS TotalBalance, 0
	--FROM 
	--	#Balance_tmp b
	--		INNER JOIN @Cust_tmp t ON (b.srecommend = t.srecommend AND b.mrecommend = t.mrecommend AND t.roleid = 3)
	--GROUP BY t.mrecommend
	
	--UNION ALL	
	--SELECT t.recommend, sum(superCash + masterCash + agentCash + memberCash)	AS TotalBalance, 0
	--FROM 
	--	#Balance_tmp b
	--		INNER JOIN @Cust_tmp t ON (b.srecommend = t.srecommend AND b.mrecommend = t.mrecommend AND b.recommend = t.recommend AND t.roleid = 2)
	--GROUP BY t.recommend
	--SELECT * INTO #BalanceCust FROM @BalanceCust

	WHILE (@i<@MaxLevel)
	BEGIN
		UPDATE b
		SET NewLevelID = @i
		FROM @BalanceCust b
			INNER JOIN LimitLoss_Setting l ON b.CustID = l.CustID
		WHERE CAST((b.NewTotalBalance/l.MaxLoss*100) AS INT) >= (SELECT Value FROM LimitLoss_ActionConfig WITH (NOLOCK) WHERE LevelID = @i)
			AND CAST((b.NewTotalBalance/l.MaxLoss*100) AS INT) < (SELECT Value FROM LimitLoss_ActionConfig WITH (NOLOCK) WHERE LevelID = @i+1)

		SET @i = @i+1
	END

	UPDATE b
	SET NewLevelID = @MaxLevel
	FROM @BalanceCust b
		INNER JOIN LimitLoss_Setting l ON b.CustID = l.CustID
	WHERE CAST((b.NewTotalBalance/l.MaxLoss*100) AS INT) >= (SELECT Value FROM LimitLoss_ActionConfig WITH (NOLOCK) WHERE LevelID = @MaxLevel)

	UPDATE l
	SET l.TotalBalance = b.NewTotalBalance,
		l.YesterdayBalance = b.YesterdayTotalBalance,
		l.OldLevelID = CASE WHEN l.LevelID = b.NewLevelID THEN l.OldLevelID ELSE l.LevelID END,
		l.LevelID = b.NewLevelID
	FROM LimitLoss_Setting l WITH (ROWLOCK, UPDLOCK)
		INNER JOIN @BalanceCust b ON l.CustID = b.CustID
END


/*
select * from bodb02.dbo.custInfo where username='S42S'

select * from LimitLoss_Setting where CustID=1207541

select * from bodb02.dbo.bettrans where srecommend=1207541
*/

/*
SELECT b.*,
	 NewLevelID = CASE WHEN CAST((b.NewTotalBalance/l.MaxLoss*100) AS INT) BETWEEN 40 AND 49 THEN 1 
					WHEN CAST((b.NewTotalBalance/l.MaxLoss*100) AS INT) BETWEEN 50 AND 59 THEN 2
					WHEN CAST((b.NewTotalBalance/l.MaxLoss*100) AS INT) BETWEEN 60 AND 69 THEN 3 
					WHEN CAST((b.NewTotalBalance/l.MaxLoss*100) AS INT) BETWEEN 70 AND 79 THEN 4 
					WHEN CAST((b.NewTotalBalance/l.MaxLoss*100) AS INT) BETWEEN 80 AND 89 THEN 5 
					WHEN CAST((b.NewTotalBalance/l.MaxLoss*100) AS INT) >= 90 THEN 6 
					ELSE 0
				END,
	l.OldLevelID
FROM LimitLoss_Setting l
INNER JOIN #BalanceCust b ON l.CustID = b.CustID
*/
GO

GRANT VIEW DEFINITION ON [dbo].[Task_LimitLoss_Setting_TotalBalanceUpd_Job] TO [vnteam] AS [dbo]
GO


