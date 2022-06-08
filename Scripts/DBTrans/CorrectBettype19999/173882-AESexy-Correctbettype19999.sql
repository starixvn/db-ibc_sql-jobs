/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0"></info>*/
/*
	Created by: 20220608@Helen
	Task: update data bettype 19999 - AE Sexy - correct data for the ticket 115497901894  [Redmine:#173882]
	DB: DBTRANS.BODB02
*/
USE bodb02
GO

DECLARE @AffectedList		VARCHAR(MAX)
DECLARE @tmpCustId TABLE (CustId INT, winlostdate SMALLDATETIME
	, stake MONEY, actual_stake MONEY
	, winlost MONEY, awinlost MONEY, mwinlost MONEY, swinlost MONEY
	, playercomm MONEY, comm MONEY, acomm MONEY,scomm MONEY)

INSERT INTO @tmpCustId (CustId,winlostdate
						,stake,actual_stake
						,winlost,awinlost,mwinlost,swinlost
						,playercomm,comm,acomm,scomm)
SELECT	custid, winlostdate
		, SUM(stake) stake, SUM(actual_stake) actual_stake
		, SUM(winlost) winlost, SUM(awinlost) awinlost, SUM(mwinlost) mwinlost, SUM(swinlost) swinlost
		, SUM(playercomm) playercomm, SUM(comm) comm, SUM(acomm) acomm, SUM(scomm) scomm
FROM	dbo.bettrans14
WHERE	winlostdate = '2022-06-01'
		AND custid = 52210028
GROUP BY custid, winlostdate

----------------- UPDATE BETTYPE 19999 ----------------------
UPDATE  t WITH(ROWLOCK, UPDLOCK)
	SET stake = c.stake, actual_stake = c.actual_stake
		, winlost = c.winlost, awinlost = c.awinlost, mwinlost = c.mwinlost,  swinlost = c.swinlost
		, playercomm = c.playercomm, comm = c.comm, acomm = c.acomm,  scomm = c.scomm
FROM	dbo.Transfer t
	INNER JOIN @tmpCustId c
		ON t.CustId = c.CustId
WHERE	t.Bettype = 19999
		AND t.WinlostDate = c.winlostdate

---------------------- insert routine task -------------------
SET @AffectedList = CAST((
	SELECT	CustId AS '@c'
			,WinlostDate AS '@w'
				
	FROM	@tmpCustId  
	GROUP BY CustId
			,WinlostDate
	FOR XML PATH('r'), ROOT('root'), TYPE
) AS VARCHAR(MAX))
	
EXEC dbo.TicketVoiding_Admin_Bet14_RoutineTask_Insert 
	@AffectedList = @AffectedList