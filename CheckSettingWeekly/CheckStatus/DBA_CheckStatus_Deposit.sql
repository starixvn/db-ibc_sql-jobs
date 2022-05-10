/*<info serverAlias="DBCHECK-CheckResultDB" executers="" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_CheckStatus_Deposit]
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
		- 20190130@Winnie:	Remove ClearBal Acc - [Redmine: #73556]
		- 20201211@Winfred: Remove OddAdj Acc[redmine:#147005]
		- 20201223@Winfred: not check data from CustSuper table[redmine:#147408]
		- 20220110@Eden: Saba Casino use DCS Setting [RedmineID: #164280]
		
Param's Explanation: 
	@RuleId = 0 : 'all'
	@RuleId IN (1->6)
*/
BEGIN 
	SET NOCOUNT ON 
	DECLARE @IsExistsInputColumn BIT = 0
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
	IF @DisableTable = 'CustInfo' AND @DisableColumnName <> ''
	BEGIN
		SET @sql_super = 'SELECT CI.CustID, 1
		FROM CheckCustDB.dbo.custInfo CI (NOLOCK) 
		WHERE CI.roleid = 4 
			AND CI.Currency NOT IN (20,72,27)
			AND CI.username NOT LIKE ''%Acc%''
			AND CI.username NOT LIKE ''%3rdSuper%''
			AND CI.username NOT LIKE ''STEST%''
			AND CI.username NOT LIKE ''%cashout%''
			AND CI.username NOT LIKE ''%dummy%''
			AND CI.username NOT LIKE ''%BetTrade%''
			AND ci.username NOT LIKE ''%ClearBal%''
			AND ci.username NOT LIKE ''%OddsAdj%''
			AND CI.srecommend IN (SELECT custid FROM CheckCustDB.dbo.Dep_CustSuper WITH(NOLOCK)) AND ci.Enabled = 1 AND '  +  @DisableColumnName + ' = 1 AND (@SportType <> 251) '
		SET @sql_master = 'SELECT CI.CustID, 1
		FROM CheckCustDB.dbo.custInfo CI (NOLOCK)
		WHERE CI.roleid = 3 
			AND CI.Currency NOT IN (20,72,27)
			AND CI.username NOT LIKE ''%Acc%''
			AND CI.username NOT LIKE ''%3rdSuper%''
			AND CI.username NOT LIKE ''STEST%''
			AND CI.username NOT LIKE ''%cashout%''
			AND CI.username NOT LIKE ''%dummy%''
			AND CI.username NOT LIKE ''%BetTrade%''
			AND ci.username NOT LIKE ''%ClearBal%''
			AND ci.username NOT LIKE ''%OddsAdj%''
			AND ci.srecommend IN (SELECT custid FROM CheckCustDB.dbo.Dep_CustSuper WITH(NOLOCK)) AND ci.Enabled = 1 AND '  +  @DisableColumnName + ' = 1 AND (@SportType <> 251) '
		SET @sql_agent = 'SELECT CI.CustID, 1
		FROM CheckCustDB.dbo.custInfo CI (NOLOCK)
		WHERE CI.roleid = 2 
			AND CI.Currency NOT IN (20,72,27)
			AND CI.username NOT LIKE ''%Acc%''
			AND CI.username NOT LIKE ''%3rdSuper%''
			AND CI.username NOT LIKE ''STEST%''
			AND CI.username NOT LIKE ''%cashout%''
			AND CI.username NOT LIKE ''%dummy%''
			AND CI.username NOT LIKE ''%BetTrade%''
			AND ci.username NOT LIKE ''%ClearBal%''
			AND ci.username NOT LIKE ''%OddsAdj%''
			AND ci.srecommend IN (SELECT custid FROM CheckCustDB.dbo.Dep_CustSuper WITH(NOLOCK)) AND ci.Enabled = 1 AND '  +  @DisableColumnName + ' = 1 AND (@SportType <> 251) '
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
		FROM CheckCustDB.dbo.custInfo CI (NOLOCK) 
		WHERE CI.roleid = 4 
			AND CI.Currency NOT IN (20,72,27)
			AND CI.username NOT LIKE ''%Acc%''
			AND CI.username NOT LIKE ''%3rdSuper%''
			AND CI.username NOT LIKE ''STEST%''
			AND CI.username NOT LIKE ''%cashout%''
			AND CI.username NOT LIKE ''%dummy%''
			AND CI.username NOT LIKE ''%BetTrade%''
			AND ci.username NOT LIKE ''%ClearBal%''
			AND ci.username NOT LIKE ''%OddsAdj%''
			AND ci.srecommend IN (SELECT custid FROM CheckCustDB.dbo.Dep_CustSuper WITH(NOLOCK)) AND ci.Enabled = 1 AND '  +  @SynColumnName + ' = 0 '
		SET @sql_master = 'SELECT CI.CustID, 0
		FROM CheckCustDB.dbo.custInfo CI (NOLOCK)
		WHERE CI.roleid = 3 
			 AND CI.Currency NOT IN (20,72,27)
			AND CI.username NOT LIKE ''%Acc%''
			AND CI.username NOT LIKE ''%3rdSuper%''
			AND CI.username NOT LIKE ''STEST%''
			AND CI.username NOT LIKE ''%cashout%''
			AND CI.username NOT LIKE ''%dummy%''
			AND CI.username NOT LIKE ''%BetTrade%''
			AND ci.username NOT LIKE ''%ClearBal%''
			AND ci.username NOT LIKE ''%OddsAdj%''
			AND ci.srecommend IN (SELECT custid FROM CheckCustDB.dbo.Dep_CustSuper WITH(NOLOCK)) AND ci.Enabled = 1 AND '  +  @SynColumnName + ' = 0  '
		SET @sql_agent = 'SELECT CI.CustID, 0
		FROM CheckCustDB.dbo.custInfo CI (NOLOCK)
		WHERE CI.roleid = 2 
			AND CI.Currency NOT IN (20,72,27)
			AND CI.username NOT LIKE ''%Acc%''
			AND CI.username NOT LIKE ''%3rdSuper%''
			AND CI.username NOT LIKE ''STEST%''
			AND CI.username NOT LIKE ''%cashout%''
			AND CI.username NOT LIKE ''%dummy%''
			AND CI.username NOT LIKE ''%BetTrade%''
			AND ci.username NOT LIKE ''%ClearBal%''
			AND ci.username NOT LIKE ''%OddsAdj%''
			AND ci.srecommend IN (SELECT custid FROM CheckCustDB.dbo.Dep_CustSuper WITH(NOLOCK)) AND ci.Enabled = 1 AND '  +  @SynColumnName + ' = 0  '
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
		WHERE CI.roleid = 4 
			AND CI.Currency NOT IN (20,72,27)
			AND CI.username NOT LIKE ''%Acc%''
			AND CI.username NOT LIKE ''%3rdSuper%''
			AND CI.username NOT LIKE ''STEST%''
			AND CI.username NOT LIKE ''%cashout%''
			AND CI.username NOT LIKE ''%dummy%''
			AND CI.username NOT LIKE ''%BetTrade%''
			AND ci.username NOT LIKE ''%ClearBal%''
			AND ci.username NOT LIKE ''%OddsAdj%''
			AND ci.srecommend IN (SELECT custid FROM CheckCustDB.dbo.Dep_CustSuper WITH(NOLOCK)) AND ci.Enabled = 1 AND '  +  @HiddenColumnName + ' = 1'
		SET @sql_master = 'SELECT CI.CustID, 1
		FROM CheckCustDB.dbo.custInfo CI WITH (NOLOCK) 
		WHERE CI.roleid = 3 
			AND CI.Currency NOT IN (20,72,27)
			AND CI.username NOT LIKE ''%Acc%''
			AND CI.username NOT LIKE ''%3rdSuper%''
			AND CI.username NOT LIKE ''STEST%''
			AND CI.username NOT LIKE ''%cashout%''
			AND CI.username NOT LIKE ''%dummy%''
			AND CI.username NOT LIKE ''%BetTrade%''
			AND ci.username NOT LIKE ''%ClearBal%''
			AND ci.username NOT LIKE ''%OddsAdj%''
			AND ci.srecommend IN (SELECT custid FROM CheckCustDB.dbo.Dep_CustSuper WITH(NOLOCK)) AND ci.Enabled = 1 AND '  +  @HiddenColumnName + ' = 1'
		SET @sql_agent = 'SELECT CI.CustID, 1
		FROM CheckCustDB.dbo.custInfo CI WITH (NOLOCK)
		WHERE CI.roleid = 2 
			AND CI.Currency NOT IN (20,72,27) 
			AND CI.username NOT LIKE ''%Acc%''
			AND CI.username NOT LIKE ''%3rdSuper%''
			AND CI.username NOT LIKE ''STEST%''
			AND CI.username NOT LIKE ''%cashout%''
			AND CI.username NOT LIKE ''%dummy%''
			AND CI.username NOT LIKE ''%BetTrade%''
			AND ci.username NOT LIKE ''%ClearBal%''
			AND ci.username NOT LIKE ''%OddsAdj%''
			AND ci.srecommend IN (SELECT custid FROM CheckCustDB.dbo.Dep_CustSuper WITH(NOLOCK)) AND ci.Enabled = 1 AND '  +  @HiddenColumnName + ' = 1'
		INSERT INTO #Super_Hidden(custID,IsHidden)
		EXEC sp_executeSQL @sql_super	
		INSERT INTO #Master_Hidden (custID,IsHidden)
		EXEC sp_executeSQL @sql_master	
		INSERT INTO #Agent_Hidden (custID,IsHidden)
		EXEC sp_executeSQL @sql_agent	
	END
	IF @SynTable = 'CustInfo' AND @SynColumnName <> ''
	BEGIN
		SET @sqlSync = 'SELECT CI.CustID, 1, CI.RoleID
		FROM CheckCustDB.dbo.custInfo CI WITH (NOLOCK) 
		WHERE CI.Currency NOT IN (20,72,27)
			AND CI.username NOT LIKE ''%Acc%''
			AND CI.username NOT LIKE ''%3rdSuper%''
			AND CI.username NOT LIKE ''STEST%''
			AND CI.username NOT LIKE ''%cashout%''
			AND CI.username NOT LIKE ''%dummy%''
			AND CI.username NOT LIKE ''%BetTrade%''
			AND ci.username NOT LIKE ''%ClearBal%''
			AND ci.username NOT LIKE ''%OddsAdj%''
			AND ci.srecommend IN (SELECT custid FROM CheckCustDB.dbo.Dep_CustSuper WITH(NOLOCK)) AND ci.Enabled = 1 AND '  +  @SynColumnName + ' = 0'
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
		SET @SQLResult = 'SELECT 1 AS RuleID, @Sporttype AS SportType,@Bettype BetType, ci.custid AS MasterID,ci.srecommend,0 AS ValueA, 1 ValueB ,GETDATE() , 1 IsDeposit  
		FROM #Super_Disabled S
			INNER JOIN CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON S.CustID = CI.srecommend AND CI.roleid = 3 AND CI.Enabled = 1
		WHERE  CI.username NOT LIKE ''%Acc%''
			AND CI.username NOT LIKE ''%3rdSuper%''
			AND CI.username NOT LIKE ''STEST%''
			AND CI.username NOT LIKE ''%cashout%''
			AND CI.username NOT LIKE ''%dummy%''
			AND ci.username NOT LIKE ''%ClearBal%''
			AND ci.username NOT LIKE ''%OddsAdj%''
			AND CI.username NOT LIKE ''%BetTrade%'' AND CI.' + @DisableColumnName + ' = 0  AND (@SportType <> 251) '
		SELECT @SQLResult
		INSERT INTO CheckStatusResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		EXEC sp_executeSQL @SQLResult,N'@Sporttype SMALLINT,@Bettype SMALLINT', @Sporttype, @Bettype
		PRINT 1 
	END	
	-- Rule 2: Master IsDisabled= 1, Agent IsDisabled = 0		
	IF @RuleId IN (0,2) AND @DisableColumnName <> ''
	BEGIN
		SET @SQLResult = 'SELECT 2, @Sporttype,@Bettype, ci.custid,m.custid,0,1,GETDATE() , 1 
		FROM #Master_Disabled m
			INNER JOIN CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON m.CustID = CI.mrecommend AND CI.roleid = 2 AND CI.Enabled = 1
		WHERE CI.username NOT LIKE ''%Acc%''
			AND CI.username NOT LIKE ''%3rdSuper%''
			AND CI.username NOT LIKE ''STEST%''
			AND CI.username NOT LIKE ''%cashout%''
			AND CI.username NOT LIKE ''%dummy%''
			AND ci.username NOT LIKE ''%ClearBal%''
			AND ci.username NOT LIKE ''%OddsAdj%''
			AND CI.username NOT LIKE ''%BetTrade%'' AND  CI.' + @DisableColumnName + ' = 0  AND (@SportType <> 251) '
		SELECT @SQLResult
		INSERT INTO CheckStatusResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		EXEC sp_executeSQL @SQLResult,N'@Sporttype SMALLINT,@Bettype SMALLINT', @Sporttype, @Bettype
		PRINT 2
	END	
	-- Rule 3: Agent IsDisabled= 1, Member IsDisabled = 0		
	IF @RuleId IN (0,3) AND @DisableColumnName <> ''
	BEGIN
		SET @SQLResult = 'SELECT 3, @Sporttype,@Bettype, ci.custid ,a.custid,0,1,GETDATE() , 1
		FROM #Agent_Disabled a
			INNER JOIN CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON a.CustID = CI.recommend AND CI.roleid = 1 AND CI.Enabled = 1
		WHERE CI.username NOT LIKE ''%Acc%''
			AND CI.username NOT LIKE ''%3rdSuper%''
			AND CI.username NOT LIKE ''STEST%''
			AND CI.username NOT LIKE ''%cashout%''
			AND CI.username NOT LIKE ''%dummy%''
			AND ci.username NOT LIKE ''%ClearBal%''
			AND ci.username NOT LIKE ''%OddsAdj%''
			AND CI.username NOT LIKE ''%BetTrade%'' AND  CI.' + @DisableColumnName + ' = 0  AND (@SportType <> 251) '
		SELECT @SQLResult
		INSERT INTO CheckStatusResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		EXEC sp_executeSQL @SQLResult,N'@Sporttype SMALLINT,@Bettype SMALLINT', @Sporttype, @Bettype
		PRINT 3
	END
	-- Rule 4: Super Hidden= 1, Master Hidden = 0		
	IF @RuleId IN (0,4) AND @HiddenColumnName <> ''
	BEGIN
		SET @SQLResult = 'SELECT 4, @Sporttype,@Bettype, ci.custid AS MasterID,ci.srecommend,0,1,GETDATE() , 1
		FROM #Super_Hidden S
			INNER JOIN CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON S.CustID = CI.srecommend AND CI.roleid = 3 AND CI.Enabled = 1
		WHERE CI.username NOT LIKE ''%Acc%''
			AND CI.username NOT LIKE ''%3rdSuper%''
			AND CI.username NOT LIKE ''STEST%''
			AND CI.username NOT LIKE ''%cashout%''
			AND CI.username NOT LIKE ''%dummy%''
			AND ci.username NOT LIKE ''%ClearBal%''
			AND ci.username NOT LIKE ''%OddsAdj%''
			AND CI.username NOT LIKE ''%BetTrade%'' AND  CI.' + @HiddenColumnName + ' = 0 '
		SELECT @SQLResult
		INSERT INTO CheckStatusResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		EXEC sp_executeSQL @SQLResult,N'@Sporttype SMALLINT,@Bettype SMALLINT', @Sporttype, @Bettype
		PRINT 4
	END	
	-- Rule 5: Master Hidden= 1, Agent Hidden = 0		
	IF @RuleId IN (0,5) AND @HiddenColumnName <> ''
	BEGIN
		SET @SQLResult = 'SELECT 5, @Sporttype,@Bettype, ci.custid,m.custid,0,1,GETDATE() , 1
		FROM #Master_Hidden m
			INNER JOIN CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON m.CustID = CI.mrecommend AND CI.roleid = 2 AND CI.Enabled = 1
		WHERE  CI.username NOT LIKE ''%Acc%''
			AND CI.username NOT LIKE ''%3rdSuper%''
			AND CI.username NOT LIKE ''STEST%''
			AND CI.username NOT LIKE ''%cashout%''
			AND CI.username NOT LIKE ''%dummy%''
			AND ci.username NOT LIKE ''%ClearBal%''
			AND ci.username NOT LIKE ''%OddsAdj%''
			AND CI.username NOT LIKE ''%BetTrade%'' AND CI.' + @HiddenColumnName + ' = 0 '
		INSERT INTO CheckStatusResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		EXEC sp_executeSQL @SQLResult,N'@Sporttype SMALLINT,@Bettype SMALLINT', @Sporttype, @Bettype
		PRINT 5
	END	
	-- Rule 6: Agent Hidden= 1, Member Hidden = 0		
	IF @RuleId IN (0,6) AND @HiddenColumnName <> ''
	BEGIN
		SET @SQLResult = 'SELECT 6, @Sporttype,@Bettype, ci.custid ,a.custid,0,1,GETDATE() , 1
		FROM #Agent_Hidden a
			INNER JOIN CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON a.CustID = CI.recommend AND CI.roleid = 1 AND CI.Enabled = 1
		WHERE  CI.username NOT LIKE ''%Acc%''
			AND CI.username NOT LIKE ''%3rdSuper%''
			AND CI.username NOT LIKE ''STEST%''
			AND CI.username NOT LIKE ''%cashout%''
			AND CI.username NOT LIKE ''%dummy%''
			AND ci.username NOT LIKE ''%ClearBal%''
			AND ci.username NOT LIKE ''%OddsAdj%''
			AND CI.username NOT LIKE ''%BetTrade%'' AND CI.' + @HiddenColumnName + ' = 0 '
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
			SET @SQLResult = 'SELECT 7, @Sporttype,@Bettype, ci.custid ,S.custid,0,0,GETDATE() , 1 
			FROM #Cust_Sync S
				INNER JOIN CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON S.CustID = CI.custid AND s.RoleID = 4 AND CI.Enabled = 1
			WHERE  CI.username NOT LIKE ''%Acc%''
				AND CI.username NOT LIKE ''%3rdSuper%''
				AND CI.username NOT LIKE ''STEST%''
				AND CI.username NOT LIKE ''%cashout%''
				AND CI.username NOT LIKE ''%dummy%''
				AND ci.username NOT LIKE ''%ClearBal%''
				AND ci.username NOT LIKE ''%OddsAdj%''
				AND CI.username NOT LIKE ''%BetTrade%'' AND CI.' + @HiddenColumnName + ' = 0
			UNION ALL
			SELECT 7, @Sporttype,@Bettype, ci.custid ,m.custid,0,0,GETDATE() , 1 
			FROM #Cust_Sync m
				INNER JOIN CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON m.CustID = CI.custid AND m.RoleID = 3 AND CI.Enabled = 1
			WHERE CI.username NOT LIKE ''%Acc%''
				AND CI.username NOT LIKE ''%3rdSuper%''
				AND CI.username NOT LIKE ''STEST%''
				AND CI.username NOT LIKE ''%cashout%''
				AND CI.username NOT LIKE ''%dummy%''
				AND ci.username NOT LIKE ''%ClearBal%''
				AND ci.username NOT LIKE ''%OddsAdj%''
				AND CI.username NOT LIKE ''%BetTrade%'' AND  CI.' + @HiddenColumnName + ' = 0 
			UNION ALL
			SELECT 7, @Sporttype,@Bettype, ci.custid ,a.custid,0,0,GETDATE() , 1 
			FROM #Cust_Sync a
				INNER JOIN CheckCustDB.dbo.custInfo  CI WITH (NOLOCK) ON a.CustID = CI.custid AND a.RoleID = 2 AND CI.Enabled = 1
			WHERE  CI.username NOT LIKE ''%Acc%''
				AND CI.username NOT LIKE ''%3rdSuper%''
				AND CI.username NOT LIKE ''STEST%''
				AND CI.username NOT LIKE ''%cashout%''
				AND CI.username NOT LIKE ''%dummy%''
				AND ci.username NOT LIKE ''%ClearBal%''
				AND ci.username NOT LIKE ''%OddsAdj%''
				AND CI.username NOT LIKE ''%BetTrade%'' AND CI.' + @HiddenColumnName + ' = 0
			UNION ALL
			SELECT 7, @Sporttype,@Bettype, ci.custid ,mb.custid,0,0,GETDATE() , 1 
			FROM #Cust_Sync mb
				INNER JOIN CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON mb.CustID = CI.custid AND mb.RoleID = 1 AND CI.Enabled = 1
			WHERE  CI.username NOT LIKE ''%Acc%''
				AND CI.username NOT LIKE ''%3rdSuper%''
				AND CI.username NOT LIKE ''STEST%''
				AND CI.username NOT LIKE ''%cashout%''
				AND CI.username NOT LIKE ''%dummy%''
				AND ci.username NOT LIKE ''%ClearBal%''
				AND ci.username NOT LIKE ''%OddsAdj%''
				AND CI.username NOT LIKE ''%BetTrade%'' AND CI.' + @HiddenColumnName + ' = 0
			'
			INSERT INTO CheckStatusResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
			EXEC sp_executeSQL @SQLResult,N'@Sporttype SMALLINT,@Bettype SMALLINT', @Sporttype, @Bettype
			PRINT 8
		END
	END
	-- Rule 8: Sync= 0, Disable = 0		
	IF @DisableColumnName <> '' AND @SynColumnName <> '' AND @Sporttype NOT IN (162,251)
	BEGIN
		IF @RuleId IN (0,8)
		BEGIN
			SET @SQLResult = 'SELECT 8, @Sporttype,@Bettype, ci.custid ,S.custid,0,0,GETDATE() , 1 
			FROM #Cust_Sync S
				INNER JOIN CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON S.CustID = CI.custid AND s.RoleID = 4 AND CI.Enabled = 1
			WHERE CI.username NOT LIKE ''%Acc%''
				AND CI.username NOT LIKE ''%3rdSuper%''
				AND CI.username NOT LIKE ''STEST%''
				AND CI.username NOT LIKE ''%cashout%''
				AND CI.username NOT LIKE ''%dummy%''
				AND ci.username NOT LIKE ''%ClearBal%''
				AND ci.username NOT LIKE ''%OddsAdj%''
				AND CI.username NOT LIKE ''%BetTrade%'' AND  CI.' + @DisableColumnName + ' = 0
			UNION ALL
			SELECT 8, @Sporttype,@Bettype, ci.custid ,m.custid,0,0,GETDATE() , 1 
			FROM #Cust_Sync m
				INNER JOIN CheckCustDB.dbo.custInfo  CI WITH (NOLOCK) ON m.CustID = CI.custid AND m.RoleID = 3 AND  CI.Enabled = 1
			WHERE  CI.username NOT LIKE ''%Acc%''
				AND CI.username NOT LIKE ''%3rdSuper%''
				AND CI.username NOT LIKE ''STEST%''
				AND CI.username NOT LIKE ''%cashout%''
				AND CI.username NOT LIKE ''%dummy%''
				AND ci.username NOT LIKE ''%ClearBal%''
				AND ci.username NOT LIKE ''%OddsAdj%''
				AND CI.username NOT LIKE ''%BetTrade%'' AND  CI.' + @DisableColumnName + ' = 0 
			UNION ALL
			SELECT 8, @Sporttype,@Bettype, ci.custid ,a.custid,0,0,GETDATE() , 1 
			FROM #Cust_Sync a
				INNER JOIN CheckCustDB.dbo.custInfo  CI WITH (NOLOCK) ON a.CustID = CI.custid AND a.RoleID = 2 AND CI.Enabled = 1
			WHERE CI.username NOT LIKE ''%Acc%''
				AND CI.username NOT LIKE ''%3rdSuper%''
				AND CI.username NOT LIKE ''STEST%''
				AND CI.username NOT LIKE ''%cashout%''
				AND CI.username NOT LIKE ''%dummy%''
				AND ci.username NOT LIKE ''%ClearBal%''
				AND ci.username NOT LIKE ''%OddsAdj%''
				AND CI.username NOT LIKE ''%BetTrade%'' AND  CI.' + @DisableColumnName + ' = 0
			UNION ALL
			SELECT 8, @Sporttype,@Bettype, ci.custid ,mb.custid,0,0,GETDATE() , 1 
			FROM #Cust_Sync mb
				INNER JOIN CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON mb.CustID = CI.custid AND mb.RoleID = 1 AND CI.Enabled = 1
			WHERE  CI.username NOT LIKE ''%Acc%''
				AND CI.username NOT LIKE ''%3rdSuper%''
				AND CI.username NOT LIKE ''STEST%''
				AND CI.username NOT LIKE ''%cashout%''
				AND CI.username NOT LIKE ''%dummy%''
				AND ci.username NOT LIKE ''%ClearBal%''
				AND ci.username NOT LIKE ''%OddsAdj%''
				AND CI.username NOT LIKE ''%BetTrade%'' AND  CI.' + @DisableColumnName + ' = 0
			'
			INSERT INTO CheckStatusResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
			EXEC sp_executeSQL @SQLResult,N'@Sporttype SMALLINT,@Bettype SMALLINT', @Sporttype, @Bettype
			PRINT 8
		END
	END
	-- Rule 10: Super IsSync= 0, Master IsSync = 1		
	IF @RuleId IN (0,10) AND @SynColumnName <> ''
	BEGIN
		SET @SQLResult = 'SELECT 10 AS RuleID, @Sporttype AS SportType,@Bettype BetType, ci.custid AS MasterID,ci.srecommend,1 AS ValueA, 0 ValueB ,GETDATE() , 1 IsDeposit  
		FROM #Super_Sync S
			INNER JOIN CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON S.CustID = CI.srecommend AND CI.roleid = 3 AND CI.Enabled = 1
		WHERE  CI.username NOT LIKE ''%Acc%''
			AND CI.username NOT LIKE ''%3rdSuper%''
			AND CI.username NOT LIKE ''STEST%''
			AND CI.username NOT LIKE ''%cashout%''
			AND CI.username NOT LIKE ''%dummy%''
			AND ci.username NOT LIKE ''%ClearBal%''
			AND ci.username NOT LIKE ''%OddsAdj%''
			AND CI.username NOT LIKE ''%BetTrade%'' AND CI.' + @SynColumnName + ' = 1   '
		SELECT @SQLResult
		INSERT INTO CheckStatusResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		EXEC sp_executeSQL @SQLResult,N'@Sporttype SMALLINT,@Bettype SMALLINT', @Sporttype, @Bettype
		PRINT 10 
	END	
	-- Rule 11: Master IsSync= 01, Agent IsSync = 1		
	IF @RuleId IN (0,11) AND @SynColumnName <> ''
	BEGIN
		SET @SQLResult = 'SELECT 11, @Sporttype,@Bettype, ci.custid,m.custid,1,0,GETDATE() , 1 
		FROM #Master_Sync m
			INNER JOIN CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON m.CustID = CI.mrecommend AND CI.roleid = 2 AND CI.Enabled = 1
		WHERE  CI.username NOT LIKE ''%Acc%''
			AND CI.username NOT LIKE ''%3rdSuper%''
			AND CI.username NOT LIKE ''STEST%''
			AND CI.username NOT LIKE ''%cashout%''
			AND CI.username NOT LIKE ''%dummy%''
			AND ci.username NOT LIKE ''%ClearBal%''
			AND ci.username NOT LIKE ''%OddsAdj%''
			AND CI.username NOT LIKE ''%BetTrade%'' AND CI.' + @SynColumnName + ' = 1   '
		SELECT @SQLResult
		INSERT INTO CheckStatusResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		EXEC sp_executeSQL @SQLResult,N'@Sporttype SMALLINT,@Bettype SMALLINT', @Sporttype, @Bettype
		PRINT 11
	END	
	-- Rule 12: Agent IsSync= 0, Member IsSync = 1		
	IF @RuleId IN (0,12) AND @SynColumnName <> ''
	BEGIN
		SET @SQLResult = 'SELECT 12, @Sporttype,@Bettype, ci.custid ,a.custid,1,0,GETDATE() , 1
		FROM #Agent_Sync a
			INNER JOIN CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON a.CustID = CI.recommend AND CI.roleid = 1 AND CI.Enabled = 1
		WHERE  CI.username NOT LIKE ''%Acc%''
			AND CI.username NOT LIKE ''%3rdSuper%''
			AND CI.username NOT LIKE ''STEST%''
			AND CI.username NOT LIKE ''%cashout%''
			AND CI.username NOT LIKE ''%dummy%''
			AND ci.username NOT LIKE ''%ClearBal%''
			AND ci.username NOT LIKE ''%OddsAdj%''
			AND CI.username NOT LIKE ''%BetTrade%'' AND CI.' + @SynColumnName + ' = 1  '
		SELECT @SQLResult
		INSERT INTO CheckStatusResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		EXEC sp_executeSQL @SQLResult,N'@Sporttype SMALLINT,@Bettype SMALLINT', @Sporttype, @Bettype
		PRINT 12
	END
	----------------------------FINAL RESULT ------------------------------------
	SET NOCOUNT OFF	
END
