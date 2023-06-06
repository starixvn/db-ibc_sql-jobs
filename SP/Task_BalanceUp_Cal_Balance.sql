/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_BalanceUp_Cal_Balance]
AS
/*
	Task: Task_BalanceUp_Cal_Balance
	Location: DBTXN.bodb02

	Revision:
		- 202010514@Patrick: Revise Movebet flow to support transfer 247 - Redmine: [#149927]
		- 20211214@Kathy: Separate Transfer Tickets[Redmine:#164197]
		- 20230104@Patrick: Balance-Up support transfer 247 [RedmineID: #173554]
*/
SET NOCOUNT ON
DECLARE @fdate SMALLDATETIME

--get current balanceup date
EXEC dbo.NAP_Admin_GetBalanceUpDate @BalanceUpDate = @fdate OUTPUT

--next balanceup date
SET @fdate = DATEADD(DAY, 7, @fdate)

PRINT '@fdate = ' + CONVERT(varchar(10), @fdate, 120)

-- clean up table on Monday (morning) = Sunday (server time)
IF DATEPART(dw, CURRENT_TIMESTAMP) = 1 
	TRUNCATE TABLE BalanceTable_tmp_cal

DECLARE @__movebetdate SMALLDATETIME
EXEC dbo.NAP_Admin_GetMovebetDate @MovebetDate = @__movebetdate OUTPUT

INSERT INTO dbo.BalanceTable_tmp_cal
SELECT dow, roleid, custid, recommend, mrecommend, srecommend, SUM(amt1), SUM(tcnt1), SUM(amt2), SUM(tcnt2), SUM(amt3), SUM(tcnt3), SUM(amt4), SUM(tcnt4)
FROM (
	SELECT
		DATEPART(dw, CURRENT_TIMESTAMP) dow,
		CASE custid
		WHEN  recommend THEN 2
		WHEN mrecommend THEN 3
		WHEN srecommend THEN 4
		ELSE 1 END roleid, 
		custid, recommend, mrecommend, srecommend,
		SUM(CASE WHEN custid NOT IN (recommend, mrecommend, srecommend) THEN winlost-actual_stake + playercomm ELSE 0 END) amt1,
		0 AS tcnt1, --SUM(CASE WHEN custid NOT IN (recommend, mrecommend, srecommend) THEN 1 ELSE 0 END) tcnt1,
		SUM(CASE WHEN custid =  recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END) amt2,
		0 AS tcnt2, --SUM(CASE WHEN custid =  recommend THEN 1 ELSE 0 END) tcnt2,
		SUM(CASE WHEN custid = mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END) amt3,
		0 AS tcnt3, --SUM(CASE WHEN custid = mrecommend THEN 1 ELSE 0 END) tcnt3,
		SUM(CASE WHEN custid = srecommend THEN winlost-actual_stake ELSE swinlost+scomm-acomm END) amt4,
		0 AS tcnt4  --SUM(CASE WHEN custid = srecommend THEN 1 ELSE 0 END) tcnt4
	FROM dbo.bettrans with (nolock)
	WHERE ruben = 1
		AND winlostdate < @fdate
		AND 1 = CASE 
					WHEN bettype > 19999 THEN 0 --> get data from transfer table
					WHEN bettype < 19999 AND winlostdate <= @__movebetdate THEN 0 --> old bet
					ELSE 1
				END
	GROUP BY
		custid, recommend, mrecommend, srecommend
	UNION ALL
	SELECT
		DATEPART(dw, CURRENT_TIMESTAMP) dow,
		CASE custid
		WHEN  recommend THEN 2
		WHEN mrecommend THEN 3
		WHEN srecommend THEN 4
		ELSE 1 END roleid, 
		custid, recommend, mrecommend, srecommend,
		SUM(CASE WHEN custid NOT IN (recommend, mrecommend, srecommend) THEN winlost-actual_stake + playercomm ELSE 0 END) amt1,
		0 AS tcnt1, --SUM(CASE WHEN custid NOT IN (recommend, mrecommend, srecommend) THEN 1 ELSE 0 END) tcnt1,
		SUM(CASE WHEN custid =  recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END) amt2,
		0 AS tcnt2, --SUM(CASE WHEN custid =  recommend THEN 1 ELSE 0 END) tcnt2,
		SUM(CASE WHEN custid = mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END) amt3,
		0 AS tcnt3, --SUM(CASE WHEN custid = mrecommend THEN 1 ELSE 0 END) tcnt3,
		SUM(CASE WHEN custid = srecommend THEN winlost-actual_stake ELSE swinlost+scomm-acomm END) amt4,
		0 AS tcnt4  --SUM(CASE WHEN custid = srecommend THEN 1 ELSE 0 END) tcnt4
	FROM dbo.Transfer with (nolock)
	WHERE winlostdate < @fdate
		AND 1 = CASE 
					WHEN bettype = 19999 AND winlostdate > @__movebetdate THEN 0 --> new sum
					ELSE 1 END
	GROUP BY
		custid, recommend, mrecommend, srecommend
) t
GROUP BY dow, roleid, custid, recommend, mrecommend, srecommend

GO
