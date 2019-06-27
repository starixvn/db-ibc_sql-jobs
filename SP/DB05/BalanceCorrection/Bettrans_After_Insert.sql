USE [bodb02]
GO

CREATE TRIGGER [dbo].[Bettrans_After_Insert]
ON [dbo].[bettrans]
FOR INSERT
AS
/*
	Created: Joe@
	DB: DB05.BODB02
	Task: 
	Revision:
		- 20190611@Patrick: CN88 integration
*/

BEGIN

	DECLARE @DelaySeconds INT
	SELECT @DelaySeconds = VValue
		FROM dbo.SystemSettings WITH (NOLOCK)
		WHERE VName = N'BetReplication_Delay'

	--if this record belong to CN88 member then skip get data from v_BalanceTable.
	DECLARE @__IsCN88 BIT
	IF EXISTS (SELECT TOP 1 1 FROM inserted d 
				WHERE EXISTS (
					SELECT TOP 1 1 FROM dbo.CS_CustSuper c WITH(NOLOCK) 
					WHERE d.srecommend =  c.CustId))
	BEGIN
		SET @__IsCN88 = 1
	END
	ELSE
	BEGIN
		SET @__IsCN88 = 0
	END

	IF @DelaySeconds < 60 AND @__IsCN88 = 0
		--PRINT GETDATE()
		INSERT INTO BalanceTrigger (
			custid, transid, bettype, 
			actual_stake, winlost, playercomm,
			BalanceChanged,
			ActionDate, ActionID, [Action],
			BTBalance)
		SELECT
			i.custid, transid, bettype, isnull(actual_stake,0), isnull(winlost,0), playercomm,
			CASE bettype 
			WHEN 19999 THEN 0
			WHEN 20000 THEN 0
			ELSE isnull(winlost-actual_stake+playercomm,0) END,
			current_timestamp,
			CASE
			WHEN bettype < 19001 THEN 010 -- bet insert
			WHEN bettype > 20000 THEN 110 -- transfer insert
			WHEN bettype = 19999 THEN 100 -- SUM insert
			WHEN bettype = 20000 THEN 255 -- Balance insert
			ELSE 0 END,
			--'Insert ' + CASE WHEN bettype < 19001 then 'Bet' ELSE 'Transfer' END + ', status ' + [status]
			-- my suggested pattern (Joe)
			CASE
			WHEN bettype < 19001 THEN 'Bet'
			WHEN bettype > 20000 THEN 'Transfer'
			ELSE [status] + ' ' + CONVERT(varchar(10), i.winlostdate, 120)
			END + ' inserted' +
			CASE
			WHEN statusID > 1 AND refno NOT IN (100000000000,260000000000,0) THEN ' as ' + [status] + ' (' + CAST(refno AS varchar(50)) + ')'
			WHEN bettype < 19001 THEN ' as ' + [status]
			WHEN bettype > 20000 THEN ' as ' + [status] + ' (' + CAST(refno AS varchar(50)) + ')'
			ELSE '' END,
			--0 Balance
			v.Balance
		FROM
			inserted i with (nolock)
			INNER JOIN DBTRANS.bodb02.dbo.v_BalanceTable v ON i.custid = v.custid
		WHERE
			i.custid <> recommend AND
			i.custid <> mrecommend AND
			i.custid <> srecommend
			--AND custid = 2211693
			--AND currency IN (3, 5, 20)
		ORDER BY
			i.transid
	ELSE -- delay too high, no need to get balance from DBTrans to see, as it's useless
		INSERT INTO BalanceTrigger (
			custid, transid, bettype, 
			actual_stake, winlost, playercomm,
			BalanceChanged,
			ActionDate, ActionID, [Action],
			BTBalance)
		SELECT
			i.custid, transid, bettype, isnull(actual_stake,0), isnull(winlost,0), playercomm,
			CASE bettype 
			WHEN 19999 THEN 0
			WHEN 20000 THEN 0
			ELSE isnull(winlost-actual_stake+playercomm,0) END,
			current_timestamp,
			CASE
			WHEN bettype < 19001 THEN 010 -- bet insert
			WHEN bettype > 20000 THEN 110 -- transfer insert
			WHEN bettype = 19999 THEN 100 -- SUM insert
			WHEN bettype = 20000 THEN 255 -- Balance insert
			ELSE 0 END,
			--'Insert ' + CASE WHEN bettype < 19001 then 'Bet' ELSE 'Transfer' END + ', status ' + [status]
			-- my suggested pattern (Joe)
			CASE
			WHEN bettype < 19001 THEN 'Bet'
			WHEN bettype > 20000 THEN 'Transfer'
			ELSE [status] + ' ' + CONVERT(varchar(10), i.winlostdate, 120)
			END + ' inserted' +
			CASE
			WHEN statusID > 1 AND refno NOT IN (100000000000,260000000000,0) THEN ' as ' + [status] + ' (' + CAST(refno AS varchar(50)) + ')'
			WHEN bettype < 19001 THEN ' as ' + [status]
			WHEN bettype > 20000 THEN ' as ' + [status] + ' (' + CAST(refno AS varchar(50)) + ')'
			ELSE '' END,
			--0 Balance
			NULL
		FROM
			inserted i with (nolock)
			--INNER JOIN DBTRANS.bodb02.dbo.v_BalanceTable v ON i.custid = v.custid
		WHERE
			i.custid <> recommend AND
			i.custid <> mrecommend AND
			i.custid <> srecommend
			--AND custid = 2211693
			--AND currency IN (3, 5, 20)
		ORDER BY
			i.transid
	/*
		INSERT INTO dbo.RowInsert_Bettrans (custid, transid, matchid, bettype, winlostdate, InsertTime, winlost, actual_stake, playercomm, statusID)
		SELECT custid, transid, matchid, bettype, winlostdate, SYSDATETIME(), winlost, actual_stake, playercomm, statusID
		FROM inserted
		WHERE 
			custid <> recommend AND
			custid <> mrecommend AND
			custid <> srecommend AND
			bettype IN (19999,20000)
	*/	

END
GO
