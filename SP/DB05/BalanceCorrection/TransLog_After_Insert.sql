USE [bodb02]
GO

CREATE TRIGGER [dbo].[TransLog_After_Insert]
ON [dbo].[translog]
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

	IF @__IsCN88 = 0
	BEGIN
		--PRINT GETDATE()
		INSERT INTO BalanceTrigger (
			custid, transid, bettype, 
			actual_stake, winlost, playercomm,
			BalanceChanged,
			ActionDate, ActionID, [Action],
			BTBalance)
		SELECT
			i.custid, translogid, gameID, actual_stake, 0, 0,
			CASE statusID
			WHEN 0 THEN -actual_stake
			ELSE 0 END,
			current_timestamp,
			011, -- TransLog insert
			--'Insert ' + CASE WHEN bettype < 19001 then 'Bet' ELSE 'Transfer' END + ', status ' + [status]
			-- my suggested pattern (Joe)
			'TransLog inserted as ' + [status],
			--0 Balance
			v.Balance
		FROM
			inserted i
			INNER JOIN DBTRANS.bodb02.dbo.v_BalanceTable v ON i.custid = v.custid
		WHERE
			i.custid <> recommend AND
			i.custid <> mrecommend AND
			i.custid <> srecommend
			--AND custid = 2211693
			--AND currency IN (3, 5, 20)
		ORDER BY
			i.translogid
	END
	ELSE
	BEGIN
		INSERT INTO BalanceTrigger (
			custid, transid, bettype, 
			actual_stake, winlost, playercomm,
			BalanceChanged,
			ActionDate, ActionID, [Action],
			BTBalance)
		SELECT
			i.custid, translogid, gameID, actual_stake, 0, 0,
			CASE statusID
			WHEN 0 THEN -actual_stake
			ELSE 0 END,
			current_timestamp,
			011, -- TransLog insert
			--'Insert ' + CASE WHEN bettype < 19001 then 'Bet' ELSE 'Transfer' END + ', status ' + [status]
			-- my suggested pattern (Joe)
			'TransLog inserted as ' + [status],
			--0 Balance
			NULL AS Balance
		FROM
			inserted i
			--INNER JOIN DBTRANS.bodb02.dbo.v_BalanceTable v ON i.custid = v.custid
		WHERE
			i.custid <> recommend AND
			i.custid <> mrecommend AND
			i.custid <> srecommend
			--AND custid = 2211693
			--AND currency IN (3, 5, 20)
		ORDER BY
			i.translogid
	END
END


GO
