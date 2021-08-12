/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_BalanceUp_Cal_Balance]
AS
/*
	Task: Task_BalanceUp_Cal_Balance
	Location: DBTXN.bodb02

	Revision:
		202010514@Patrick: Revise Movebet flow to support transfer 247 - Redmine: [#149927]
*/
SET NOCOUNT ON
Declare @fdate datetime

SELECT TOP(1) @fdate = DATEADD(day, 7, winlostdate)
FROM dbo.bettrans with (nolock)
WHERE matchid = 0 and bettype = 20000
ORDER BY transid

PRINT '@fdate = ' + CONVERT(varchar(10), @fdate, 120)

-- clean up table on Monday (morning) = Sunday (server time)
IF DATEPART(dw, CURRENT_TIMESTAMP) = 1 
	TRUNCATE TABLE BalanceTable_tmp_cal

DECLARE @__movebetdate SMALLDATETIME
EXEC dbo.NAP_Admin_GetMovebetDate @MovebetDate = @__movebetdate OUTPUT

INSERT INTO dbo.BalanceTable_tmp_cal
SELECT
	DATEPART(dw, CURRENT_TIMESTAMP) dow,
	CASE custid
	WHEN  recommend THEN 2
	WHEN mrecommend THEN 3
	WHEN srecommend THEN 4
	ELSE 1 END roleid, 
	custid, recommend, mrecommend, srecommend,
	SUM(CASE WHEN custid NOT IN (recommend, mrecommend, srecommend) THEN winlost-actual_stake + playercomm ELSE 0 END) amt1,
	0, --SUM(CASE WHEN custid NOT IN (recommend, mrecommend, srecommend) THEN 1 ELSE 0 END) tcnt1,
	SUM(CASE WHEN custid =  recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END) amt2,
	0, --SUM(CASE WHEN custid =  recommend THEN 1 ELSE 0 END) tcnt2,
	SUM(CASE WHEN custid = mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END) amt3,
	0, --SUM(CASE WHEN custid = mrecommend THEN 1 ELSE 0 END) tcnt3,
	SUM(CASE WHEN custid = srecommend THEN winlost-actual_stake ELSE swinlost+scomm-acomm END) amt4,
	0  --SUM(CASE WHEN custid = srecommend THEN 1 ELSE 0 END) tcnt4
FROM dbo.bettrans with (nolock)
WHERE ruben = 1
	AND winlostdate < @fdate
	AND 1 = CASE WHEN bettype = 19999 AND winlostdate > @__movebetdate THEN 0 --> new sum
				 WHEN bettype < 19999 AND winlostdate <= @__movebetdate THEN 0 --> old bet
				 ELSE 1 END
GROUP BY
	custid, recommend, mrecommend, srecommend

GO
