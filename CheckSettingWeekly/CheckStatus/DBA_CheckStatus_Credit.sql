/*<info serverAlias="DBCHECK-CheckResultDB" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_CheckStatus_Credit]
	@RuleId	SMALLINT = 0
	,@Sporttype SMALLINT = 0
	,@Bettype SMALLINT = 0
	
	,@DisableTable VARCHAR (100) = ''
	,@DisableColumnName  VARCHAR (100) = ''
	
	,@HiddenTable VARCHAR (100) = ''
	,@HiddenColumnName VARCHAR (100) = ''
	
	,@SynTable VARCHAR (100) = ''
	,@SynColumnName VARCHAR (100) = ''
	
	,@TABLE_CATALOG VARCHAR (200)= 'CheckCustDB'
AS
/*
Created: 20170328@Helen
Task: Monthly check Status setting for credit/deposit customers - [Redmine:73556]
DB: DB054.CheckResultDB
Revisions:
	- 20171208@Johnson: add more rule to check un-sync customers for GD,Casino,VB,AB [Redmine: #87745]
	- 20180201@Johnson: update rule check un-sync customer for GD,Casino,VB,AB [Redmine: #87745]
	- 20190610@Johnson: exclude cn88 site for checking [redmine:#114675]
	- 20210419@Winfred: Remove check Gold Deluxe [redmine:#153659]
	- 20220110@Eden: Saba Casino use DCS Setting [RedmineID: #164280]
Param's Explanation: 
	@RuleId = 0 : 'all'
	@RuleId IN (1->6)
	Casino: Check rule 1,2,3: IsSync = 1

*/

