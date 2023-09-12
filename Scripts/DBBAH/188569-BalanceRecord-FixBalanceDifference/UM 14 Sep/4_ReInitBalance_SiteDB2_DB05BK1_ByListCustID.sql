/*<info serverAlias="DBBAH-bodb02" executers="" isFunction="0"></info>*/
/*
    Created: 20230905@Louisa
	Task: Reinit balance - SiteDB2 by list custid [Redmine: #181595]
	DB:DBBAH/bodb02

*/

----Run on DB05BK1 only

USE bodb02
GO

--------------DECLARE temporary tables ------------------

IF OBJECT_ID('tempdb..#temp_Cust') IS NOT NULL
	DROP TABLE #temp_Cust

CREATE TABLE #temp_Cust(
	ID INT IDENTITY (1,1) PRIMARY KEY,
	custid INT
)


--------------GET members needs to process ------------------
INSERT INTO #temp_Cust (custid)
VALUES (32738833),(23431627),(32198000),(92383360),(68311925),(57817256),(65334583),(68602803),(67234654)
	  ,(49513060),(49523362),(49576151),(49582372),(61140910),(80453191),(91396612),(23314258),(35226943)
	  ,(77102519),(83532606),(91176245),(52536624),(70525202),(53060168),(74785410),(84167078),(42982534)
	  ,(53947758),(67127975),(58044443),(63937843)

SELECT count(1) AS [custid_Count_diff] FROM #temp_Cust 

-- Check data [dbo].[BalanceTrigger_ProcessData] on DB05/DB05BK1 until it's no data
SELECT TOP 1 1
FROM BalanceTrigger_ProcessData b WITH (NOLOCK)
	INNER JOIN #temp_Cust m ON b.custid = m.custid

DECLARE  @ExecuteSQL NVARCHAR(MAX) = ''
		, @query NVARCHAR(MAX) = ''
		, @ExecuteSQL_balance NVARCHAR(MAX) = ''
		, @query_balance NVARCHAR(MAX) = ''
		, @SiteDBAlias VARCHAR(200) = ''

DECLARE @CustidBalanceList VARCHAR(MAX) = ''
DECLARE @xml XML = NULL

-- SET param to insert balance in db05
	SELECT  @query_balance = N'', @SiteDBAlias = 'DB05'		
	SELECT	@query_balance = @query_balance + N'EXEC SiteDB_BalanceRecord_InsertBalanceRecord_tmp @CustidBalanceList'
	SELECT	@ExecuteSQL_balance = N'EXECUTE '+ @SiteDBAlias +'.bodb02.dbo.sp_executesql @query_balance, N''@CustidBalanceList VARCHAR(MAX)'',@CustidBalanceList'
					
	SELECT @CustidBalanceList = (SELECT  m.custid AS '@c'
										,bal.Balance AS '@b'
								FROM #temp_Cust m
									CROSS APPLY (
												SELECT TOP 1 Balance 
												FROM DBSIG02.bodb02.dbo.v_BalanceTable b WITH(NOLOCK) -- v_BalanceTable: this is a view, get data from 8 balance tables
												WHERE b.custid = m.custid) AS bal
								FOR XML PATH('r'), ROOT('root')
								)
	SET @xml = CONVERT(XML, @CustidBalanceList)

	-- insert db05bk1 first
	INSERT INTO BalanceRecord (custid, transid, bettype, actual_stake, winlost, playercomm, balancechanged, newbalance, actionDate, actionID, [action])
	SELECT	t.c.value('@c','int') AS custid, 0, 0, 0, 0, 0, 0, t.c.value('@b','MONEY') AS balance,CURRENT_TIMESTAMP, 255, 'Balance : Re-Init'
	FROM @xml.nodes('root/r') t(c)
	OPTION (OPTIMIZE FOR (@xml = NULL))	

	-- insert db05
	EXECUTE	sys.sp_executesql @ExecuteSQL_balance, N'@query_balance NVARCHAR(MAX), @CustidBalanceList VARCHAR(MAX)', @query_balance, @CustidBalanceList






