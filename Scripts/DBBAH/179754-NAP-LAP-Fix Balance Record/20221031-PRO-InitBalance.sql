/*<info serverAlias="DBBAH-bodb02" executers="" isFunction="0"></info>*/
/*
    Created: 20221031@Max
	Task: NAP/LAP - Wrong balance value shown for functions using BalanceRecord table [Redmine: #179754]
	DB:DBBAH/bodb02

	Notes: run on db05bk1 only
*/
USE bodb02
GO
---------------------------------------------------------------------------------
DECLARE @maxcustid INT = 0

SELECT @maxcustid = MAX(custid) 
FROM customer ci WITH (NOLOCK)
	INNER JOIN site s WITH (NOLOCK) ON ci.site = s.site
WHERE s.SiteDBGroupID = 2

SELECT @maxcustid AS [@maxcustid]

--------------DECLARE temporary tables ------------------
CREATE TABLE #temp_MemberInput(
	ID INT IDENTITY (1,1) PRIMARY KEY,
	custid INT
)

CREATE TABLE #tempMember (custid INT PRIMARY KEY)
--------------GET members needs to process ------------------
INSERT INTO #temp_MemberInput (custid)
VALUES (48290292),(48309997),(48761351),(48777895),(48784639),(48841664),(48899232),(48909449),(48910921),(48911167),(48912013),(48964898),(49023183),(49351901),(49370161),(49411273),(49476571),(49694386),(49857034),(49956221),(49972188),(50380569),(50785313),(50803314),(51432486),(51911447),(52041702),(52272733),(52595855),(53031246),(53053275),(53224417),(53789772),(53796142),(54353604),(54574985),(54656097),(54720653),(54805445),(54839856),(54859811),(54989011),(55229227),(55310787),(55337886),(55351870),(55522809),(55581966),(30628299),(30912905),(31764314),(31986666),(32282042),(33380898),(33652656),(33922561),(33993970),(34102859),(34724273),(34991836),(35582342),(55736216),(55800764),(56160721),(56169517),(56188242),(56218435),(56275704),(57246903),(57650353),(57762475),(57905217),(58050653),(58082033),(58308926),(58422623),(58545989),(58624901),(58830101),(58966219),(59029332),(59120522),(59139929),(59317619),(59437965),(59446086),(59492723),(59602000),(59627499),(59823032),(59856321),(59929096),(60147653),(60186974),(60384196),(60445482),(60502710),(60546912),(60658126),(60669060),(60699395),(61029048),(61235379),(61860226),(61927447),(36464652),(36745872),(36957792),(37447646),(39828349),(40150668),(41414658),(41484047),(41580342),(41654838),(42667946),(42707269),(43170621),(43285505),(62319850),(62366132),(62382742),(62583538),(62712506),(63136943),(63633510),(63746083),(63903615),(63945656),(64529346),(64751051),(65064675),(65129439),(65425390),(65954862),(66057482),(66512226),(66582459),(66914277),(66961572),(67054753),(67065496),(67351589),(67469304),(67489335),(67855963),(67890621),(68038077),(68089632),(68264080),(68422462),(68545907),(68647488),(43799766),(43976626),(44087142),(44140721),(44225743),(44994094),(45497406),(45700316),(20484837),(21670494),(22516537),(22737584),(23649211),(24165303),(24232340),(24598991),(24754386),(26016980),(27188278),(27289702),(28185339),(28298235),(28607422),(28651566),(28886343),(13869208),(69648424),(69896333),(70013182),(70090013),(70259772),(70330503),(70366514),(70367731),(70368280),(70369565),(70377111),(70380012),(70383036),(70383342),(70385630),(70385645),(70385755),(70385836),(70387829),(70388761),(70389270),(70391319),(70397048),(70397195),(70397211),(70401688),(70401827),(70407585),(70408123),(70420303),(70425799),(70439477),(70441152),(70445484),(70451175),(70452324),(70452641),(70453637),(70455690),(70458457),(70463730),(70466796),(70472234),(70483925),(70485980),(70496137),(70498297),(70500011),(70501937),(70505068),(70505887),(70506799),(70509669),(70510292),(70524059),(70525783),(70526071),(70526351),(70528276),(70529833),(70535626),(70535896),(70539659),(70542887),(70545430),(70545879),(70547309),(70556623),(70564049),(70572269),(70575956),(70576549),(70577823),(70579486),(70583965),(70589246),(70589294),(70591569),(70593275),(70606017),(70616048),(70622267),(70624513),(70624601),(70627862),(70628195),(70640307),(70643664),(70649925),(70656129),(14666594),(14710583),(14961692),(15866267),(16328977),(16652557),(16675134),(18020737),(45997437),(46016235),(46087710),(46459014),(46549360),(46581082),(46721655),(46778790),(46957889),(47056228),(47272334),(47415086),(47429046),(47439411),(47439529),(47492610),(47520485),(47855906),(47976473),(47999643),(48143283),(48278885),(70597735)