BEGIN 

	SET NOCOUNT ON 
	
	DECLARE @IsExistsInputColumn BIT = 0
	
	-- SPORT: KENO WILL PROCESSED IN ANOTHER SP
	IF @DisableTable <> 'CustInfo' AND @HiddenTable <> 'CustInfo' AND @SynTable <> 'CustInfo'
	BEGIN
		PRINT 'SP only process for status in the table CustInfo ONLY'
		RETURN
	END
	-- CHECK COLUMN NAME EXISTS
	
	IF @HiddenColumnName <> ''
	BEGIN
		IF EXISTS ( SELECT 1 FROM CheckCustDB.INFORMATION_SCHEMA.Columns 
				WHERE TABLE_NAME = @HiddenTable AND COLUMN_NAME = @HiddenColumnName AND TABLE_CATALOG = @TABLE_CATALOG)
			SET @IsExistsInputColumn = 1
	END
	
	IF 	@DisableColumnName <> ''
	BEGIN
		IF EXISTS ( SELECT 1 FROM CheckCustDB.INFORMATION_SCHEMA.Columns 
				WHERE TABLE_NAME = @DisableTable AND COLUMN_NAME = @DisableColumnName AND TABLE_CATALOG = @TABLE_CATALOG)
			SET @IsExistsInputColumn = 1
	END
	
	IF  @SynColumnName <> ''
	BEGIN            
		IF EXISTS ( SELECT 1 FROM CheckCustDB.INFORMATION_SCHEMA.Columns 
				WHERE TABLE_NAME = @SynTable AND COLUMN_NAME = @SynColumnName AND TABLE_CATALOG = @TABLE_CATALOG)
		SET @IsExistsInputColumn = 1             
	END
	
	IF @IsExistsInputColumn = 0 
	BEGIN
		PRINT 'Wrong column name, please re-check'
		RETURN
	END
	-------------------PREPARATION: GET LIST SUPER/Master/Agent disabled FIRST----------------------------
	CREATE TABLE #Supers(CustID INT)
	CREATE TABLE #Super_Disabled (custID INT, IsDisabled BIT)
	CREATE TABLE #Master_Disabled (custID INT,IsDisabled BIT)
	CREATE TABLE #Agent_Disabled (custID INT, IsDisabled BIT)
	
	CREATE TABLE #Super_Hidden (custID INT, IsHidden BIT )
	CREATE TABLE #Master_Hidden (custID INT,IsHidden BIT)
	CREATE TABLE #Agent_Hidden (custID INT, IsHidden BIT)
	
	CREATE TABLE #Super_Sync (custID INT, IsSync BIT)
	CREATE TABLE #Master_Sync (custID INT,IsSync BIT)
	CREATE TABLE #Agent_Sync (custID INT, IsSync BIT)
	
	CREATE TABLE #Cust_Sync (custID INT, IsSync BIT,RoleID INT)
	
	DECLARE @sql_super NVARCHAR(MAX)
	DECLARE @sql_master NVARCHAR(MAX)
	DECLARE @sql_agent NVARCHAR(MAX)
	
	DECLARE @sqlSync NVARCHAR(MAX)
	
	DECLARE @SQLResult NVARCHAR(MAX) = ''
	
	--super list excluded	
	DECLARE @tmpSuper TABLE(CustID INT)
	INSERT INTO @tmpSuper(custid)
	SELECT 	3984944	--	STE8
	UNION SELECT 	3590248	--	CSDTEST
	UNION SELECT 	62	--	SA-KW
	UNION SELECT 	63	--	SA-NZD
	UNION SELECT 	64	--	SA-UT
	UNION SELECT 	65	--	SA-UDI
	UNION SELECT 	66	--	SA-YUN
	UNION SELECT 	68	--	SA-POS
	UNION SELECT 	70	--	SA-MKK
	UNION SELECT 	71	--	SA-KHR
	UNION SELECT 	73	--	SA-LIR
	UNION SELECT 	7119552	--	skwrongxxx
	UNION SELECT 	8551070	--	gtwrong
	UNION SELECT 	69	--	SA-MMK
	UNION SELECT 	18	--	SA-ttt
	UNION SELECT 	21	--	SA-CAD
	UNION SELECT 	37	--	SA-P
	UNION SELECT 	40	--	SA-IRR
	UNION SELECT 	43	--	SA-THB
	UNION SELECT 	44	--	SA-PT
	UNION SELECT 	45	--	SA-WON
	UNION SELECT 	46	--	SA-BND
	UNION SELECT 	47	--	SA-DDD
	UNION SELECT 	48	--	SA-ZAR
	UNION SELECT 	49	--	SA-MXN
	UNION SELECT 	51	--	SA-INH
	UNION SELECT 	52	--	SA-DKK
	UNION SELECT 	53	--	SA-SEK
	UNION SELECT 	54	--	SA-NOK
	UNION SELECT 	55	--	SA-RUB
	UNION SELECT 	56	--	SA-PLN
	UNION SELECT 	57	--	SA-CZK
	UNION SELECT 	58	--	SA-RON
	UNION SELECT 	61	--	SA-INR
	UNION SELECT 	74	--	SA-TH
	UNION SELECT 	8	--	sabill
	UNION SELECT 	7	--	SM07
	UNION SELECT 	10	--	SM10
	UNION SELECT 	11	--	SM11
	UNION SELECT 	14	--	SM14
	UNION SELECT 	19	--	SM19
	UNION SELECT 	23	--	SM23
	UNION SELECT 	24	--	SM24
	UNION SELECT 	38	--	SM38
	UNION SELECT 	39	--	SM39
	UNION SELECT 	59	--	SM59
	UNION SELECT 	60	--	SM60
	UNION SELECT 	75	--	SM75
	UNION SELECT 	76	--	SM76
	UNION SELECT 	77	--	SM77
	UNION SELECT 	78	--	SM78
	UNION SELECT 	79	--	SM79
	UNION SELECT 	80	--	SM80
	UNION SELECT 	81	--	SM81
	UNION SELECT 	82	--	SM82
	UNION SELECT 	83	--	SM83
	UNION SELECT 	84	--	SM84
	UNION SELECT 	85	--	SM85
	UNION SELECT 	86	--	SM86
	UNION SELECT 	87	--	SM87
	UNION SELECT 	88	--	SM88
	UNION SELECT 	89	--	SM89
	UNION SELECT 	90	--	SM90
	UNION SELECT 	91	--	SM91
	UNION SELECT 	92	--	SM92
	UNION SELECT 	93	--	SM93
	UNION SELECT 	94	--	SM94
	UNION SELECT 	95	--	SM95
	UNION SELECT 	96	--	SM96
	UNION SELECT 	97	--	SM97
	UNION SELECT 	98	--	SM98
	UNION SELECT 	99	--	SM99
	UNION SELECT 	100	--	SM0*
	
	INSERT INTO #Supers
	SELECT CI.CustID
	FROM CheckCustDB.dbo.custInfo CI WITH (NOLOCK) 
		INNER JOIN CheckCustDB.dbo.customer c WITH (NOLOCK) ON C.custid = ci.custID
		INNER JOIN CheckCustDB.dbo.CustSuper CS WITH (NOLOCK)  ON CI.custid = CS.custid AND CS.IsInternal = 0
	WHERE CI.roleid = 4 
		AND CI.username NOT LIKE '%Acc%'
		AND CI.username NOT LIKE '%3rdSuper%'
		AND CI.username NOT LIKE 'STEST%'
		AND CI.username NOT LIKE '%cashout%'
		AND CI.username NOT LIKE '%dummy%'
		AND CI.username NOT LIKE '%BetTrade%'
		AND CI.Currency NOT IN (0,20,72,27) 
		AND ci.srecommend NOT IN (SELECT custid FROM CheckCustDB.dbo.Dep_CustSuper WITH(NOLOCK)) 
		AND ci.srecommend NOT IN (SELECT custid FROM @tmpSuper)
		AND ci.Enabled = 1
		AND c.site <> 'cn88'
					
	IF @DisableTable = 'CustInfo' AND @DisableColumnName <> ''
	BEGIN
		
		SET @sql_super = 'SELECT CI.CustID, 1
		FROM CheckCustDB.dbo.custInfo CI WITH (NOLOCK) 			
		WHERE CI.custid IN (SELECT custID FROM #Supers)  AND '  +  @DisableColumnName + ' = 1 AND (@SportType <> 251) '
		
		SET @sql_master = 'SELECT CI.CustID, 1
		FROM CheckCustDB.dbo.custInfo CI (NOLOCK) 
			INNER JOIN CheckCustDB.dbo.CustSuper CS WITH (NOLOCK)  ON CI.srecommend = CS.custid AND CS.IsInternal = 0
		WHERE CI.roleid = 3 
			AND ci.Srecommend IN (SELECT custid FROM #Supers)
			AND CI.username NOT LIKE ''%Acc%''
			AND CI.username NOT LIKE ''%3rdSuper%''
			AND CI.username NOT LIKE ''STEST%''
			AND CI.username NOT LIKE ''%cashout%''
			AND CI.username NOT LIKE ''%dummy%''
			AND CI.username NOT LIKE ''%BetTrade%''
			AND ci.Enabled = 1 AND '  +  @DisableColumnName + ' = 1 AND (@SportType <> 251) '
		
		SET @sql_agent = 'SELECT CI.CustID, 1
		FROM CheckCustDB.dbo.custInfo CI (NOLOCK) 
			INNER JOIN CheckCustDB.dbo.CustSuper CS WITH (NOLOCK)  ON CI.srecommend = CS.custid AND CS.IsInternal = 0
		WHERE CI.roleid = 2 
			AND ci.Srecommend IN (SELECT custid FROM #Supers)
			AND CI.username NOT LIKE ''%Acc%''
			AND CI.username NOT LIKE ''%3rdSuper%''
			AND CI.username NOT LIKE ''STEST%''
			AND CI.username NOT LIKE ''%cashout%''
			AND CI.username NOT LIKE ''%dummy%''
			AND CI.username NOT LIKE ''%BetTrade%''
			AND ci.Enabled = 1 AND '  +  @DisableColumnName + ' = 1 AND (@SportType <> 251) '
		
		INSERT INTO #Super_Disabled (custID,IsDisabled)
		EXEC sp_executeSQL @sql_super, N'@SportType SMALLINT', @SportType	
		
		INSERT INTO #Master_Disabled (custID,IsDisabled)
		EXEC sp_executeSQL @sql_master, N'@SportType SMALLINT', @SportType	
		
		INSERT INTO #Agent_Disabled (custID,IsDisabled)
		EXEC sp_executeSQL @sql_agent, N'@SportType SMALLINT', @SportType	
		
	END
	
	IF @SynTable = 'CustInfo' AND @SynColumnName <> ''
	BEGIN
		
		SET @sql_super = 'SELECT CI.CustID, 0
		FROM CheckCustDB.dbo.custInfo CI WITH (NOLOCK) 			
		WHERE CI.custID IN (SELECT custid FROM #Supers)
			AND '  +  @SynColumnName + ' = 0  '
		
		SET @sql_master = 'SELECT CI.CustID, 0
		FROM CheckCustDB.dbo.custInfo CI (NOLOCK) 
			INNER JOIN CheckCustDB.dbo.CustSuper CS WITH (NOLOCK)  ON CI.srecommend = CS.custid AND CS.IsInternal = 0
		WHERE CI.roleid = 3 
			AND ci.Srecommend IN (SELECT custid FROM #Supers)
			AND CI.username NOT LIKE ''%Acc%''
			AND CI.username NOT LIKE ''%3rdSuper%''
			AND CI.username NOT LIKE ''STEST%''
			AND CI.username NOT LIKE ''%cashout%''
			AND CI.username NOT LIKE ''%dummy%''
			AND CI.username NOT LIKE ''%BetTrade%''
			AND ci.Enabled = 1 AND '  +  @SynColumnName + ' = 0  '
		
		SET @sql_agent = 'SELECT CI.CustID, 0
		FROM CheckCustDB.dbo.custInfo CI (NOLOCK) 
			INNER JOIN CheckCustDB.dbo.CustSuper CS WITH (NOLOCK)  ON CI.srecommend = CS.custid AND CS.IsInternal = 0
		WHERE CI.roleid = 2 
			AND ci.Srecommend IN (SELECT custid FROM #Supers)
			AND CI.username NOT LIKE ''%Acc%''
			AND CI.username NOT LIKE ''%3rdSuper%''
			AND CI.username NOT LIKE ''STEST%''
			AND CI.username NOT LIKE ''%cashout%''
			AND CI.username NOT LIKE ''%dummy%''
			AND CI.username NOT LIKE ''%BetTrade%''
			AND ci.Enabled = 1 AND '  +  @SynColumnName + ' = 0  '
		
		INSERT INTO #Super_Sync (custID,IsSync)
		EXEC sp_executeSQL @sql_super
		
		INSERT INTO #Master_Sync (custID,IsSync)
		EXEC sp_executeSQL @sql_master
		
		INSERT INTO #Agent_Sync (custID,IsSync)
		EXEC sp_executeSQL @sql_agent
		
	END
		
	IF @HiddenTable = 'CustInfo' AND @HiddenColumnName <> ''
	BEGIN
		
		SET @sql_super = 'SELECT CI.CustID, 1
		FROM CheckCustDB.dbo.custInfo CI WITH (NOLOCK) 			
		WHERE CI.custID IN (SELECT custid FROM #Supers) AND '  +  @HiddenColumnName + ' = 1
			AND (@SportType <> 255)'
		
		SET @sql_master = 'SELECT CI.CustID, 1
		FROM CheckCustDB.dbo.custInfo CI WITH (NOLOCK) 
			INNER JOIN CheckCustDB.dbo.CustSuper CS WITH (NOLOCK)  ON CI.srecommend = CS.custid AND CS.IsInternal = 0
		WHERE CI.roleid = 3 
			AND ci.Srecommend IN (SELECT custid FROM #Supers)
			AND CI.username NOT LIKE ''%Acc%''
			AND CI.username NOT LIKE ''%3rdSuper%''
			AND CI.username NOT LIKE ''STEST%''
			AND CI.username NOT LIKE ''%cashout%''
			AND CI.username NOT LIKE ''%dummy%''
			AND CI.username NOT LIKE ''%BetTrade%''
			AND ci.Enabled = 1 AND '  +  @HiddenColumnName + ' = 1
			AND (@SportType <> 255)'
		
		SET @sql_agent = 'SELECT CI.CustID, 1
		FROM CheckCustDB.dbo.custInfo CI WITH (NOLOCK) 
			INNER JOIN CheckCustDB.dbo.CustSuper CS WITH (NOLOCK)  ON CI.srecommend = CS.custid AND CS.IsInternal = 0
		WHERE CI.roleid = 2 
			AND ci.Srecommend IN (SELECT custid FROM #Supers)
			AND CI.username NOT LIKE ''%Acc%''
			AND CI.username NOT LIKE ''%3rdSuper%''
			AND CI.username NOT LIKE ''STEST%''
			AND CI.username NOT LIKE ''%cashout%''
			AND CI.username NOT LIKE ''%dummy%''
			AND CI.username NOT LIKE ''%BetTrade%''
			AND ci.Enabled = 1 AND '  +  @HiddenColumnName + ' = 1
			AND (@SportType <> 255)'
		
		INSERT INTO #Super_Hidden(custID,IsHidden)
		EXEC sp_executeSQL @sql_super, N'@SportType SMALLINT', @SportType		
		
		INSERT INTO #Master_Hidden (custID,IsHidden)
		EXEC sp_executeSQL @sql_master, N'@SportType SMALLINT', @SportType		
		
		INSERT INTO #Agent_Hidden (custID,IsHidden)
		EXEC sp_executeSQL @sql_agent, N'@SportType SMALLINT', @SportType		
		
	END
	
	IF @SynTable = 'CustInfo' AND @SynColumnName <> ''
	BEGIN
		SET @sqlSync = 'SELECT CI.CustID, 1, CI.RoleID
		FROM CheckCustDB.dbo.custInfo CI WITH (NOLOCK) 
			INNER JOIN CheckCustDB.dbo.CustSuper CS WITH (NOLOCK)  ON CI.srecommend = CS.custid AND CS.IsInternal = 0
		WHERE CI.username NOT LIKE ''%Acc%''
			AND CI.username NOT LIKE ''%3rdSuper%''
			AND CI.username NOT LIKE ''STEST%''
			AND CI.username NOT LIKE ''%cashout%''
			AND CI.username NOT LIKE ''%dummy%''
			AND CI.username NOT LIKE ''%BetTrade%''
			AND ci.Srecommend IN (SELECT custid FROM #Supers)
			
			AND ci.Enabled = 1 AND '  +  @SynColumnName + ' = 0'
		
		INSERT INTO #Cust_Sync(custID,IsSync,RoleID)
		EXEC sp_executeSQL @sqlSync
		
	END
	
	/* tracing issues
	
	SELECT @sql_super
	SELECT @sql_master
	SELECT @sql_agent
	
	SELECT * FROM #Super_Hidden
	SELECT * FROM #Master_Hidden
	SELECT * FROM #Agent_Hidden
	
	SELECT * FROM #Super_Disabled
	SELECT * FROM #Master_Disabled
	SELECT * FROM #agent_Disabled
	*/
	-------------------END OF PREPARATION: GET LIST SUPER/Master/Agent disabled FIRST----------------------------
	-- Rule 1: Super IsDisabled= 1, Master IsDisabled = 0		
	IF @RuleId IN (0,1) AND @DisableColumnName <> ''
	BEGIN
	
		SET @SQLResult = 'SELECT 1 AS RuleID, @Sporttype AS SportType,@Bettype BetType, ci.custid AS MasterID,ci.srecommend,0 AS ValueA,1 ValueB ,GETDATE() , 0 IsDeposit  
		FROM #Super_Disabled S
			INNER JOIN CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON S.CustID = CI.srecommend AND CI.roleid = 3 AND CI.Enabled = 1 
		WHERE CI.username NOT LIKE ''%Acc%''
			AND CI.username NOT LIKE ''%3rdSuper%''
			AND CI.username NOT LIKE ''STEST%''
			AND CI.username NOT LIKE ''%cashout%''
			AND CI.username NOT LIKE ''%dummy%''
			AND CI.username NOT LIKE ''%BetTrade%'' 
			AND CI.' + @DisableColumnName + ' = 0  AND (@SportType <> 251) '
		
		SELECT @SQLResult
		
		INSERT INTO CheckStatusResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		EXEC sp_executeSQL @SQLResult,N'@Sporttype SMALLINT,@Bettype SMALLINT', @Sporttype, @Bettype
		
		PRINT 1 
	END	
	
	-- Rule 2: Master IsDisabled= 1, Agent IsDisabled = 0		
	IF @RuleId IN (0,2) AND @DisableColumnName <> ''
	BEGIN
		SET @SQLResult = 'SELECT 2, @Sporttype,@Bettype, ci.custid,m.custid,0,1,GETDATE() , 0 
		FROM #Master_Disabled m
			INNER JOIN CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON m.CustID = CI.mrecommend AND CI.roleid = 2 AND CI.Enabled = 1
		WHERE CI.username NOT LIKE ''%Acc%''
			AND CI.username NOT LIKE ''%3rdSuper%''
			AND CI.username NOT LIKE ''STEST%''
			AND CI.username NOT LIKE ''%cashout%''
			AND CI.username NOT LIKE ''%dummy%''
			AND CI.username NOT LIKE ''%BetTrade%'' 
			AND CI.' + @DisableColumnName + ' = 0  AND (@SportType <> 251) '
		
		SELECT @SQLResult
		
		INSERT INTO CheckStatusResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		EXEC sp_executeSQL @SQLResult,N'@Sporttype SMALLINT,@Bettype SMALLINT', @Sporttype, @Bettype
		
		PRINT 2
	END	
	
	-- Rule 3: Agent IsDisabled= 1, Member IsDisabled = 0		
	IF @RuleId IN (0,3) AND @DisableColumnName <> ''
	BEGIN
		SET @SQLResult = 'SELECT 3, @Sporttype,@Bettype, ci.custid ,a.custid,0,1,GETDATE() , 0
		FROM #Agent_Disabled a
			INNER JOIN CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON a.CustID = CI.recommend AND CI.roleid = 1 AND CI.Enabled = 1
		WHERE CI.username NOT LIKE ''%Acc%''
			AND CI.username NOT LIKE ''%3rdSuper%''
			AND CI.username NOT LIKE ''STEST%''
			AND CI.username NOT LIKE ''%cashout%''
			AND CI.username NOT LIKE ''%dummy%''
			AND CI.username NOT LIKE ''%BetTrade%'' 
			AND CI.' + @DisableColumnName + ' = 0  AND (@SportType <> 251)'
		
		SELECT @SQLResult
		
		INSERT INTO CheckStatusResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		EXEC sp_executeSQL @SQLResult,N'@Sporttype SMALLINT,@Bettype SMALLINT', @Sporttype, @Bettype
		
		PRINT 3
	END
	
	-- Rule 4: Super Hidden= 1, Master Hidden = 0		
	IF @RuleId IN (0,4) AND @HiddenColumnName <> ''
	BEGIN
		SET @SQLResult = 'SELECT 4, @Sporttype,@Bettype, ci.custid AS MasterID,ci.srecommend,0,1,GETDATE() , 0
		FROM #Super_Hidden S
			INNER JOIN CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON S.CustID = CI.srecommend AND CI.roleid = 3 AND CI.Enabled = 1
		WHERE CI.username NOT LIKE ''%Acc%''
			AND CI.username NOT LIKE ''%3rdSuper%''
			AND CI.username NOT LIKE ''STEST%''
			AND CI.username NOT LIKE ''%cashout%''
			AND CI.username NOT LIKE ''%dummy%''
			AND CI.username NOT LIKE ''%BetTrade%''
			AND CI.' + @HiddenColumnName + ' = 0 '
		
		SELECT @SQLResult
		
		INSERT INTO CheckStatusResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		EXEC sp_executeSQL @SQLResult,N'@Sporttype SMALLINT,@Bettype SMALLINT', @Sporttype, @Bettype
		
		PRINT 4
	END	
	
	-- Rule 5: Master Hidden= 1, Agent Hidden = 0		
	IF @RuleId IN (0,5) AND @HiddenColumnName <> ''
	BEGIN
		SET @SQLResult = 'SELECT 5, @Sporttype,@Bettype, ci.custid,m.custid,0,1,GETDATE() , 0
		FROM #Master_Hidden m
			INNER JOIN CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON m.CustID = CI.mrecommend AND CI.roleid = 2 AND CI.Enabled = 1
		WHERE CI.username NOT LIKE ''%Acc%''
			AND CI.username NOT LIKE ''%3rdSuper%''
			AND CI.username NOT LIKE ''STEST%''
			AND CI.username NOT LIKE ''%cashout%''
			AND CI.username NOT LIKE ''%dummy%''
			AND CI.username NOT LIKE ''%BetTrade%'' 
			AND CI.' + @HiddenColumnName + ' = 0 '
		
		INSERT INTO CheckStatusResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		EXEC sp_executeSQL @SQLResult,N'@Sporttype SMALLINT,@Bettype SMALLINT', @Sporttype, @Bettype
		
		PRINT 5
	END	
	
	-- Rule 6: Agent Hidden= 1, Member Hidden = 0		
	IF @RuleId IN (0,6) AND @HiddenColumnName <> ''
	BEGIN
		SET @SQLResult = 'SELECT 6, @Sporttype,@Bettype, ci.custid ,a.custid,0,1,GETDATE() , 0
		FROM #Agent_Hidden a
			INNER JOIN CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON a.CustID = CI.recommend AND CI.roleid = 1 AND CI.Enabled = 1
		WHERE CI.username NOT LIKE ''%Acc%''
			AND CI.username NOT LIKE ''%3rdSuper%''
			AND CI.username NOT LIKE ''STEST%''
			AND CI.username NOT LIKE ''%cashout%''
			AND CI.username NOT LIKE ''%dummy%''
			AND CI.username NOT LIKE ''%BetTrade%'' 
			AND CI.' + @HiddenColumnName + ' = 0 '
		
		SELECT @SQLResult
		
		INSERT INTO CheckStatusResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		EXEC sp_executeSQL @SQLResult,N'@Sporttype SMALLINT,@Bettype SMALLINT', @Sporttype, @Bettype
		
		PRINT 6
		
	END
	
	-- Rule 7: Sync= 0, Hidden = 0
	IF @HiddenColumnName <> '' AND @SynColumnName <> '' AND @Sporttype NOT IN (162,251)
	BEGIN		
		IF @RuleId IN (0,7)
		BEGIN
			SET @SQLResult = 'SELECT 7, @Sporttype,@Bettype, ci.custid ,S.custid,0,0,GETDATE() , 0 
			FROM #Cust_Sync S
				INNER JOIN CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON S.CustID = CI.custid AND s.RoleID = 4 AND CI.Enabled = 1
			WHERE CI.username NOT LIKE ''%Acc%''
				AND CI.username NOT LIKE ''%3rdSuper%''
				AND CI.username NOT LIKE ''STEST%''
				AND CI.username NOT LIKE ''%cashout%''
				AND CI.username NOT LIKE ''%dummy%''
				AND CI.username NOT LIKE ''%BetTrade%'' 
				AND CI.' + @HiddenColumnName + ' = 0
			 
			UNION ALL
			
			SELECT 7, @Sporttype,@Bettype, ci.custid ,a.custid,0,0,GETDATE() , 0 
			FROM #Cust_Sync a
				INNER JOIN CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON a.CustID = CI.custid AND a.RoleID = 3 AND CI.Enabled = 1
			WHERE CI.username NOT LIKE ''%Acc%''
				AND CI.username NOT LIKE ''%3rdSuper%''
				AND CI.username NOT LIKE ''STEST%''
				AND CI.username NOT LIKE ''%cashout%''
				AND CI.username NOT LIKE ''%dummy%''
				AND CI.username NOT LIKE ''%BetTrade%'' 
				AND CI.' + @HiddenColumnName + ' = 0 
			
			UNION ALL
			
			SELECT 7, @Sporttype,@Bettype, ci.custid ,a.custid,0,0,GETDATE() , 0 
			FROM #Cust_Sync a
				INNER JOIN CheckCustDB.dbo.custInfo  CI WITH (NOLOCK) ON a.CustID = CI.custid AND a.RoleID = 2 AND CI.Enabled = 1
			WHERE CI.username NOT LIKE ''%Acc%''
				AND CI.username NOT LIKE ''%3rdSuper%''
				AND CI.username NOT LIKE ''STEST%''
				AND CI.username NOT LIKE ''%cashout%''
				AND CI.username NOT LIKE ''%dummy%''
				AND CI.username NOT LIKE ''%BetTrade%'' 
				AND CI.' + @HiddenColumnName + ' = 0
			
			UNION ALL
			
			SELECT 7, @Sporttype,@Bettype, ci.custid ,a.custid,0,0,GETDATE() , 0 
			FROM #Cust_Sync a
				INNER JOIN CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON a.CustID = CI.custid AND a.RoleID = 1 AND CI.Enabled = 1
			WHERE CI.username NOT LIKE ''%Acc%''
				AND CI.username NOT LIKE ''%3rdSuper%''
				AND CI.username NOT LIKE ''STEST%''
				AND CI.username NOT LIKE ''%cashout%''
				AND CI.username NOT LIKE ''%dummy%''
				AND CI.username NOT LIKE ''%BetTrade%'' 
				AND CI.' + @HiddenColumnName + ' = 0
						
			'
			
			INSERT INTO CheckStatusResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
			EXEC sp_executeSQL @SQLResult,N'@Sporttype SMALLINT,@Bettype SMALLINT', @Sporttype, @Bettype
			
			PRINT 7
			
		END
	END
	
	-- Rule 8: Sync= 0, Disable = 0		
	IF @DisableColumnName <> '' AND @SynColumnName <> '' AND @Sporttype NOT IN (162,251)
	BEGIN
		IF @RuleId IN (0,8)
		BEGIN
			SET @SQLResult = 'SELECT 8, @Sporttype,@Bettype, ci.custid ,S.custid,0,0,GETDATE() , 0 
			FROM #Cust_Sync S
				INNER JOIN CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON S.CustID = CI.custid AND s.RoleID = 4 AND CI.Enabled = 1
			WHERE CI.username NOT LIKE ''%Acc%''
				AND CI.username NOT LIKE ''%3rdSuper%''
				AND CI.username NOT LIKE ''STEST%''
				AND CI.username NOT LIKE ''%cashout%''
				AND CI.username NOT LIKE ''%dummy%''
				AND CI.username NOT LIKE ''%BetTrade%'' 
				AND CI.' + @DisableColumnName + ' = 0
			 
			UNION ALL
			
			SELECT 8, @Sporttype,@Bettype, ci.custid ,m.custid,0,0,GETDATE() , 0 
			FROM #Cust_Sync m
				INNER JOIN CheckCustDB.dbo.custInfo  CI WITH (NOLOCK) ON m.CustID = CI.custid AND m.RoleID = 3 AND  CI.Enabled = 1
			WHERE CI.username NOT LIKE ''%Acc%''
				AND CI.username NOT LIKE ''%3rdSuper%''
				AND CI.username NOT LIKE ''STEST%''
				AND CI.username NOT LIKE ''%cashout%''
				AND CI.username NOT LIKE ''%dummy%''
				AND CI.username NOT LIKE ''%BetTrade%'' 
				AND CI.' + @DisableColumnName + ' = 0 
			
			UNION ALL
			
			SELECT 8, @Sporttype,@Bettype, ci.custid ,a.custid,0,0,GETDATE() , 0 
			FROM #Cust_Sync a
				INNER JOIN CheckCustDB.dbo.custInfo  CI WITH (NOLOCK) ON a.CustID = CI.custid AND a.RoleID = 2 AND CI.Enabled = 1
			WHERE CI.username NOT LIKE ''%Acc%''
				AND CI.username NOT LIKE ''%3rdSuper%''
				AND CI.username NOT LIKE ''STEST%''
				AND CI.username NOT LIKE ''%cashout%''
				AND CI.username NOT LIKE ''%dummy%''
				AND CI.username NOT LIKE ''%BetTrade%'' 
				AND CI.' + @DisableColumnName + ' = 0
			
			UNION ALL
			
			SELECT 8, @Sporttype,@Bettype, ci.custid ,mb.custid,0,0,GETDATE() , 0 
			FROM #Cust_Sync mb
				INNER JOIN CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON mb.CustID = CI.custid AND mb.RoleID = 1 AND CI.Enabled = 1
			WHERE CI.username NOT LIKE ''%Acc%''
				AND CI.username NOT LIKE ''%3rdSuper%''
				AND CI.username NOT LIKE ''STEST%''
				AND CI.username NOT LIKE ''%cashout%''
				AND CI.username NOT LIKE ''%dummy%''
				AND CI.username NOT LIKE ''%BetTrade%'' 
				AND CI.' + @DisableColumnName + ' = 0
						
			'
			
			INSERT INTO CheckStatusResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
			EXEC sp_executeSQL @SQLResult,N'@Sporttype SMALLINT,@Bettype SMALLINT', @Sporttype, @Bettype
			
			PRINT 8
			
		END
	END
	
	-- Rule 10: Super IsSync= 0, Master IsSync = 1		
	IF @RuleId IN (0,10) AND @SynColumnName <> ''
	BEGIN
	
		SET @SQLResult = 'SELECT 10 AS RuleID, @Sporttype AS SportType,@Bettype BetType, ci.custid AS MasterID,ci.srecommend,1 AS ValueA,0 ValueB ,GETDATE() , 0 IsDeposit  
		FROM #Super_Sync S
			INNER JOIN CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON S.CustID = CI.srecommend AND CI.roleid = 3 AND CI.Enabled = 1 
		WHERE CI.username NOT LIKE ''%Acc%''
			AND CI.username NOT LIKE ''%3rdSuper%''
			AND CI.username NOT LIKE ''STEST%''
			AND CI.username NOT LIKE ''%cashout%''
			AND CI.username NOT LIKE ''%dummy%''
			AND CI.username NOT LIKE ''%BetTrade%'' 
			AND CI.' + @SynColumnName + ' = 1  '
		
		SELECT @SQLResult
		
		INSERT INTO CheckStatusResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		EXEC sp_executeSQL @SQLResult,N'@Sporttype SMALLINT,@Bettype SMALLINT', @Sporttype, @Bettype
		
		PRINT 10 
	END	
	
	-- Rule 11: Master IsSync= 0, Agent IsSync = 1		
	IF @RuleId IN (0,11) AND @SynColumnName <> ''
	BEGIN
		SET @SQLResult = 'SELECT 11, @Sporttype,@Bettype, ci.custid,m.custid,1,0,GETDATE() , 0 
		FROM #Master_Sync m
			INNER JOIN CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON m.CustID = CI.mrecommend AND CI.roleid = 2 AND CI.Enabled = 1
		WHERE CI.username NOT LIKE ''%Acc%''
			AND CI.username NOT LIKE ''%3rdSuper%''
			AND CI.username NOT LIKE ''STEST%''
			AND CI.username NOT LIKE ''%cashout%''
			AND CI.username NOT LIKE ''%dummy%''
			AND CI.username NOT LIKE ''%BetTrade%'' 
			AND CI.' + @SynColumnName + ' = 1  '
		
		SELECT @SQLResult
		
		INSERT INTO CheckStatusResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		EXEC sp_executeSQL @SQLResult,N'@Sporttype SMALLINT,@Bettype SMALLINT', @Sporttype, @Bettype
		
		PRINT 11
	END	
	
	-- Rule 12: Agent IsSync= 0, Member IsSync = 1		
	IF @RuleId IN (0,12) AND @SynColumnName <> ''
	BEGIN
		SET @SQLResult = 'SELECT 12, @Sporttype,@Bettype, ci.custid ,a.custid,1,0,GETDATE() , 0
		FROM #Agent_Sync a
			INNER JOIN CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON a.CustID = CI.recommend AND CI.roleid = 1 AND CI.Enabled = 1
		WHERE CI.username NOT LIKE ''%Acc%''
			AND CI.username NOT LIKE ''%3rdSuper%''
			AND CI.username NOT LIKE ''STEST%''
			AND CI.username NOT LIKE ''%cashout%''
			AND CI.username NOT LIKE ''%dummy%''
			AND CI.username NOT LIKE ''%BetTrade%'' 
			AND CI.' + @SynColumnName + ' = 1 '
		
		SELECT @SQLResult
		
		INSERT INTO CheckStatusResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		EXEC sp_executeSQL @SQLResult,N'@Sporttype SMALLINT,@Bettype SMALLINT', @Sporttype, @Bettype
		
		PRINT 12
	END
	
	--rule 13: Super IsSync= 0(For GD,CS)
	IF @ruleID IN (0,13) AND @SportType IN (251)
	BEGIN
		IF @SportType = 251
		BEGIN
			SET @SQLResult = 'SELECT 13 AS RuleID, @Sporttype AS SportType,@Bettype BetType, custid,custid,0 AS ValueA,0 ValueB ,GETDATE() , 0 IsDeposit  
			FROM #Super_Sync'
		END
		ELSE 
		BEGIN
			SET @SQLResult = 'SELECT 13 AS RuleID, @Sporttype,@Bettype, custid ,CustID,0,0,GETDATE() , 0
			FROM #Super_Hidden'
		END
		
		SELECT @SQLResult
		
		INSERT INTO CheckStatusResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		EXEC sp_executeSQL @SQLResult,N'@Sporttype SMALLINT,@Bettype SMALLINT', @Sporttype, @Bettype
		
		PRINT 13 
	END
	
	--rule 14: Master IsSync= 0(For GD,CS)
	IF @ruleID IN (0,14) AND @SportType IN (251)
	BEGIN
		IF @SportType = 251
		BEGIN
			SET @SQLResult = 'SELECT 14 AS RuleID, @Sporttype AS SportType,@Bettype BetType, custid,custid,0 AS ValueA,0 ValueB ,GETDATE() , 0 IsDeposit  
			FROM #Master_Sync'
		END
		ELSE 
		BEGIN
			SET @SQLResult = 'SELECT 14 AS RuleID, @Sporttype,@Bettype, custid ,CustID,0,0,GETDATE() , 0
			FROM #Master_Hidden'
		END
		
		SELECT @SQLResult
		
		INSERT INTO CheckStatusResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		EXEC sp_executeSQL @SQLResult,N'@Sporttype SMALLINT,@Bettype SMALLINT', @Sporttype, @Bettype
		
		PRINT 14 
	END
	
	--rule 15: Agent IsSync= 0(For GD,CS)
	IF @ruleID IN (0,15) AND @SportType IN (251) 
	BEGIN
		IF @SportType = 251
		BEGIN
			SET @SQLResult = 'SELECT 15 AS RuleID, @Sporttype AS SportType,@Bettype BetType, custid,custid,0 AS ValueA,0 ValueB ,GETDATE() , 0 IsDeposit  
			FROM #Agent_Sync'
		END
		ELSE 
		BEGIN
			SET @SQLResult = 'SELECT 15 AS RuleID, @Sporttype,@Bettype, custid ,CustID,0,0,GETDATE() , 0
			FROM #Agent_Hidden'
		END
		
		SELECT @SQLResult
		
		INSERT INTO CheckStatusResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		EXEC sp_executeSQL @SQLResult,N'@Sporttype SMALLINT,@Bettype SMALLINT', @Sporttype, @Bettype
		
		PRINT 15 
	END
	
	--rule 16: Member IsSync= 0(For GD,CS)
	IF @ruleID IN (0,16) AND @SportType IN (251)
	BEGIN
		IF @SportType = 251
		BEGIN
			SET @SQLResult = 'SELECT 16 AS RuleID, @Sporttype AS SportType,@Bettype BetType, ci.custid,ci.custid,0 AS ValueA,0 ValueB ,GETDATE() , 0 IsDeposit  
			FROM CheckCustDB.dbo.custInfo CI WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSuper CS WITH (NOLOCK)  ON CI.srecommend = CS.custid AND CS.IsInternal = 0
			WHERE CI.roleid = 1 
				AND CI.username NOT LIKE ''%Acc%''
				AND CI.username NOT LIKE ''%3rdSuper%''
				AND CI.username NOT LIKE ''STEST%''
				AND CI.username NOT LIKE ''%cashout%''
				AND CI.username NOT LIKE ''%dummy%''
				AND CI.username NOT LIKE ''%BetTrade%''
				AND ci.Srecommend IN (SELECT custid FROM #Supers)
				AND CI.Currency NOT IN (0,20,72,27) AND ci.srecommend NOT IN (SELECT custid FROM CheckCustDB.dbo.Dep_CustSuper WITH(NOLOCK)) AND ci.Enabled = 1 AND '  +  @SynColumnName + ' = 0'
				
		END
		ELSE 
		BEGIN
			SET @SQLResult = 'SELECT 16 AS RuleID, @Sporttype AS SportType,@Bettype BetType, ci.custid,ci.custid,0 AS ValueA,0 ValueB ,GETDATE() , 0 IsDeposit  
			FROM CheckCustDB.dbo.custInfo CI WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSuper CS WITH (NOLOCK)  ON CI.srecommend = CS.custid AND CS.IsInternal = 0
			WHERE CI.roleid = 1 
				AND CI.username NOT LIKE ''%Acc%''
				AND CI.username NOT LIKE ''%3rdSuper%''
				AND CI.username NOT LIKE ''STEST%''
				AND CI.username NOT LIKE ''%cashout%''
				AND CI.username NOT LIKE ''%dummy%''
				AND CI.username NOT LIKE ''%BetTrade%''
				AND CI.Currency NOT IN (0,20,72,27) AND ci.srecommend NOT IN (SELECT custid FROM CheckCustDB.dbo.Dep_CustSuper WITH(NOLOCK)) AND ci.Enabled = 1 AND '  +  @HiddenColumnName + ' = 1
				AND ci.Srecommend IN (SELECT custid FROM #Supers)
				AND (@SportType <> 255)'
				
		END
		
		SELECT @SQLResult
		
		INSERT INTO CheckStatusResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		EXEC sp_executeSQL @SQLResult,N'@Sporttype SMALLINT,@Bettype SMALLINT', @Sporttype, @Bettype
		
		PRINT 16 
	END
	----------------------------FINAL RESULT ------------------------------------

	SET NOCOUNT OFF	
		
END
GO

