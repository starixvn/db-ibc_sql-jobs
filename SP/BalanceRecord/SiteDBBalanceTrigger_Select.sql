/*<info serverAlias="DBSIG-bodb02" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/  
ALTER PROCEDURE [dbo].[SiteDBBalanceTrigger_Select] 
(
	@ServerName VARCHAR(255)
)
AS
/*
    Created: 20220928@July
    Task: 
    DB: DBBAH/bodb02
    Revisions:
		- 20220928@July: scaleout project - Balance record [176932]
		- 20221010@July: Dynamic - Order by RowID & waitfor delay [176932]
		- 20221031@July: BatchSize = 2000 & waitfordelay 3s [176932]
		- 20221110@July: waitfordelay down 500ms [180331]
*/
BEGIN
	
	SET NOCOUNT ON

	DECLARE @sqlCMD NVARCHAR(MAX), @maxRowID BIGINT, @batchSize INT = 2000;
 
	qlandRowID] [bigint] NOT NULL,
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

	IF @ServerName <>  @@SERVERNAME
	BEGIN
		SELECT custid, transid, bettype, actual_stake, winlost, playercomm, BalanceChanged, NewBalance, ActionDate, ActionID, Action, BTBalance, StatusId, MatchId, SettlementType, awinlost, mwinlost, swinlost, comm, acomm, scomm, modds
		FROM #tmpBalanceTrigger
	END

	ELSE
	BEGIN

		--SET @maxRowID = (SELECT CONVERT(BIGINT,VValue) FROM bodb02.dbo.SystemSettings WITH (NOLOCK) WHERE VName = @VName /*'BT_SiteDB01_Sync'*/)
	
		INSERT INTO #tmpBalanceTrigger (rowID, custid, transid, bettype, actual_stake, winlost, playercomm, BalanceChanged, NewBalance, ActionDate, ActionID, Action, BTBalance, StatusId, MatchId, SettlementType, awinlost, mwinlost, swinlost, comm, acomm, scomm, modds)
		SELECT  TOP(@batchSize)
			rowID, custid, transid, bettype, actual_stake, winlost, playercomm, BalanceChanged, NewBalance, ActionDate, ActionID, Action, BTBalance, StatusId, MatchId, SettlementType, awinlost, mwinlost, swinlost, comm, acomm, scomm, modds 
		FROM [bodb02].[dbo].[BalanceTrigger] WITH(NOLOCK) 
		WHERE RowID <= @maxID_tmp AND RowID > @maxRowID
		ORDER BY RowID ASC

		SET @maxRowID = (SELECT MAX(rowID) FROM #tmpBalanceTrigger)

		IF @maxRowID IS NULL
			RETURN

		INSERT INTO [bodb02].[dbo].[BalanceTrigger] (custid, transid, bettype, actual_stake, winlost, playercomm, BalanceChanged, NewBalance, ActionDate, ActionID, Action, BTBalance, StatusId, MatchId, SettlementType, awinlost, mwinlost, swinlost, comm, acomm, scomm, modds)
		SELECT custid, transid, bettype, actual_stake, winlost, playercomm, BalanceChanged, NewBalance, ActionDate, ActionID, Action, BTBalance, StatusId, MatchId, SettlementType, awinlost, mwinlost, swinlost, comm, acomm, scomm, modds
		FROM #tmpBalanceTrigger
		ORDER BY RowID ASC

		SELECT custid, transid, bettype, actual_stake, winlost, playercomm, BalanceChanged, NewBalance, ActionDate, ActionID, Action, BTBalance, StatusId, MatchId, SettlementType, awinlost, mwinlost, swinlost, comm, acomm, scomm, modds
		FROM #tmpBalanceTrigger
	END

END
GO


