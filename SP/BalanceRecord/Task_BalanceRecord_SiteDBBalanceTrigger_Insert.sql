/*<info serverAlias="DBBAH-bodb02" executers="" viewers="" isFunction="0"></info>*/  
ALTER PROCEDURE [dbo].[Task_BalanceRecord_SiteDBBalanceTrigger_Insert] 
AS
/*
    Created: 20220913@Helen
    Task: 
    DB: DBBAH/bodb02
    Revisions:
		- 20220912@Helen: scaleout project [176932]
		
*/
BEGIN
	
	SET NOCOUNT ON

	DECLARE @sqlCMD NVARCHAR(MAX), @maxRowID BIGINT, @siteDBAlias VARCHAR(100)='DBSIG01', @batchSize INT = 5000;

	CREATE TABLE #tmpBalanceTrigger(
		[RowID] [bigint] NOT NULL,
		[custid] [int] NOT NULL,
		[transid] [bigint] NOT NULL,
		[bettype] [smallint] NOT NULL,
		[actual_stake] [money] NOT NULL,
		[winlost] [money] NOT NULL,
		[playercomm] [money] NOT NULL,
		[BalanceChanged] [money] NOT NULL,
		[NewBalance] [money] NULL,
		[ActionDate] [datetime] NOT NULL,
		[ActionID] [tinyint] NULL,
		[Action] [varchar](200) NOT NULL,
		[BTBalance] [money] NULL,
		[StatusId] [tinyint] NULL,
		[MatchId] [int] NULL,
		[SettlementType] [tinyint] NULL,
		[awinlost] [money] NULL,
		[mwinlost] [money] NULL,
		[swinlost] [money] NULL,
		[comm] [money] NULL,
		[acomm] [money] NULL,
		[scomm] [money] NULL,
		[modds] [smallmoney] NULL
	)

	SET @maxRowID = (SELECT CONVERT(BIGINT,VValue) FROM bodb02.dbo.SystemSettings WITH (NOLOCK) WHERE VName = 'BT_SiteDB01_Sync')
	
	SET @sqlCMD = N'\
	SELECT rowID, custid, transid, bettype, actual_stake, winlost, playercomm, BalanceChanged, NewBalance, ActionDate, ActionID, Action, BTBalance, StatusId, MatchId, SettlementType, awinlost, mwinlost, swinlost, comm, acomm, scomm, modds 
	FROM OPENQUERY('+@siteDBAlias+', ''\
	SELECT TOP('+CONVERT(VARCHAR(10), @batchSize)+') rowid, custid, transid, bettype, actual_stake, winlost, playercomm, BalanceChanged, NewBalance, ActionDate, ActionID, Action, BTBalance, StatusId, MatchId, SettlementType, awinlost, mwinlost, swinlost, comm, acomm, scomm, modds 
	FROM [bodb02].[dbo].[BalanceTrigger] WITH(NOLOCK) WHERE RowID > '+CONVERT(VARCHAR(10), @maxRowID)+'\
	'')';

	--debug
	--PRINT @sqlCMD
	
	INSERT INTO #tmpBalanceTrigger (rowID, custid, transid, bettype, actual_stake, winlost, playercomm, BalanceChanged, NewBalance, ActionDate, ActionID, Action, BTBalance, StatusId, MatchId, SettlementType, awinlost, mwinlost, swinlost, comm, acomm, scomm, modds)
	EXEC sp_executesql @sqlCMD

	SET @maxRowID = (SELECT MAX(rowID) FROM #tmpBalanceTrigger)

	IF @maxRowID IS NULL
		RETURN

	INSERT INTO [bodb02].[dbo].[BalanceTrigger] (custid, transid, bettype, actual_stake, winlost, playercomm, BalanceChanged, NewBalance, ActionDate, ActionID, Action, BTBalance, StatusId, MatchId, SettlementType, awinlost, mwinlost, swinlost, comm, acomm, scomm, modds)
	SELECT custid, transid, bettype, actual_stake, winlost, playercomm, BalanceChanged, NewBalance, ActionDate, ActionID, Action, BTBalance, StatusId, MatchId, SettlementType, awinlost, mwinlost, swinlost, comm, acomm, scomm, modds
	FROM #tmpBalanceTrigger
	ORDER BY RowID

	-- get maxRowID
	UPDATE s
		SET VValue = CONVERT(VARCHAR(20),@maxRowID)
	FROM bodb02.dbo.SystemSettings s WITH (ROWLOCK,UPDLOCK)
	WHERE VName = 'BT_SiteDB01_Sync'

	DROP TABLE #tmpBalanceTrigger

END