SELECT @@ROWCOUNT AS [custid_Count]

-- delete data [dbo].[BalanceTrigger_ProcessData] for customers will process to insert balancerecord for credit
SELECT TOP 1 1
FROM BalanceTrigger_ProcessData b WITH (NOLOCK)
	INNER JOIN #temp_MemberInput m ON b.custid = m.custid

----------- get maxtransid: Run on DBTRans/bodb02----------------
select * from OPENQUERY(DBSIG02, '
select *
from (
	select MAX(transid) from bodb02.dbo.bettrans with(nolock)
) as b(bettrans_transid)
outer apply (
	select MAX(transid) from bodb02.dbo.Transfer with(nolock)
) as b2(Transfer_transid)
outer apply (
	select MAX(translogid) from bodb02.dbo.translog with(nolock)
) as b3(translog_translogid)
outer apply (
	select MAX(transid) from bodb02.dbo.bettransLC with(nolock)
) as b4(bettransLC_transid)
outer apply (
	select MAX(transid) from bodb02.dbo.bettransRnG with(nolock)
) as b5(bettransRnG_transid)');

------ info for deployer 
DECLARE @debug_message VARCHAR(MAX) = ''

--------------LOOP BY batch 500 of customers ------------------
DECLARE @rid_loop INT, @rowCount int  =0, @batch int = 25, @loop_cnt int = 1
DECLARE @StartRow INT = 1
		, @StopRow INT 
		, @retrycnt INT = 0 
		, @isSuccess BIT = 0
DECLARE  @ExecuteSQL NVARCHAR(MAX) = ''
		, @query NVARCHAR(MAX) = ''
		, @ExecuteSQL_balance NVARCHAR(MAX) = ''
		, @query_balance NVARCHAR(MAX) = ''
		, @SiteDBAlias VARCHAR(200) ='DBSIG02'
		, @CustidList VARCHAR(MAX) = ''

DECLARE @CustidBalanceList VARCHAR(MAX) = ''
DECLARE @xml XML = NULL

SET @rid_loop = ((SELECT MAX(ID) FROM #temp_MemberInput)/@batch) + 1
SET @StopRow = @batch

SELECT  @query = N''		
SELECT	@query = @query + N'EXEC SiteDB_BalanceRecord_DeleteBalanceTrigger_tmp @CustidList'
SELECT	@ExecuteSQL = N'EXECUTE '+ @SiteDBAlias +'.bodb02.dbo.sp_executesql @query, N''@CustidList VARCHAR(MAX)'',@CustidList'

-- SET param to insert balance in db05
SELECT  @query_balance = N'', @SiteDBAlias = 'DB05'		
SELECT	@query_balance = @query_balance + N'EXEC SiteDB_BalanceRecord_InsertBalanceRecord_tmp @CustidBalanceList'
SELECT	@ExecuteSQL_balance = N'EXECUTE '+ @SiteDBAlias +'.bodb02.dbo.sp_executesql @query_balance, N''@CustidBalanceList VARCHAR(MAX)'',@CustidBalanceList'

WHILE (@loop_cnt <= @rid_loop)
BEGIN
	
	TRUNCATE TABLE #tempMember

	SET @debug_message = CONCAT(CONVERT(VARCHAR(50), GETDATE(), 121), ', processing for round:',  @loop_cnt, '/', @rid_loop)
	RAISERROR (@debug_message, 0, 1) WITH NOWAIT

	-- process by recommend, 2000 customers per batch
	INSERT INTO #tempMember(custid)
	SELECT custid
	FROM #temp_MemberInput 
	WHERE ID BETWEEN @StartRow AND @StopRow

	IF @@ROWCOUNT = 0
		BREAK

	SET @CustidList = ''
	SET @CustidList = STUFF((SELECT ',' + CONVERT(VARCHAR(20), custid)
				 FROM #tempMember 
				 FOR XML PATH ('')
					),1,1,'')	
					
	--- step 2 insert balance record to re-init
	SELECT @CustidBalanceList = (SELECT  m.custid AS '@c'
										,bal.Balance AS '@b'
								FROM #tempMember m
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

	-- step 3: delete balance trigger if exists
	WHILE (@isSuccess = 0)
	BEGIN
		BEGIN TRY

			EXECUTE	sys.sp_executesql @ExecuteSQL, N'@query NVARCHAR(MAX), @CustidList VARCHAR(MAX)', @query, @CustidList
			SET @isSuccess = 1

		END TRY
		BEGIN CATCH
			SET @retrycnt = @retrycnt + 1
			PRINT @retrycnt

		END CATCH
	END

	WAITFOR DELAY '00:00:00.020' --optional

	SET @StartRow = @StopRow + 1
	SET @StopRow = @StopRow + @batch

	SELECT  @loop_cnt += 1

END

--SELECT @rowCount

DROP TABLE #temp_MemberInput
DROP TABLE #tempMember



