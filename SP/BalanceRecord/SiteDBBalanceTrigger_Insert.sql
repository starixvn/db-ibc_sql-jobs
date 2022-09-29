/*<info serverAlias="DBBAH-bodb02" executers="" viewers="" isFunction="0"></info>*/  
ALTER PROCEDURE [dbo].[SiteDBBalanceTrigger_Insert] 
(
	@SiteDBAlias VARCHAR(100) = NULL
	,@VName VARCHAR(100) = NULL
)
AS
/*
    Created: 20220928@July
    Task: 
    DB: DBBAH/bodb02
    Revisions:
		- 20220928@July: scaleout project - Balance record [176932]
		
*/
BEGIN
	
	SET NOCOUNT ON

	DECLARE @sqlCMD NVARCHAR(MAX), @maxRowID BIGINT, @batchSize INT = 5000;

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

	SET @maxRowID = (SELECT CONVERT(BIGINT,VValue) FROM bodb02.dbo.SystemSettings WITH (NOLOCK) WHERE VName = @VName /*'BT_SiteDB01_Sync'*/)
	
	SET @sqlCMD = N'\
	SELECT rowID, custid, transid, bettype, actual_stake, winlost, playercomm, BalanceChanged, NewBalance, ActionDate, ActionID, Action, BTBalance, StatusId, MatchId, SettlementType, awinlost, mwinlost, swinlost, comm, acomm, scomm, modds 
	FROM OPENQUERY('+@SiteDBAlias+', ''\
	SELECT TOP('+CONVERT(VARCHAR(10), @batchSize)+') rowid, custid, transid, bettype, actual_stake, winlost, playercomm, BalanceChanged, NewBalance, ActionDate, ActionID, Action, BTBalance, StatusId, MatchId, SettlementType, awinlost, mwinlost, swinlost, comm, acomm, scomm, modds 
	FROM [bodb02].[dbo].[BalanceTrigger] WITH(NOLOCK) WHERE RowID > '+CONVERT(VARCHAR(20), @maxRowID)+'\
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
	WHERE VName = @VName --'BT_SiteDB01_Sync'
	
	DROP TABLE #tmpBalanceTrigger

END

