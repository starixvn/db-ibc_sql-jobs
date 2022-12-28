/*<info serverAlias="DBAGE-bodb02,DBEXT-bodb02" executers="bodbDownlineNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_WLMonitored_Service_AccumulatedData]
	@ServiceName VARCHAR(100) = 'WLMonitoredAccount'
	,@CustWinlost XML
	,@LastId BIGINT
AS
/*	Creator: 20220617@Kathy
	Task: Accumulate data
	DB: DBAGE/BODB02
	
	Revisions:	
		- 20220617@Kathy: accumulate data [Redmine:#170467]
		- 20221228@Kathy: Monitor SMA WinLoss [Redmine:#179067]

	Param's Explanation:
		  @CustWinlost: <CustIds>
						    	<Cust CustId="1" AccumWL="100" Type="c" SettlementDate="20220617" Action="i" RoleId=""/>
						    	<Cust CustId="2" AccumWL="100" Type="d" SettlementDate="20220617" Action="" RoleId=""/>
						</CustIds>
			Action: i - delete existing row if any (turn on setting) then insert new accumulate wl
*/
BEGIN
	SET NOCOUNT ON
	CREATE TABLE #tmpCustWinlost (CustId INT, Type VARCHAR(1), AccumWL MONEY, SettlementDate DATE, Action VARCHAR(1), RoleId TINYINT)
	
	;WITH cteAccummWL
	AS(
		SELECT	T.c.value ('@CustId', 'INT') AS CustId
				,T.c.value ('@Type', 'VARCHAR(1)') AS Type
				,ISNULL(T.c.value ('@AccumWL', 'MONEY'),0) AS AccumWL
				,T.c.value ('@SettlementDate', 'DATE') AS SettlementDate
				,T.c.value ('@Action', 'VARCHAR(1)') AS Action
				,T.c.value ('@RoleId', 'TINYINT') AS RoleId
		FROM	@CustWinlost.nodes('/CustIds/Cust') AS T(c)
	)
	INSERT INTO #tmpCustWinlost(CustId, Type, AccumWL, SettlementDate, Action, RoleId)
	SELECT	CustId, Type, SUM(AccumWL), SettlementDate, Action, RoleId
	FROM	cteAccummWL
	GROUP BY CustId, Type, SettlementDate, Action, RoleId

	BEGIN -- credit
		--delete existing rows if turn on setting
		DELETE	a WITH(ROWLOCK, UPDLOCK)
		FROM	dbo.WLMonitored_AccumulatedWL a 
			INNER JOIN #tmpCustWinlost t
				ON	a.CustId = t.CustId
					AND a.SettlementDate = t.SettlementDate
		WHERE	t.Action = 'i'

		-- insert/update accumulate wl
		MERGE	dbo.WLMonitored_AccumulatedWL WITH(ROWLOCK, UPDLOCK) AS TARGET
		USING (SELECT	CustId, AccumWL, SettlementDate, RoleId
				FROM	#tmpCustWinlost
				WHERE	Type = 'c'
		) AS SOURCE
			ON TARGET.CustId = SOURCE.CustId
				AND TARGET.SettlementDate = SOURCE.SettlementDate
		WHEN MATCHED THEN
			UPDATE SET 
				TARGET.AccumWL = TARGET.AccumWL + SOURCE.AccumWL
				,TARGET.UpdatedTime = GETDATE()
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (CustId, AccumWL, SettlementDate, UpdatedTime, RoleId) VALUES (SOURCE.CustId, SOURCE.AccumWL, SOURCE.SettlementDate, GETDATE(), SOURCE.RoleId);
	END

	BEGIN -- deposit
		--delete existing rows if turn on setting
		DELETE	a WITH(ROWLOCK, UPDLOCK)
		FROM	dbo.Dep_WLMonitored_AccumulatedWL a 
			INNER JOIN #tmpCustWinlost t
				ON	a.CustId = t.CustId
					AND a.SettlementDate = t.SettlementDate
		WHERE	t.Action = 'i'

		-- insert/update accumulate wl
		MERGE	dbo.Dep_WLMonitored_AccumulatedWL WITH(ROWLOCK, UPDLOCK) AS TARGET
		USING (SELECT	CustId, AccumWL, SettlementDate
				FROM	#tmpCustWinlost
				WHERE	Type = 'd'
		) AS SOURCE
			ON TARGET.CustId = SOURCE.CustId
				AND TARGET.SettlementDate = SOURCE.SettlementDate
		WHEN MATCHED THEN
			UPDATE SET 
				TARGET.AccumWL = TARGET.AccumWL + SOURCE.AccumWL
				,TARGET.UpdatedTime = GETDATE()
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (CustId, AccumWL, SettlementDate, UpdatedTime) VALUES (SOURCE.CustId, SOURCE.AccumWL, SOURCE.SettlementDate, GETDATE());
	END

	EXEC dbo.Acc_WLMonitored_Service_GlobalSettingUpd 
		@ServiceName = @ServiceName
		,@SettingName = 'LastId'
		,@SettingValue = @LastId
END
GO
