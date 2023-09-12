/*<info serverAlias="DBBAH-bodb02" executers="" isFunction="0"></info>*/
/*
    Created: 20230905@Louisa
	Task: Reinit balance - SiteDB1 by list custid [Redmine: #181595]
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
VALUES (84619149),(91239955),(10187086),(11928147),(18947648),(19145431),(23811333),(28579105),(28748784)
	  ,(29578527),(29609998),(29932000),(31899735),(32189993),(32887678),(32986338),(36017000),(40571898),(43693908)
	  ,(45468108),(47715523),(48804690),(53619224),(79955100),(80256675),(79926776),(79965109),(82777482),(83046775)
	  ,(83752522),(84711215),(84802703),(88029542),(89233556),(89234152),(89395301),(89644339),(90765020),(67382054)
	  ,(79892156),(70646765),(72857465),(80060190),(62287186),(62616364),(88515921),(57072603),(63783132),(62417107)
	  ,(65271739),(69657242),(90369781),(79368267),(62082439),(73689084),(87776937),(88274247),(88566130),(90789892)
	  ,(90877046),(72624846),(73650150),(76685422),(91531213),(92098884),(65325518),(66607038),(80341066),(78550574)
	  ,(78551922),(78555219),(78924335),(80196422),(82244254),(85634410),(86337264),(89257194),(89063848),(91550626)
	  ,(89727103),(91072077),(85272866),(45410901),(81040277),(59281652),(54975115),(81545808)

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
												FROM DBSIG01.bodb02.dbo.v_BalanceTable b WITH(NOLOCK) -- v_BalanceTable: this is a view, get data from 8 balance tables
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






