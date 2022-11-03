/*<info serverAlias="DBBAH-bodb02" executers="" viewers="" isFunction="0"></info>*/  
ALTER TRIGGER [dbo].[bettransLC_After_Insert]
ON [dbo].[bettransLC]
FOR INSERT
AS
/*
	Created: Joe@
	DB: DBBAH.bodb02
	Task: 
	Revision:
		- 20210309@Kathy: Allow null for bettype,actual_stake, winlost, playercomm [Redmine:#138552]
		- 20220912@Helen: scaleout project, exclude 'sitedb' data since it has been processed in sitedb already [176932]
		- 20221031@July: Change column BalanceChanged [176932]
*/
BEGIN

	-- DB05BK1 : not sync balance from DBTrans

	--PRINT GETDATE()
	INSERT INTO BalanceTrigger (
		custid, transid, bettype, 
		actual_stake, winlost, playercomm,
		BalanceChanged,
		ActionDate, ActionID, [Action],
		BTBalance)
	SELECT
		i.custid, transid, gameID, ISNULL(actual_stake,0), ISNULL(winlost,0), ISNULL(playercomm,0),
		CASE
		--WHEN IsSum = 0 AND statusID = 0 THEN -ISNULL(actual_stake,0)
		--WHEN IsSum = 0 AND statusID = 1 THEN ISNULL(winlost,0) - ISNULL(actual_stake,0) +ISNULL(playercomm,0)
		WHEN IsSum = 0  THEN ISNULL(winlost,0) - ISNULL(actual_stake,0) + ISNULL(playercomm,0)
		ELSE 0 END,
		current_timestamp,
		012, -- bettransLC insert
		--'Insert ' + CASE WHEN bettype < 19001 then 'Bet' ELSE 'Transfer' END + ', status ' + [status]
		-- my suggested pattern (Joe)
		'LC (IsSUM : ' + CAST(IsSUM AS varchar(50)) + ') inserted as ' + [status],
		NULL Balance
		--v.Balance
	FROM
		inserted i
		--INNER JOIN DBTRANS.bodb02.dbo.v_BalanceTable v ON i.custid = v.custid
	WHERE
		i.custid <> recommend AND
		i.custid <> mrecommend AND
		i.custid <> srecommend
		AND i.SiteDBGroupID = 0
	ORDER BY
		i.transid
END


GO


