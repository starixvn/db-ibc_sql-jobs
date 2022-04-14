/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0"></info>*/
/*
	Created by: 20210730@Kathy
	Task: gen data bettype 19999  [Redmine:#171422]
	DB: DBTRANS.BODB02
*/
USE bodb02
GO

DECLARE @AffectedList		VARCHAR(MAX)

DECLARE @tmpCustId TABLE (CustId INT, winlostdate SMALLDATETIME
	, awinlost MONEY, mwinlost MONEY, swinlost MONEY)

INSERT INTO @tmpCustId (CustId, winlostdate, awinlost, mwinlost, swinlost)
SELECT c.custid, c.winlostdate, c.awinlost, c.mwinlost, c.swinlost
FROM (
SELECT	custid, winlostdate, SUM(awinlost) AS awinlost, SUM(mwinlost) AS mwinlost, SUM(swinlost) AS swinlost
FROM	dbo.bettrans14
WHERE	winlostdate = '20220407'
		AND custid IN (18837488,23974945,30168744,40011569,42202578,47474540,52518637,54162657,55516507,62096042)
GROUP BY custid, winlostdate
UNION ALL
SELECT	custid, winlostdate, SUM(awinlost) AS awinlost, SUM(mwinlost) AS mwinlost, SUM(swinlost) AS swinlost
FROM	dbo.bettrans14
WHERE	winlostdate = '20220408'
		AND custid IN (30168744,42202578,45912718,47474540,50021041,51650537,53555037,53776755,53908035,57318581,61360767,61699783,62587483)
GROUP BY custid, winlostdate
UNION ALL
SELECT	custid, winlostdate, SUM(awinlost) AS awinlost, SUM(mwinlost) AS mwinlost, SUM(swinlost) AS swinlost
FROM	dbo.bettrans14
WHERE	winlostdate = '20220409'
		AND custid IN (16965747,25263083,38032756,42202578,45342970,47474540,53908035,54516731,55516507,55699707,57318581,62434789,62635432)
GROUP BY custid, winlostdate
UNION ALL
SELECT	custid, winlostdate, SUM(awinlost) AS awinlost, SUM(mwinlost) AS mwinlost, SUM(swinlost) AS swinlost
FROM	dbo.bettrans14
WHERE	winlostdate = '20220410'
		AND custid IN (22688054,24693145,30168744,42202578,46832797,50734164,51650537,55516507,58526136)
GROUP BY custid, winlostdate
) c

UPDATE  t WITH(ROWLOCK, UPDLOCK)
	SET AWinlost = c.awinlost
		,MWinlost = c.mwinlost
		,SWinlost = c.swinlost
FROM	dbo.Transfer t
	INNER JOIN @tmpCustId c
		ON t.CustId = c.CustId
WHERE	t.Bettype = 19999
		AND t.WinlostDate = c.winlostdate


SET @AffectedList = CAST((
	SELECT	CustId AS '@c'
			,WinlostDate AS '@w'
				
	FROM	@tmpCustId  
	GROUP BY CustId
			,WinlostDate
	FOR XML PATH('r'), ROOT('root'), TYPE
) AS VARCHAR(MAX))
	
-- insert routine task
EXEC dbo.TicketVoiding_Admin_Bet14_RoutineTask_Insert 
	@AffectedList = @AffectedList