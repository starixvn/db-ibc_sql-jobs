/*<info serverAlias="DBCHECK-CheckResultDB" executers="" viewers="" isFunction="0"></info>*/
USE CheckResultDB
GO


ALTER PROCEDURE [dbo].[DBA_CheckBetLimit_Dep]  
(	 @srecommend	INT   
	,@RuleId		SMALLINT = 0  
 )

AS  
/*  
	Created: 20180817@Winnie
	Task: Monthly check bet limit setting for Deposit
	DB: DBCHECK/CheckResultDB  
	Revisions:  :
		- 20190130@Winnie:	Remove ClearBal Acc - [Redmine: #73556]
		- 20190717@Winnie:	Check Keno - [Redmine: #73556]
	Param's Explanation:   
	 @RuleId = 0 : 'all'  
	 @RuleId IN (317->328)  
*/  
	
BEGIN   
	
	SET NOCOUNT ON   

	IF @srecommend IN(1752415,932209,1574083,179457)--'AB88SuperRM' , '12BETSuperSD$',MS88SuperBND,'ITSA'
	RETURN

	CREATE TABLE #Dummy (CustID INT PRIMARY KEY)
	CREATE TABLE #Agent (CustID INT PRIMARY KEY)
	CREATE TABLE #Trade (CustID INT PRIMARY KEY)
	DECLARE @HideKeno BIT
	DECLARE @DisableKeno BIT
	
	SELECT @HideKeno=HideKeno FROM CheckCustDB.dbo.custInfo WITH(NOLOCK) WHERE custid=@srecommend
	SELECT @DisableKeno=IsDisabled FROM CheckCustDB.dbo.CustgameType WITH(NOLOCK) WHERE custid=@srecommend AND GameTypeID=1	

	INSERT INTO #Dummy(CustID)
	SELECT CustID FROM CheckCustDB.dbo.Customer WITH(NOLOCK) WHERE srecommend=@srecommend AND roleid=3 AND (username LIKE '%Acc%' OR username LIKE '%LocalBank%' OR username LIKE '%AFF%'
																												OR username LIKE 'AB88'+'CAS%' )

	INSERT INTO #Agent(CustID)
	SELECT CustID FROM CheckCustDB.dbo.Customer WITH(NOLOCK) WHERE username IN('12BETSD$02','12BETSD$01')
	UNION
	SELECT CustID FROM CheckCustDB.dbo.Customer WITH(NOLOCK) WHERE mrecommend IN(SELECT custid FROM #Dummy) AND roleID=2

	INSERT INTO #Trade(CustID)
	SELECT CustID FROM CheckCustDB.dbo.Customer WITH(NOLOCK) WHERE srecommend=@srecommend AND roleid=1 AND (username LIKE '%Bettrade%' OR username LIKE '%CashOut%' OR username LIKE '%ClearBal%')
	UNION
	SELECT CustID FROM CheckCustDB.dbo.Customer WITH(NOLOCK) WHERE recommend IN(SELECT custid FROM #Agent) AND roleID=1
	UNION
	SELECT CustID FROM CheckCustDB.dbo.Customer WITH(NOLOCK) WHERE mrecommend IN(SELECT custid FROM #Dummy) AND roleID=1

	IF @RuleId IN (0,317)  
	BEGIN  
		CREATE TABLE #SuperSetting	(SporttypeID INT,BettypeID INT,Num INT, PRIMARY KEY(SporttypeID,BettypeID))
		CREATE TABLE #MasterSetting	(CustID INT,SporttypeID INT,BettypeID INT,Num INT,PRIMARY KEY(CustID,SporttypeID,BettypeID))
		CREATE TABLE #AgentSetting	(CustID INT,SporttypeID INT,BettypeID INT,Num INT, PRIMARY KEY(CustID,SporttypeID,BettypeID))
		CREATE TABLE #MemberSetting	(CustID INT,SporttypeID INT,BettypeID INT,Num INT, PRIMARY KEY(CustID,SporttypeID,BettypeID))

		INSERT INTO #SuperSetting(SporttypeID ,BettypeID ,Num)
		SELECT cs.sporttype,cs.bettype,COUNT(cs.custid)
		FROM CheckCustDB.dbo.Dep_CustSetting cs WITH(NOLOCK) 			
		WHERE cs.custid=@srecommend AND sporttype NOT BETWEEN 151 AND 154
		GROUP BY cs.custid,cs.sporttype,cs.bettype

		INSERT INTO #MasterSetting(CustID ,SporttypeID ,BettypeID ,Num)
		SELECT c.custid,cs.sporttype,cs.bettype,COUNT(c.custid)
		FROM CheckCustDB.dbo.Dep_CustSetting cs WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON cs.Custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=3 AND sporttype NOT BETWEEN 151 AND 154
			AND c.custid NOT IN(SELECT custid FROM #Dummy)
		GROUP BY c.custid,cs.sporttype,cs.bettype

		INSERT INTO #AgentSetting(CustID ,SporttypeID ,BettypeID ,Num)
		SELECT c.custid,cs.sporttype,cs.bettype,COUNT(cs.custid)
		FROM CheckCustDB.dbo.Dep_CustSetting cs WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON cs.Custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=2 AND sporttype NOT BETWEEN 151 AND 154
			AND c.custid NOT IN(SELECT custid FROM #Agent)
		GROUP BY c.custid,cs.sporttype,cs.bettype

		INSERT INTO #MemberSetting(CustID ,SporttypeID ,BettypeID ,Num)
		SELECT c.custid,cs.sporttype,cs.bettype,COUNT(c.custid)
		FROM CheckCustDB.dbo.Dep_CustSetting cs WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON cs.Custid=c.custid
		WHERE c.srecommend=@srecommend AND sporttype NOT BETWEEN 151 AND 154
			AND c.roleid=1 
			AND c.custid NOT IN(SELECT custid FROM #Trade)		
		GROUP BY c.custid,cs.sporttype,cs.bettype,c.recommend

		IF EXISTS(SELECT TOP 1 1 FROM #MasterSetting)
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 317,s.SporttypeID,s.BettypeID,@srecommend,m.CustID,s.Num,m.Num,GETDATE(),1
			FROM #SuperSetting s
				LEFT JOIN #MasterSetting m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID
			WHERE m.CustID IS NULL OR s.Num<>m.Num
		
		IF EXISTS(SELECT TOP 1 1 FROM #AgentSetting)
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 317,s.SporttypeID,s.BettypeID,@srecommend,m.CustID,s.Num,m.Num,GETDATE(),1
			FROM #SuperSetting s
				LEFT JOIN #AgentSetting m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID
			WHERE m.CustID IS NULL OR s.Num<>m.Num

		IF EXISTS(SELECT TOP 1 1 FROM #MemberSetting)
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 317,s.SporttypeID,s.BettypeID,@srecommend,m.CustID,s.Num,m.Num,GETDATE(),1
			FROM #SuperSetting s
				LEFT JOIN #MemberSetting m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID
			WHERE m.CustID IS NULL OR s.Num<>m.Num

		TRUNCATE TABLE #SuperSetting
		TRUNCATE TABLE #MasterSetting
		TRUNCATE TABLE #AgentSetting
		TRUNCATE TABLE #MemberSetting

		INSERT INTO #SuperSetting(SporttypeID ,BettypeID ,Num)
		SELECT cs.sporttype,cs.bettype,COUNT(cs.custid)
		FROM CheckCustDB.dbo.Dep_CustSetting3rd cs WITH(NOLOCK) 			
		WHERE cs.custid=@srecommend AND sporttype NOT BETWEEN 151 AND 154
		GROUP BY cs.custid,cs.sporttype,cs.bettype

		INSERT INTO #MasterSetting(CustID ,SporttypeID ,BettypeID ,Num)
		SELECT c.custid,cs.sporttype,cs.bettype,COUNT(c.custid)
		FROM CheckCustDB.dbo.Dep_CustSetting3rd cs WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON cs.Custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=3 AND sporttype NOT BETWEEN 151 AND 154
			AND c.custid NOT IN(SELECT custid FROM #Dummy)
		GROUP BY c.custid,cs.sporttype,cs.bettype

		INSERT INTO #AgentSetting(CustID ,SporttypeID ,BettypeID ,Num)
		SELECT c.custid,cs.sporttype,cs.bettype,COUNT(c.custid)
		FROM CheckCustDB.dbo.Dep_CustSetting3rd cs WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON cs.Custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=2 AND sporttype NOT BETWEEN 151 AND 154
			AND c.custid NOT IN(SELECT custid FROM #Agent)
		GROUP BY c.custid,cs.sporttype,cs.bettype

		INSERT INTO #MemberSetting(CustID ,SporttypeID ,BettypeID ,Num)
		SELECT c.custid,cs.sporttype,cs.bettype,COUNT(c.custid)
		FROM CheckCustDB.dbo.Dep_CustSetting3rd cs WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON cs.Custid=c.custid
		WHERE c.srecommend=@srecommend 
			AND c.roleid=1 
			AND c.custid NOT IN(SELECT custid FROM #Trade)	
			AND sporttype NOT BETWEEN 151 AND 154
		GROUP BY c.custid,cs.sporttype,cs.bettype
		
		IF EXISTS(SELECT TOP 1 1 FROM #MasterSetting)
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 317,s.SporttypeID,s.BettypeID,@srecommend,m.CustID,s.Num,m.Num,GETDATE(),1
			FROM #SuperSetting s
				LEFT JOIN #MasterSetting m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID
			WHERE m.CustID IS NULL OR s.Num<>m.Num		
		
		IF EXISTS(SELECT TOP 1 1 FROM #AgentSetting)
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 317,s.SporttypeID,s.BettypeID,@srecommend,m.CustID,s.Num,m.Num,GETDATE(),1
			FROM #SuperSetting s
				LEFT JOIN #AgentSetting m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID
			WHERE m.CustID IS NULL OR s.Num<>m.Num

		IF EXISTS(SELECT TOP 1 1 FROM #MemberSetting)
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 317,s.SporttypeID,s.BettypeID,@srecommend,m.CustID,s.Num,m.Num,GETDATE(),1
			FROM #SuperSetting s
				LEFT JOIN #MemberSetting m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID
			WHERE m.CustID IS NULL OR s.Num<>m.Num

		TRUNCATE TABLE #SuperSetting
		TRUNCATE TABLE #MasterSetting
		TRUNCATE TABLE #AgentSetting
		TRUNCATE TABLE #MemberSetting

		INSERT INTO #SuperSetting(SporttypeID ,BettypeID ,Num)
		SELECT cs.sporttype,cs.bettype,COUNT(cs.custid)
		FROM CheckCustDB.dbo.Dep_CustSettingGame cs WITH(NOLOCK) 			
		WHERE cs.CustID=@srecommend AND cs.sporttype<>203
		GROUP BY cs.custid,cs.sporttype,cs.bettype

		INSERT INTO #MasterSetting(CustID ,SporttypeID ,BettypeID ,Num)
		SELECT c.custid,cs.sporttype,cs.bettype,COUNT(c.custid)
		FROM CheckCustDB.dbo.Dep_CustSettingGame cs WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON cs.Custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=3 AND cs.sporttype<>203
			AND c.custid NOT IN(SELECT custid FROM #Dummy)
		GROUP BY c.custid,cs.sporttype,cs.bettype

		INSERT INTO #AgentSetting(CustID ,SporttypeID ,BettypeID ,Num)
		SELECT c.custid,cs.sporttype,cs.bettype,COUNT(c.custid)
		FROM CheckCustDB.dbo.Dep_CustSettingGame cs WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON cs.Custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=2 AND cs.sporttype<>203
			AND c.custid NOT IN(SELECT custid FROM #Agent)
		GROUP BY c.custid,cs.sporttype,cs.bettype

		INSERT INTO #MemberSetting(CustID ,SporttypeID ,BettypeID ,Num)
		SELECT c.custid,cs.sporttype,cs.bettype,COUNT(c.custid)
		FROM CheckCustDB.dbo.Dep_CustSettingGame cs WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON cs.Custid=c.custid
		WHERE c.srecommend=@srecommend 
			AND c.roleid=1 
			AND c.custid NOT IN(SELECT custid FROM #Trade)
			AND cs.sporttype<>203		
		GROUP BY c.custid,cs.sporttype,cs.bettype

		IF EXISTS(SELECT TOP 1 1 FROM #MasterSetting)
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 317,s.SporttypeID,s.BettypeID,@srecommend,m.CustID,s.Num,m.Num,GETDATE(),1
			FROM #SuperSetting s
				LEFT JOIN #MasterSetting m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID
			WHERE m.CustID IS NULL OR s.Num<>m.Num
		
		IF EXISTS(SELECT TOP 1 1 FROM #AgentSetting)
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 317,s.SporttypeID,s.BettypeID,@srecommend,m.CustID,s.Num,m.Num,GETDATE(),1
			FROM #SuperSetting s
				LEFT JOIN #AgentSetting m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID
			WHERE m.CustID IS NULL OR s.Num<>m.Num

		IF EXISTS(SELECT TOP 1 1 FROM #MemberSetting)
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 317,s.SporttypeID,s.BettypeID,@srecommend,m.CustID,s.Num,m.Num,GETDATE(),1
			FROM #SuperSetting s
				LEFT JOIN #MemberSetting m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID
			WHERE m.CustID IS NULL OR s.Num<>m.Num

		TRUNCATE TABLE #SuperSetting
		TRUNCATE TABLE #MasterSetting
		TRUNCATE TABLE #AgentSetting
		TRUNCATE TABLE #MemberSetting

		INSERT INTO #SuperSetting(SporttypeID ,BettypeID ,Num)
		SELECT cs.sporttype,cs.bettype,COUNT(cs.custid)
		FROM CheckCustDB.dbo.Dep_CustBetSetting_Agent cs WITH(NOLOCK) 
		WHERE cs.CustID=@srecommend  
		GROUP BY cs.custid,cs.sporttype,cs.bettype

		INSERT INTO #MasterSetting(CustID ,SporttypeID ,BettypeID ,Num)
		SELECT c.custid,cs.sporttype,cs.bettype,COUNT(c.custid)
		FROM CheckCustDB.dbo.Dep_CustBetSetting_Agent cs WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON cs.Custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=3 
			AND c.custid NOT IN(SELECT custid FROM #Dummy)
		GROUP BY c.custid,cs.sporttype,cs.bettype

		INSERT INTO #AgentSetting(CustID ,SporttypeID ,BettypeID ,Num)
		SELECT c.custid,cs.sporttype,cs.bettype,COUNT(c.custid)
		FROM CheckCustDB.dbo.Dep_CustBetSetting_Agent cs WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON cs.Custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=2
			AND c.custid NOT IN(SELECT custid FROM #Agent)
		GROUP BY c.custid,cs.sporttype,cs.bettype

		INSERT INTO #MemberSetting(CustID ,SporttypeID ,BettypeID ,Num)
		SELECT c.custid,cs.sporttype,cs.bettype,COUNT(c.custid)
		FROM CheckCustDB.dbo.Dep_CustBetSetting_Member cs WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON cs.Custid=c.custid
		WHERE c.srecommend=@srecommend 
			AND c.roleid=1 
			AND c.custid NOT IN(SELECT custid FROM #Trade)			
		GROUP BY c.custid,cs.sporttype,cs.bettype

		IF EXISTS(SELECT TOP 1 1 FROM #MasterSetting)
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 317,s.SporttypeID,s.BettypeID,@srecommend,m.CustID,s.Num,m.Num,GETDATE(),1
			FROM #SuperSetting s
				LEFT JOIN #MasterSetting m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID
			WHERE m.CustID IS NULL OR s.Num<>m.Num
		
		IF EXISTS(SELECT TOP 1 1 FROM #AgentSetting)
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 317,s.SporttypeID,s.BettypeID,@srecommend,m.CustID,s.Num,m.Num,GETDATE(),1
			FROM #SuperSetting s
				LEFT JOIN #AgentSetting m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID
			WHERE m.CustID IS NULL OR s.Num<>m.Num

		IF EXISTS(SELECT TOP 1 1 FROM #MemberSetting)
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 317,s.SporttypeID,s.BettypeID,@srecommend,m.CustID,s.Num,m.Num,GETDATE(),1
			FROM #SuperSetting s
				LEFT JOIN #MemberSetting m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID
			WHERE m.CustID IS NULL OR s.Num<>m.Num

		-- 
		IF @HideKeno=0 AND @DisableKeno=0
		BEGIN
			TRUNCATE TABLE #SuperSetting
			TRUNCATE TABLE #MasterSetting
			TRUNCATE TABLE #AgentSetting
			TRUNCATE TABLE #MemberSetting

			INSERT INTO #SuperSetting(SporttypeID ,BettypeID ,Num)
			SELECT 202,1501,COUNT(cs.custid)
			FROM CheckCustDB.dbo.CustGameType cs WITH(NOLOCK) 
			WHERE cs.CustID=@srecommend  AND cs.GameTypeID=1
			GROUP BY cs.custid,cs.GameTypeID

			INSERT INTO #MasterSetting(CustID ,SporttypeID ,BettypeID ,Num)
			SELECT c.custid,202,1501,COUNT(cs.custid)
			FROM CheckCustDB.dbo.custInfo c WITH(NOLOCK) 
				LEFT JOIN CheckCustDB.dbo.CustGameType cs WITH(NOLOCK)  ON cs.Custid=c.custid AND cs.GameTypeID=1
			WHERE c.srecommend=@srecommend AND c.roleid=3 
				AND c.custid NOT IN(SELECT custid FROM #Dummy)
			GROUP BY c.custid,cs.GameTypeID

			INSERT INTO #AgentSetting(CustID ,SporttypeID ,BettypeID ,Num)
			SELECT c.custid,202,1501,COUNT(cs.custid)
			FROM CheckCustDB.dbo.custInfo c WITH(NOLOCK) 
				LEFT JOIN  CheckCustDB.dbo.CustGameType cs WITH(NOLOCK)   ON cs.Custid=c.custid  AND cs.GameTypeID=1
			WHERE c.srecommend=@srecommend AND c.roleid=2
				AND c.custid NOT IN(SELECT custid FROM #Agent)
			GROUP BY c.custid,cs.GameTypeID

			INSERT INTO #MemberSetting(CustID ,SporttypeID ,BettypeID ,Num)
			SELECT c.custid,202,1501,COUNT(cs.custid)
			FROM  CheckCustDB.dbo.custInfo c WITH(NOLOCK)
				LEFT JOIN CheckCustDB.dbo.CustGameType cs WITH(NOLOCK)  ON cs.Custid=c.custid  AND cs.GameTypeID=1
			WHERE c.srecommend=@srecommend
				AND c.roleid=1 
				AND c.custid NOT IN(SELECT custid FROM #Trade)			
			GROUP BY c.custid,cs.GameTypeID

			IF EXISTS(SELECT TOP 1 1 FROM #MasterSetting)
				INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
				SELECT 317,s.SporttypeID,s.BettypeID,@srecommend,m.CustID,s.Num,m.Num,GETDATE(),1
				FROM #SuperSetting s
					LEFT JOIN #MasterSetting m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID
				WHERE m.CustID IS NULL OR s.Num<>m.Num
		
			IF EXISTS(SELECT TOP 1 1 FROM #AgentSetting)
				INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
				SELECT 317,s.SporttypeID,s.BettypeID,@srecommend,m.CustID,s.Num,m.Num,GETDATE(),1
				FROM #SuperSetting s
					LEFT JOIN #AgentSetting m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID
				WHERE m.CustID IS NULL OR s.Num<>m.Num

			IF EXISTS(SELECT TOP 1 1 FROM #MemberSetting)
				INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
				SELECT 317,s.SporttypeID,s.BettypeID,@srecommend,m.CustID,s.Num,m.Num,GETDATE(),1
				FROM #SuperSetting s
					LEFT JOIN #MemberSetting m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID
				WHERE m.CustID IS NULL OR s.Num<>m.Num
		END
	END  
	IF @RuleId IN(0,318)
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 318,s.sporttype,s.bettype,s.CustID,NULL,Minbet,NULL,GETDATE(),1
		FROM CheckCustDB.dbo.Dep_CustSetting s WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend 
			AND s.minbet<0  			
			AND c.custid NOT IN(SELECT custid FROM #Trade)
			AND c.custid NOT IN(SELECT custid FROM #Dummy)
			AND c.custid NOT IN(SELECT custid FROM #Agent)
			AND sporttype NOT BETWEEN 151 AND 154

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 318,s.sporttype,s.bettype,s.CustID,NULL,Minbet,NULL,GETDATE(),1
		FROM CheckCustDB.dbo.Dep_CustSetting3rd s WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend 
			AND s.minbet<0  				
			AND c.custid NOT IN(SELECT custid FROM #Trade)
			AND c.custid NOT IN(SELECT custid FROM #Dummy)
			AND c.custid NOT IN(SELECT custid FROM #Agent)
			AND sporttype NOT BETWEEN 151 AND 154

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 318,s.sporttype,s.bettype,s.CustID,NULL,Minbet,NULL,GETDATE(),1
		FROM CheckCustDB.dbo.Dep_CustBetSetting_Agent s WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend 
			AND s.minbet<0  			
			AND c.custid NOT IN(SELECT custid FROM #Trade)
			AND c.custid NOT IN(SELECT custid FROM #Dummy)
			AND c.custid NOT IN(SELECT custid FROM #Agent)
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 318,s.sporttype,s.bettype,s.CustID,NULL,Minbet,NULL,GETDATE(),1
		FROM CheckCustDB.dbo.Dep_CustBetSetting_Member s WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend 
			AND s.minbet<0  			
			AND c.custid NOT IN(SELECT custid FROM #Trade)
			AND c.custid NOT IN(SELECT custid FROM #Dummy)
			AND c.custid NOT IN(SELECT custid FROM #Agent)

		IF (@HideKeno=0 AND @DisableKeno=0)
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 318,202,1501,s.CustID,NULL,Minbet,NULL,GETDATE(),1
			FROM CheckCustDB.dbo.CustGameType s WITH(NOLOCK) 
				INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON s.custid=c.custid
			WHERE c.srecommend=@srecommend AND s.GameTypeID=1
				AND s.minbet<0  			
				AND c.custid NOT IN(SELECT custid FROM #Trade)
				AND c.custid NOT IN(SELECT custid FROM #Dummy)
				AND c.custid NOT IN(SELECT custid FROM #Agent)
		END
	END
	IF @RuleId IN (0,319)  
	BEGIN
		CREATE TABLE #Super319	(SporttypeID INT,BettypeID INT,Minbet MONEY,IsLive BIT, PRIMARY KEY(SporttypeID,BettypeID,IsLive))
		CREATE TABLE #Master319	(CustID INT,SporttypeID INT,BettypeID INT,Minbet MONEY,IsLive BIT, PRIMARY KEY(CustID,SporttypeID,BettypeID,IsLive))
		CREATE TABLE #Agent319	(CustID INT,SporttypeID INT,BettypeID INT,Minbet MONEY,IsLive BIT,mrecommend INT, PRIMARY KEY(CustID,SporttypeID,BettypeID,IsLive,mrecommend))		

		INSERT INTO #Super319(SporttypeID ,BettypeID,IsLive ,Minbet)
		SELECT cs.sporttype,cs.bettype,cs.islive,Minbet
		FROM CheckCustDB.dbo.Dep_CustSetting cs WITH(NOLOCK) 			
		WHERE cs.custid=@srecommend AND sporttype NOT BETWEEN 151 AND 154				
		
		INSERT INTO #Master319(CustID ,SporttypeID ,BettypeID,IsLive ,Minbet)
		SELECT c.custid,cs.sporttype,cs.bettype,cs.islive,Minbet
		FROM CheckCustDB.dbo.Dep_CustSetting cs WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON cs.Custid=c.custid
		WHERE c.srecommend=@srecommend 
			AND c.roleid=3 		
			AND c.custid NOT IN(SELECT custid FROM #Dummy)		
			AND sporttype NOT BETWEEN 151 AND 154		

		INSERT INTO #Agent319(CustID ,SporttypeID ,BettypeID,IsLive ,Minbet,mrecommend)
		SELECT cs.custid,cs.sporttype,cs.bettype,cs.islive,Minbet,mrecommend
		FROM CheckCustDB.dbo.Dep_CustSetting cs WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON cs.Custid=c.custid
		WHERE c.srecommend=@srecommend 
			AND c.roleid=2 
			AND c.custid NOT IN(SELECT custid FROM #Agent)	
			AND sporttype NOT BETWEEN 151 AND 154

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 319,s.SporttypeID,s.BettypeID,@srecommend,m.CustID,s.Minbet,m.Minbet,GETDATE(),1
		FROM #Super319 s
			INNER JOIN #Master319 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.IsLive=m.IsLive
		WHERE s.Minbet>m.Minbet
			
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 319,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.Minbet,m.Minbet,GETDATE(),1
		FROM #Master319 s
			INNER JOIN #Agent319 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.IsLive=m.IsLive AND m.mrecommend=s.CustID
		WHERE s.Minbet>m.Minbet

		TRUNCATE TABLE #Super319
		TRUNCATE TABLE #Master319
		TRUNCATE TABLE #Agent319

		INSERT INTO #Super319(SporttypeID ,BettypeID,IsLive ,Minbet)
		SELECT cs.sporttype,cs.bettype,cs.islive,Minbet
		FROM CheckCustDB.dbo.Dep_CustSetting3rd cs WITH(NOLOCK) 			
		WHERE cs.custid=@srecommend 
			AND sporttype NOT BETWEEN 151 AND 154	
		
		INSERT INTO #Master319(CustID ,SporttypeID ,BettypeID,IsLive ,Minbet)
		SELECT c.custid,cs.sporttype,cs.bettype,cs.islive,Minbet
		FROM CheckCustDB.dbo.Dep_CustSetting3rd cs WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON cs.Custid=c.custid
		WHERE c.srecommend=@srecommend 
			AND c.roleid=3  
			AND c.custid NOT IN(SELECT custid FROM #Dummy)	
			AND sporttype NOT BETWEEN 151 AND 154	

		INSERT INTO #Agent319(CustID ,SporttypeID ,BettypeID,IsLive ,Minbet,mrecommend)
		SELECT cs.custid,cs.sporttype,cs.bettype,cs.islive,Minbet,mrecommend
		FROM CheckCustDB.dbo.Dep_CustSetting3rd cs WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON cs.Custid=c.custid
		WHERE c.srecommend=@srecommend 
			AND c.roleid=2 
			AND c.custid NOT IN(SELECT custid FROM #Agent)		
			AND sporttype NOT BETWEEN 151 AND 154		

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 319,s.SporttypeID,s.BettypeID,@srecommend,m.CustID,s.Minbet,m.Minbet,GETDATE(),1
		FROM #Super319 s
			INNER JOIN #Master319 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.IsLive=m.IsLive
		WHERE s.Minbet>m.Minbet
			
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 319,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.Minbet,m.Minbet,GETDATE(),1
		FROM #Master319 s
			INNER JOIN #Agent319 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.IsLive=m.IsLive AND s.CustID=m.mrecommend
		WHERE s.Minbet>m.Minbet

		TRUNCATE TABLE #Super319
		TRUNCATE TABLE #Master319
		TRUNCATE TABLE #Agent319

		INSERT INTO #Super319(SporttypeID ,BettypeID,IsLive ,Minbet)
		SELECT cs.sporttype,cs.bettype,0,Minbet
		FROM CheckCustDB.dbo.Dep_CustBetSetting_Agent cs WITH(NOLOCK) 			
		WHERE cs.custid=@srecommend
		
		INSERT INTO #Master319(CustID ,SporttypeID ,BettypeID,IsLive ,Minbet)
		SELECT c.custid,cs.sporttype,cs.bettype,0,Minbet
		FROM CheckCustDB.dbo.Dep_CustBetSetting_Agent cs WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON cs.Custid=c.custid
		WHERE c.srecommend=@srecommend 
			AND c.roleid=3  
			AND c.custid NOT IN(SELECT custid FROM #Dummy)			

		INSERT INTO #Agent319(CustID ,SporttypeID ,BettypeID,IsLive ,Minbet,mrecommend)
		SELECT cs.custid,cs.sporttype,cs.bettype,0,Minbet,mrecommend
		FROM CheckCustDB.dbo.Dep_CustBetSetting_Agent cs WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON cs.Custid=c.custid
		WHERE c.srecommend=@srecommend 
			AND c.roleid=2 
			AND c.custid NOT IN(SELECT custid FROM #Agent)		

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 319,s.SporttypeID,s.BettypeID,@srecommend,m.CustID,s.Minbet,m.Minbet,GETDATE(),1
		FROM #Super319 s
			INNER JOIN #Master319 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.IsLive=m.IsLive
		WHERE s.Minbet>m.Minbet
			
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 319,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.Minbet,m.Minbet,GETDATE(),1
		FROM #Master319 s
			INNER JOIN #Agent319 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.IsLive=m.IsLive AND s.CustID=m.mrecommend
		WHERE s.Minbet>m.Minbet

		--
		IF @DisableKeno=0 AND @HideKeno=0
		BEGIN
			TRUNCATE TABLE #Super319
			TRUNCATE TABLE #Master319
			TRUNCATE TABLE #Agent319

			INSERT INTO #Super319(SporttypeID ,BettypeID,IsLive ,Minbet)
			SELECT 202,1501,0,Minbet
			FROM CheckCustDB.dbo.CustGameType cs WITH(NOLOCK) 			
			WHERE cs.custid=@srecommend AND cs.GameTypeID=1
		
			INSERT INTO #Master319(CustID ,SporttypeID ,BettypeID,IsLive ,Minbet)
			SELECT c.custid, 202,1501,0,Minbet
			FROM CheckCustDB.dbo.CustGameType cs WITH(NOLOCK) 
				INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON cs.Custid=c.custid
			WHERE c.srecommend=@srecommend AND cs.GameTypeID=1
				AND c.roleid=3  
				AND c.custid NOT IN(SELECT custid FROM #Dummy)			

			INSERT INTO #Agent319(CustID ,SporttypeID ,BettypeID,IsLive ,Minbet,mrecommend)
			SELECT cs.custid, 202,1501,0,Minbet,mrecommend
			FROM CheckCustDB.dbo.CustGameType cs WITH(NOLOCK) 
				INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON cs.Custid=c.custid
			WHERE c.srecommend=@srecommend AND cs.GameTypeID=1
				AND c.roleid=2 
				AND c.custid NOT IN(SELECT custid FROM #Agent)		

			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 319,s.SporttypeID,s.BettypeID,@srecommend,m.CustID,s.Minbet,m.Minbet,GETDATE(),1
			FROM #Super319 s
				INNER JOIN #Master319 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.IsLive=m.IsLive
			WHERE s.Minbet>m.Minbet
			
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 319,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.Minbet,m.Minbet,GETDATE(),1
			FROM #Master319 s
				INNER JOIN #Agent319 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.IsLive=m.IsLive AND s.CustID=m.mrecommend
			WHERE s.Minbet>m.Minbet
		END
	END
	IF @RuleId IN(0,320)
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 320,s.sporttype,s.bettype,s.CustID,NULL,Maxbet,NULL,GETDATE(),1
		FROM CheckCustDB.dbo.Dep_CustSetting s WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend 
			AND s.Maxbet<0 			
			AND c.custid NOT IN(SELECT custid FROM #Trade)
			AND c.custid NOT IN(SELECT custid FROM #Dummy)
			AND c.custid NOT IN(SELECT custid FROM #Agent)
			AND sporttype NOT BETWEEN 151 AND 154

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 320,s.sporttype,s.bettype,s.CustID,NULL,Maxbet,NULL,GETDATE(),1
		FROM CheckCustDB.dbo.Dep_CustSetting3rd s WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND s.Maxbet<0 
			AND c.custid NOT IN(SELECT custid FROM #Trade)
			AND sporttype NOT BETWEEN 151 AND 154	

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 320,s.sporttype,s.bettype,s.CustID,NULL,Maxbet,NULL,GETDATE(),1
		FROM CheckCustDB.dbo.Dep_CustBetSetting_Agent s WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND s.Maxbet<0
			AND c.custid NOT IN(SELECT custid FROM #Trade)
			AND c.custid NOT IN(SELECT custid FROM #Dummy)
			AND c.custid NOT IN(SELECT custid FROM #Agent)
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 320,s.sporttype,s.bettype,s.CustID,NULL,Maxbet,NULL,GETDATE(),1
		FROM CheckCustDB.dbo.Dep_CustBetSetting_Member s WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND s.Maxbet<0 
			AND c.custid NOT IN(SELECT custid FROM #Trade)
			AND c.custid NOT IN(SELECT custid FROM #Dummy)
			AND c.custid NOT IN(SELECT custid FROM #Agent)

		IF @DisableKeno=0 AND @HideKeno=0
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 320,202,1501,s.CustID,NULL,Maxbet,NULL,GETDATE(),1
			FROM CheckCustDB.dbo.CustGameType s WITH(NOLOCK) 
				INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON s.custid=c.custid
			WHERE c.srecommend=@srecommend AND s.Maxbet<0 AND s.GameTypeID=1
				AND c.custid NOT IN(SELECT custid FROM #Trade)
				AND c.custid NOT IN(SELECT custid FROM #Dummy)
				AND c.custid NOT IN(SELECT custid FROM #Agent)
		END
	END
	IF @RuleId IN (0,321)  
	BEGIN
		CREATE TABLE #Super321	(SporttypeID INT,BettypeID INT,Maxbet MONEY,IsLive BIT, PRIMARY KEY(SporttypeID,BettypeID,IsLive))
		CREATE TABLE #Master321	(CustID INT,SporttypeID INT,BettypeID INT,Maxbet MONEY,IsLive BIT, PRIMARY KEY(CustID,SporttypeID,BettypeID,IsLive))
		CREATE TABLE #Agent321	(CustID INT,SporttypeID INT,BettypeID INT,Maxbet MONEY,IsLive BIT,mrecommend INT, PRIMARY KEY(CustID,SporttypeID,BettypeID,IsLive,mrecommend))		

		INSERT INTO #Super321(SporttypeID ,BettypeID,IsLive ,Maxbet)
		SELECT cs.sporttype,cs.bettype,cs.islive,Maxbet
		FROM CheckCustDB.dbo.Dep_CustSetting cs WITH(NOLOCK) 			
		WHERE cs.custid=@srecommend	
			AND sporttype NOT BETWEEN 151 AND 154		
		
		INSERT INTO #Master321(CustID ,SporttypeID ,BettypeID,IsLive ,Maxbet)
		SELECT c.custid,cs.sporttype,cs.bettype,cs.islive,Maxbet
		FROM CheckCustDB.dbo.Dep_CustSetting cs WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON cs.Custid=c.custid
		WHERE c.srecommend=@srecommend 
			AND c.roleid=3  
			AND c.custid NOT IN(SELECT custid FROM #Dummy)
			AND sporttype NOT BETWEEN 151 AND 154			

		INSERT INTO #Agent321(CustID ,SporttypeID ,BettypeID,IsLive ,Maxbet,mrecommend)
		SELECT cs.custid,cs.sporttype,cs.bettype,cs.islive,Maxbet,mrecommend
		FROM CheckCustDB.dbo.Dep_CustSetting cs WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON cs.Custid=c.custid
		WHERE c.srecommend=@srecommend 
			AND c.roleid=2	
			AND c.custid NOT IN(SELECT custid FROM #Agent)	
			AND sporttype NOT BETWEEN 151 AND 154		

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 321,s.SporttypeID,s.BettypeID,@srecommend,m.CustID,s.Maxbet,m.Maxbet,GETDATE(),1
		FROM #Super321 s
			INNER JOIN #Master321 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.IsLive=m.IsLive
		WHERE s.Maxbet<m.Maxbet
			
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 321,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.Maxbet,m.Maxbet,GETDATE(),1
		FROM #Master321 s
			INNER JOIN #Agent321 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.IsLive=m.IsLive AND s.CustID=m.mrecommend
		WHERE s.Maxbet<m.Maxbet

		TRUNCATE TABLE #Super321
		TRUNCATE TABLE #Master321
		TRUNCATE TABLE #Agent321
				
		INSERT INTO #Super321(SporttypeID ,BettypeID,IsLive ,Maxbet)
		SELECT cs.sporttype,cs.bettype,cs.islive,Maxbet
		FROM CheckCustDB.dbo.Dep_CustSetting3rd cs WITH(NOLOCK) 			
		WHERE cs.custid=@srecommend AND sporttype NOT BETWEEN 151 AND 154			
		
		INSERT INTO #Master321(CustID ,SporttypeID ,BettypeID,IsLive ,Maxbet)
		SELECT c.custid,cs.sporttype,cs.bettype,cs.islive,Maxbet
		FROM CheckCustDB.dbo.Dep_CustSetting3rd cs WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON cs.Custid=c.custid
		WHERE c.srecommend=@srecommend 
			AND c.roleid=3  
			AND c.custid NOT IN(SELECT custid FROM #Dummy) 	
			AND sporttype NOT BETWEEN 151 AND 154			

		INSERT INTO #Agent321(CustID ,SporttypeID ,BettypeID,IsLive ,Maxbet,mrecommend)
		SELECT cs.custid,cs.sporttype,cs.bettype,cs.islive,Maxbet,mrecommend
		FROM CheckCustDB.dbo.Dep_CustSetting3rd cs WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON cs.Custid=c.custid
		WHERE c.srecommend=@srecommend 
			AND c.roleid=2 
			AND c.custid NOT IN(SELECT custid FROM #Agent)		
			AND sporttype NOT BETWEEN 151 AND 154			

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 321,s.SporttypeID,s.BettypeID,@srecommend,m.CustID,s.Maxbet,m.Maxbet,GETDATE(),1
		FROM #Super321 s
			INNER JOIN #Master321 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.IsLive=m.IsLive
		WHERE s.Maxbet<m.Maxbet		
			
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 321,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.Maxbet,m.Maxbet,GETDATE(),1
		FROM #Master321 s
			INNER JOIN #Agent321 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.IsLive=m.IsLive AND s.CustID=m.mrecommend
		WHERE s.Maxbet<m.Maxbet

		TRUNCATE TABLE #Super321
		TRUNCATE TABLE #Master321
		TRUNCATE TABLE #Agent321
				
		INSERT INTO #Super321(SporttypeID ,BettypeID,IsLive ,Maxbet)
		SELECT cs.sporttype,cs.bettype,0,Maxbet
		FROM CheckCustDB.dbo.Dep_CustBetSetting_Agent cs WITH(NOLOCK) 			
		WHERE cs.custid=@srecommend
		
		INSERT INTO #Master321(CustID ,SporttypeID ,BettypeID,IsLive ,Maxbet)
		SELECT c.custid,cs.sporttype,cs.bettype,0,Maxbet
		FROM CheckCustDB.dbo.Dep_CustBetSetting_Agent cs WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON cs.Custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=3  AND c.custid NOT IN(SELECT custid FROM #Dummy)

		INSERT INTO #Agent321(CustID ,SporttypeID ,BettypeID,IsLive ,Maxbet,mrecommend)
		SELECT cs.custid,cs.sporttype,cs.bettype,0,Maxbet,mrecommend
		FROM CheckCustDB.dbo.Dep_CustBetSetting_Agent cs WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON cs.Custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=2 AND c.custid NOT IN(SELECT custid FROM #Agent)	

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 321,s.SporttypeID,s.BettypeID,@srecommend,m.CustID,s.Maxbet,m.Maxbet,GETDATE(),1
		FROM #Super321 s
			INNER JOIN #Master321 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.IsLive=m.IsLive
		WHERE s.Maxbet<m.Maxbet
			
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 321,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.Maxbet,m.Maxbet,GETDATE(),1
		FROM #Master321 s
			INNER JOIN #Agent321 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.IsLive=m.IsLive AND s.CustID=m.mrecommend
		WHERE s.Maxbet<m.Maxbet

		IF @DisableKeno=0 AND @HideKeno=0
		BEGIN
			TRUNCATE TABLE #Super321
			TRUNCATE TABLE #Master321
			TRUNCATE TABLE #Agent321
				
			INSERT INTO #Super321(SporttypeID ,BettypeID,IsLive ,Maxbet)
			SELECT 202,1501,0,Maxbet
			FROM CheckCustDB.dbo.CustGameType cs WITH(NOLOCK) 			
			WHERE cs.custid=@srecommend AND cs.GameTypeID=1
		
			INSERT INTO #Master321(CustID ,SporttypeID ,BettypeID,IsLive ,Maxbet)
			SELECT c.custid,202,1501,0,Maxbet
			FROM CheckCustDB.dbo.CustGameType cs WITH(NOLOCK) 
				INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON cs.Custid=c.custid
			WHERE c.srecommend=@srecommend AND c.roleid=3  AND c.custid NOT IN(SELECT custid FROM #Dummy) AND cs.GameTypeID=1

			INSERT INTO #Agent321(CustID ,SporttypeID ,BettypeID,IsLive ,Maxbet,mrecommend)
			SELECT cs.custid,202,1501,0,Maxbet,mrecommend
			FROM CheckCustDB.dbo.CustGameType cs WITH(NOLOCK) 
				INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON cs.Custid=c.custid
			WHERE c.srecommend=@srecommend AND c.roleid=2 AND c.custid NOT IN(SELECT custid FROM #Agent) AND cs.GameTypeID=1	 

			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 321,s.SporttypeID,s.BettypeID,@srecommend,m.CustID,s.Maxbet,m.Maxbet,GETDATE(),1
			FROM #Super321 s
				INNER JOIN #Master321 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.IsLive=m.IsLive
			WHERE s.Maxbet<m.Maxbet
			
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 321,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.Maxbet,m.Maxbet,GETDATE(),1
			FROM #Master321 s
				INNER JOIN #Agent321 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.IsLive=m.IsLive AND s.CustID=m.mrecommend
			WHERE s.Maxbet<m.Maxbet
		END

	END
	IF @RuleId IN (0,322)  
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 322,s.sporttype,s.bettype,s.CustID,NULL,c.MaxPerMatch,NULL,GETDATE(),1
		FROM CheckCustDB.dbo.Dep_CustBetSetting_Agent s WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND s.MaxPerMatch<0
			AND c.custid NOT IN(SELECT custid FROM #Trade)
			AND c.custid NOT IN(SELECT custid FROM #Dummy)
			AND c.custid NOT IN(SELECT custid FROM #Agent)

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 322,s.sporttype,s.bettype,s.CustID,NULL,c.MaxPerMatch,NULL,GETDATE(),1
		FROM CheckCustDB.dbo.Dep_CustBetSetting_Member s WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND s.MaxPerMatch<0
			AND c.custid NOT IN(SELECT custid FROM #Trade)
			AND c.custid NOT IN(SELECT custid FROM #Dummy)
			AND c.custid NOT IN(SELECT custid FROM #Agent)

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 322,1,1,s.CustID,NULL,s.MaxPerMatch,NULL,GETDATE(),1
		FROM CheckCustDB.dbo.custInfo s WITH(NOLOCK) 			
		WHERE s.srecommend=@srecommend AND s.MaxPerMatch<0
			AND s.custid NOT IN(SELECT custid FROM #Trade)
			AND s.custid NOT IN(SELECT custid FROM #Dummy)
			AND s.custid NOT IN(SELECT custid FROM #Agent)

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 322,2,1,s.CustID,NULL,s.MaxPerMatch2,NULL,GETDATE(),1
		FROM CheckCustDB.dbo.custInfo s WITH(NOLOCK) 			
		WHERE s.srecommend=@srecommend AND s.MaxPerMatch2<0
			AND s.custid NOT IN(SELECT custid FROM #Trade)
			AND s.custid NOT IN(SELECT custid FROM #Dummy)
			AND s.custid NOT IN(SELECT custid FROM #Agent)

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 322,3,1,s.CustID,NULL,s.MaxPerMatch3,NULL,GETDATE(),1
		FROM CheckCustDB.dbo.custInfo s WITH(NOLOCK) 			
		WHERE s.srecommend=@srecommend AND s.MaxPerMatch3<0
			AND s.custid NOT IN(SELECT custid FROM #Trade)
			AND s.custid NOT IN(SELECT custid FROM #Dummy)
			AND s.custid NOT IN(SELECT custid FROM #Agent)

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 322,5,1,s.CustID,NULL,s.MaxPerMatch5,NULL,GETDATE(),1
		FROM CheckCustDB.dbo.custInfo s WITH(NOLOCK) 			
		WHERE s.srecommend=@srecommend AND s.MaxPerMatch5<0
			AND s.custid NOT IN(SELECT custid FROM #Trade)
			AND s.custid NOT IN(SELECT custid FROM #Dummy)
			AND s.custid NOT IN(SELECT custid FROM #Agent)

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 322,8,1,s.CustID,NULL,s.MaxPerMatch8,NULL,GETDATE(),1
		FROM CheckCustDB.dbo.custInfo s WITH(NOLOCK) 			
		WHERE s.srecommend=@srecommend AND s.MaxPerMatch8<0
			AND s.custid NOT IN(SELECT custid FROM #Trade)
			AND s.custid NOT IN(SELECT custid FROM #Dummy)
			AND s.custid NOT IN(SELECT custid FROM #Agent)
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 322,10,1,s.CustID,NULL,s.MaxPerMatch10,NULL,GETDATE(),1
		FROM CheckCustDB.dbo.custInfo s WITH(NOLOCK) 			
		WHERE s.srecommend=@srecommend AND s.MaxPerMatch10<0
			AND s.custid NOT IN(SELECT custid FROM #Trade)
			AND s.custid NOT IN(SELECT custid FROM #Dummy)
			AND s.custid NOT IN(SELECT custid FROM #Agent)
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 322,11,1,s.CustID,NULL,s.MaxPerMatch11,NULL,GETDATE(),1
		FROM CheckCustDB.dbo.custInfo s WITH(NOLOCK) 			
		WHERE s.srecommend=@srecommend AND s.MaxPerMatch11<0	
			AND s.custid NOT IN(SELECT custid FROM #Trade)
			AND s.custid NOT IN(SELECT custid FROM #Dummy)
			AND s.custid NOT IN(SELECT custid FROM #Agent)
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 322,161,81,s.CustID,NULL,s.MaxPerMatch161,NULL,GETDATE(),1
		FROM CheckCustDB.dbo.custInfo s WITH(NOLOCK) 			
		WHERE s.srecommend=@srecommend AND s.MaxPerMatch161<0
			AND s.custid NOT IN(SELECT custid FROM #Trade)
			AND s.custid NOT IN(SELECT custid FROM #Dummy)
			AND s.custid NOT IN(SELECT custid FROM #Agent)

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 322,99,1,s.CustID,NULL,s.MaxPerMatch99,NULL,GETDATE(),1
		FROM CheckCustDB.dbo.custInfo s WITH(NOLOCK) 			
		WHERE s.srecommend=@srecommend AND s.MaxPerMatch99<0
			AND s.custid NOT IN(SELECT custid FROM #Trade)
			AND s.custid NOT IN(SELECT custid FROM #Dummy)
			AND s.custid NOT IN(SELECT custid FROM #Agent)

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 322,99,9,s.CustID,NULL,s.MaxPerMatch99MP,NULL,GETDATE(),1
		FROM CheckCustDB.dbo.custInfo s WITH(NOLOCK) 			
		WHERE s.srecommend=@srecommend AND s.MaxPerMatch99MP<0
			AND s.custid NOT IN(SELECT custid FROM #Trade)
			AND s.custid NOT IN(SELECT custid FROM #Dummy)
			AND s.custid NOT IN(SELECT custid FROM #Agent)

		IF(@DisableKeno=0 AND @HideKeno=0)
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 322,202,1501,s.CustID,NULL,s.MaxPerGameType,NULL,GETDATE(),1
			FROM CheckCustDB.dbo.CustGameType s WITH(NOLOCK) 
				INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON s.custid=c.custid
			WHERE c.srecommend=@srecommend AND s.MaxPerGameType<0
				AND s.custid NOT IN(SELECT custid FROM #Trade)
				AND s.custid NOT IN(SELECT custid FROM #Dummy)
				AND s.custid NOT IN(SELECT custid FROM #Agent)
				AND s.GameTypeID=1
		END
	END
	IF @RuleId IN (0,323)  
	BEGIN
		CREATE TABLE #Super323	(SporttypeID INT,BettypeID INT,MaxPerMatch MONEY,PRIMARY KEY(SporttypeID,BettypeID))
		CREATE TABLE #Master323	(CustID INT,SporttypeID INT,BettypeID INT,MaxPerMatch MONEY,PRIMARY KEY(CustID,SporttypeID,BettypeID))
		CREATE TABLE #Agent323	(CustID INT,SporttypeID INT,BettypeID INT,mrecommend INT,MaxPerMatch MONEY,PRIMARY KEY(CustID,SporttypeID,BettypeID,mrecommend))		

		INSERT INTO #Super323(SporttypeID ,BettypeID ,MaxPerMatch)
		SELECT cs.sporttype,cs.bettype,MaxPerMatch
		FROM CheckCustDB.dbo.Dep_CustBetSetting_Agent cs WITH(NOLOCK) 			
		WHERE cs.custid=@srecommend
		
		INSERT INTO #Master323(CustID ,SporttypeID ,BettypeID ,MaxPerMatch)
		SELECT c.custid,cs.sporttype,cs.bettype,cs.MaxPerMatch
		FROM CheckCustDB.dbo.Dep_CustBetSetting_Agent cs WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON cs.Custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=3 
			AND c.custid NOT IN(SELECT custid FROM #Dummy)

		INSERT INTO #Agent323(CustID ,SporttypeID ,BettypeID,MaxPerMatch,mrecommend)
		SELECT cs.custid,cs.sporttype,cs.bettype,cs.MaxPerMatch,mrecommend
		FROM CheckCustDB.dbo.Dep_CustBetSetting_Agent cs WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON cs.Custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=2 
			AND c.custid NOT IN(SELECT custid FROM #Agent)	

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 323,s.SporttypeID,s.BettypeID,@srecommend,m.CustID,s.MaxPerMatch,m.MaxPerMatch,GETDATE(),1
		FROM #Super323 s
			INNER JOIN #Master323 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID 
		WHERE s.MaxPerMatch<m.MaxPerMatch
			
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 323,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.MaxPerMatch,m.MaxPerMatch,GETDATE(),1
		FROM #Master323 s
			INNER JOIN #Agent323 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.CustID=m.mrecommend
		WHERE s.MaxPerMatch<m.MaxPerMatch

		TRUNCATE TABLE #Super323
		TRUNCATE TABLE #Master323
		TRUNCATE TABLE #Agent323

		INSERT INTO #Super323(SporttypeID ,BettypeID ,MaxPerMatch)
		SELECT 1,1,MaxPerMatch
		FROM CheckCustDB.dbo.custInfo c WITH(NOLOCK)
		WHERE c.CustID=@srecommend 

		INSERT INTO #Master323(CustID ,SporttypeID ,BettypeID ,MaxPerMatch)
		SELECT c.custid,1,1,MaxPerMatch
		FROM CheckCustDB.dbo.custInfo c WITH(NOLOCK) 
		WHERE c.srecommend=@srecommend AND c.roleid=3  
			AND c.custid NOT IN(SELECT custid FROM #Dummy)

		INSERT INTO #Agent323(CustID ,SporttypeID ,BettypeID,MaxPerMatch,mrecommend)
		SELECT c.custid,1,1,MaxPerMatch,mrecommend
		FROM CheckCustDB.dbo.custInfo c WITH(NOLOCK) 
		WHERE c.srecommend=@srecommend AND c.roleid=2  
			AND c.custid NOT IN(SELECT custid FROM #Agent)	

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 323,s.SporttypeID,s.BettypeID,@srecommend,m.CustID,s.MaxPerMatch,m.MaxPerMatch,GETDATE(),1
		FROM #Super323 s
			INNER JOIN #Master323 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID 
		WHERE s.MaxPerMatch<m.MaxPerMatch
			
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 323,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.MaxPerMatch,m.MaxPerMatch,GETDATE(),1
		FROM #Master323 s
			INNER JOIN #Agent323 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.CustID=m.mrecommend
		WHERE s.MaxPerMatch<m.MaxPerMatch

		TRUNCATE TABLE #Super323
		TRUNCATE TABLE #Master323
		TRUNCATE TABLE #Agent323

		INSERT INTO #Super323(SporttypeID ,BettypeID ,MaxPerMatch)
		SELECT 2,1,maxpermatch2
		FROM CheckCustDB.dbo.custInfo c WITH(NOLOCK)
		WHERE c.CustID=@srecommend 

		INSERT INTO #Master323(CustID ,SporttypeID ,BettypeID ,MaxPerMatch)
		SELECT c.custid,2,1,MaxPerMatch2
		FROM CheckCustDB.dbo.custInfo c WITH(NOLOCK) 
		WHERE c.srecommend=@srecommend AND c.roleid=3  
			AND c.custid NOT IN(SELECT custid FROM #Dummy)

		INSERT INTO #Agent323(CustID ,SporttypeID ,BettypeID,MaxPerMatch,mrecommend)
		SELECT c.custid,2,1,MaxPerMatch2,mrecommend
		FROM CheckCustDB.dbo.custInfo c WITH(NOLOCK)
		WHERE c.srecommend=@srecommend AND c.roleid=2 
			AND c.custid NOT IN(SELECT custid FROM #Agent)	

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 323,s.SporttypeID,s.BettypeID,@srecommend,m.CustID,s.MaxPerMatch,m.MaxPerMatch,GETDATE(),1
		FROM #Super323 s
			INNER JOIN #Master323 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID 
		WHERE s.MaxPerMatch<m.MaxPerMatch
			
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 323,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.MaxPerMatch,m.MaxPerMatch,GETDATE(),1
		FROM #Master323 s
			INNER JOIN #Agent323 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.CustID=m.mrecommend
		WHERE s.MaxPerMatch<m.MaxPerMatch

		TRUNCATE TABLE #Super323
		TRUNCATE TABLE #Master323
		TRUNCATE TABLE #Agent323

		INSERT INTO #Super323(SporttypeID ,BettypeID ,MaxPerMatch)
		SELECT 3,1,maxpermatch3
		FROM CheckCustDB.dbo.custInfo c WITH(NOLOCK) 
		WHERE c.CustID=@srecommend 

		INSERT INTO #Master323(CustID ,SporttypeID ,BettypeID ,MaxPerMatch)
		SELECT c.custid,3,1,MaxPerMatch3
		FROM CheckCustDB.dbo.custInfo c WITH(NOLOCK)
		WHERE c.srecommend=@srecommend AND c.roleid=3 
			AND c.custid NOT IN(SELECT custid FROM #Dummy)

		INSERT INTO #Agent323(CustID ,SporttypeID ,BettypeID,MaxPerMatch,mrecommend)
		SELECT c.custid,3,1,MaxPerMatch3,mrecommend
		FROM CheckCustDB.dbo.custInfo c WITH(NOLOCK) 
		WHERE c.srecommend=@srecommend AND c.roleid=2  
			AND c.custid NOT IN(SELECT custid FROM #Agent)	

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 323,s.SporttypeID,s.BettypeID,@srecommend,m.CustID,s.MaxPerMatch,m.MaxPerMatch,GETDATE(),1
		FROM #Super323 s
			INNER JOIN #Master323 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID 
		WHERE s.MaxPerMatch<m.MaxPerMatch
			
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 323,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.MaxPerMatch,m.MaxPerMatch,GETDATE(),1
		FROM #Master323 s
			INNER JOIN #Agent323 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.CustID=m.mrecommend
		WHERE s.MaxPerMatch<m.MaxPerMatch

		TRUNCATE TABLE #Super323
		TRUNCATE TABLE #Master323
		TRUNCATE TABLE #Agent323

		INSERT INTO #Super323(SporttypeID ,BettypeID ,MaxPerMatch)
		SELECT 5,1,maxpermatch5
		FROM CheckCustDB.dbo.custInfo c WITH(NOLOCK) 
		WHERE c.CustID=@srecommend 

		INSERT INTO #Master323(CustID ,SporttypeID ,BettypeID ,MaxPerMatch)
		SELECT c.custid,5,1,MaxPerMatch5
		FROM CheckCustDB.dbo.custInfo c WITH(NOLOCK)
		WHERE c.srecommend=@srecommend AND c.roleid=3 
			AND c.custid NOT IN(SELECT custid FROM #Dummy)

		INSERT INTO #Agent323(CustID ,SporttypeID ,BettypeID,MaxPerMatch,mrecommend)
		SELECT c.custid,5,1,MaxPerMatch5,mrecommend
		FROM CheckCustDB.dbo.custInfo c WITH(NOLOCK)
		WHERE c.srecommend=@srecommend AND c.roleid=2
			AND c.custid NOT IN(SELECT custid FROM #Agent)	

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 323,s.SporttypeID,s.BettypeID,@srecommend,m.CustID,s.MaxPerMatch,m.MaxPerMatch,GETDATE(),1
		FROM #Super323 s
			INNER JOIN #Master323 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID 
		WHERE s.MaxPerMatch<m.MaxPerMatch
			
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 323,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.MaxPerMatch,m.MaxPerMatch,GETDATE(),1
		FROM #Master323 s
			INNER JOIN #Agent323 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.CustID=m.mrecommend
		WHERE s.MaxPerMatch<m.MaxPerMatch

		TRUNCATE TABLE #Super323
		TRUNCATE TABLE #Master323
		TRUNCATE TABLE #Agent323

		INSERT INTO #Super323(SporttypeID ,BettypeID ,MaxPerMatch)
		SELECT 8,1,maxpermatch8
		FROM CheckCustDB.dbo.custInfo c WITH(NOLOCK)
		WHERE c.CustID=@srecommend 

		INSERT INTO #Master323(CustID ,SporttypeID ,BettypeID ,MaxPerMatch)
		SELECT c.custid,8,1,MaxPerMatch8
		FROM CheckCustDB.dbo.custInfo c WITH(NOLOCK) 
		WHERE c.srecommend=@srecommend AND c.roleid=3 
			AND c.custid NOT IN(SELECT custid FROM #Dummy)

		INSERT INTO #Agent323(CustID ,SporttypeID ,BettypeID,MaxPerMatch,mrecommend)
		SELECT c.custid,8,1,MaxPerMatch8,mrecommend
		FROM CheckCustDB.dbo.custInfo c WITH(NOLOCK) 
		WHERE c.srecommend=@srecommend AND c.roleid=2 
			AND c.custid NOT IN(SELECT custid FROM #Agent)	

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 323,s.SporttypeID,s.BettypeID,@srecommend,m.CustID,s.MaxPerMatch,m.MaxPerMatch,GETDATE(),1
		FROM #Super323 s
			INNER JOIN #Master323 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID 
		WHERE s.MaxPerMatch<m.MaxPerMatch
			
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 323,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.MaxPerMatch,m.MaxPerMatch,GETDATE(),1
		FROM #Master323 s
			INNER JOIN #Agent323 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.CustID=m.mrecommend
		WHERE s.MaxPerMatch<m.MaxPerMatch

		TRUNCATE TABLE #Super323
		TRUNCATE TABLE #Master323
		TRUNCATE TABLE #Agent323

		INSERT INTO #Super323(SporttypeID ,BettypeID ,MaxPerMatch)
		SELECT 10,1,maxpermatch10
		FROM CheckCustDB.dbo.custInfo c WITH(NOLOCK) 
		WHERE c.CustID=@srecommend 

		INSERT INTO #Master323(CustID ,SporttypeID ,BettypeID ,MaxPerMatch)
		SELECT c.custid,10,1,MaxPerMatch10
		FROM CheckCustDB.dbo.custInfo c WITH(NOLOCK)
		WHERE c.srecommend=@srecommend AND c.roleid=3 
			AND c.custid NOT IN(SELECT custid FROM #Dummy)

		INSERT INTO #Agent323(CustID ,SporttypeID ,BettypeID,MaxPerMatch,mrecommend)
		SELECT c.custid,10,1,MaxPerMatch10,mrecommend
		FROM CheckCustDB.dbo.custInfo c WITH(NOLOCK) 
		WHERE c.srecommend=@srecommend AND c.roleid=2 
			AND c.custid NOT IN(SELECT custid FROM #Agent)	

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 323,s.SporttypeID,s.BettypeID,@srecommend,m.CustID,s.MaxPerMatch,m.MaxPerMatch,GETDATE(),1
		FROM #Super323 s
			INNER JOIN #Master323 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID 
		WHERE s.MaxPerMatch<m.MaxPerMatch
			
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 323,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.MaxPerMatch,m.MaxPerMatch,GETDATE(),1
		FROM #Master323 s
			INNER JOIN #Agent323 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.CustID=m.mrecommend
		WHERE s.MaxPerMatch<m.MaxPerMatch

		TRUNCATE TABLE #Super323
		TRUNCATE TABLE #Master323
		TRUNCATE TABLE #Agent323

		INSERT INTO #Super323(SporttypeID ,BettypeID ,MaxPerMatch)
		SELECT 11,1,maxpermatch11
		FROM CheckCustDB.dbo.custInfo c WITH(NOLOCK)
		WHERE c.CustID=@srecommend

		INSERT INTO #Master323(CustID ,SporttypeID ,BettypeID ,MaxPerMatch)
		SELECT c.custid,11,1,MaxPerMatch11
		FROM CheckCustDB.dbo.custInfo c WITH(NOLOCK) 
		WHERE c.srecommend=@srecommend AND c.roleid=3  
			AND c.custid NOT IN(SELECT custid FROM #Dummy)

		INSERT INTO #Agent323(CustID ,SporttypeID ,BettypeID,MaxPerMatch,mrecommend)
		SELECT c.custid,11,1,MaxPerMatch11,mrecommend
		FROM CheckCustDB.dbo.custInfo c WITH(NOLOCK) 
		WHERE c.srecommend=@srecommend AND c.roleid=2 
			AND c.custid NOT IN(SELECT custid FROM #Agent)	

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 323,s.SporttypeID,s.BettypeID,@srecommend,m.CustID,s.MaxPerMatch,m.MaxPerMatch,GETDATE(),1
		FROM #Super323 s
			INNER JOIN #Master323 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID 
		WHERE s.MaxPerMatch<m.MaxPerMatch

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 323,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.MaxPerMatch,m.MaxPerMatch,GETDATE(),1
		FROM #Master323 s
			INNER JOIN #Agent323 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.CustID=m.mrecommend
		WHERE s.MaxPerMatch<m.MaxPerMatch

		TRUNCATE TABLE #Super323
		TRUNCATE TABLE #Master323
		TRUNCATE TABLE #Agent323

		INSERT INTO #Super323(SporttypeID ,BettypeID ,MaxPerMatch)
		SELECT 161,81,maxpermatch161
		FROM CheckCustDB.dbo.custInfo c WITH(NOLOCK) 
		WHERE c.CustID=@srecommend 

		INSERT INTO #Master323(CustID ,SporttypeID ,BettypeID ,MaxPerMatch)
		SELECT c.custid,161,81,MaxPerMatch161
		FROM CheckCustDB.dbo.custInfo c WITH(NOLOCK) 
		WHERE c.srecommend=@srecommend AND c.roleid=3 
			AND c.custid NOT IN(SELECT custid FROM #Dummy)

		INSERT INTO #Agent323(CustID ,SporttypeID ,BettypeID,MaxPerMatch,mrecommend)
		SELECT c.custid,161,81,MaxPerMatch161,mrecommend
		FROM CheckCustDB.dbo.custInfo c WITH(NOLOCK) 
		WHERE c.srecommend=@srecommend AND c.roleid=2 
			AND c.custid NOT IN(SELECT custid FROM #Agent)	

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 323,s.SporttypeID,s.BettypeID,@srecommend,m.CustID,s.MaxPerMatch,m.MaxPerMatch,GETDATE(),1
		FROM #Super323 s
			INNER JOIN #Master323 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID 
		WHERE s.MaxPerMatch<m.MaxPerMatch
			
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 323,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.MaxPerMatch,m.MaxPerMatch,GETDATE(),1
		FROM #Master323 s
			INNER JOIN #Agent323 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.CustID=m.mrecommend
		WHERE s.MaxPerMatch<m.MaxPerMatch

		TRUNCATE TABLE #Super323
		TRUNCATE TABLE #Master323
		TRUNCATE TABLE #Agent323

		INSERT INTO #Super323(SporttypeID ,BettypeID ,MaxPerMatch)
		SELECT 99,1,maxpermatch99
		FROM  CheckCustDB.dbo.custInfo c WITH(NOLOCK) 
		WHERE c.CustID=@srecommend 

		INSERT INTO #Master323(CustID ,SporttypeID ,BettypeID ,MaxPerMatch)
		SELECT c.custid,99,1,MaxPerMatch99
		FROM CheckCustDB.dbo.custInfo c WITH(NOLOCK) 
		WHERE c.srecommend=@srecommend AND c.roleid=3 
			AND c.custid NOT IN(SELECT custid FROM #Dummy)

		INSERT INTO #Agent323(CustID ,SporttypeID ,BettypeID,MaxPerMatch,mrecommend)
		SELECT c.custid,99,1,MaxPerMatch99,mrecommend
		FROM CheckCustDB.dbo.custInfo c WITH(NOLOCK)
		WHERE c.srecommend=@srecommend AND c.roleid=2 
			AND c.custid NOT IN(SELECT custid FROM #Agent)	

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 323,s.SporttypeID,s.BettypeID,@srecommend,m.CustID,s.MaxPerMatch,m.MaxPerMatch,GETDATE(),1
		FROM #Super323 s
			INNER JOIN #Master323 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID 
		WHERE s.MaxPerMatch<m.MaxPerMatch
			
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 323,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.MaxPerMatch,m.MaxPerMatch,GETDATE(),1
		FROM #Master323 s
			INNER JOIN #Agent323 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.CustID=m.mrecommend
		WHERE s.MaxPerMatch<m.MaxPerMatch

		TRUNCATE TABLE #Super323
		TRUNCATE TABLE #Master323
		TRUNCATE TABLE #Agent323

		INSERT INTO #Super323(SporttypeID ,BettypeID ,MaxPerMatch)
		SELECT 99,9,MaxPerMatch99MP
		FROM CheckCustDB.dbo.custInfo c WITH(NOLOCK) 
		WHERE c.CustID=@srecommend

		INSERT INTO #Master323(CustID ,SporttypeID ,BettypeID ,MaxPerMatch)
		SELECT c.custid,99,9,MaxPerMatch99MP
		FROM CheckCustDB.dbo.custInfo c WITH(NOLOCK) 
		WHERE c.srecommend=@srecommend AND c.roleid=3 
			AND c.custid NOT IN(SELECT custid FROM #Dummy)

		INSERT INTO #Agent323(CustID ,SporttypeID ,BettypeID,MaxPerMatch,mrecommend)
		SELECT c.custid,99,9,MaxPerMatch99MP,mrecommend
		FROM CheckCustDB.dbo.custInfo c WITH(NOLOCK)
		WHERE c.srecommend=@srecommend AND c.roleid=2  
			AND c.custid NOT IN(SELECT custid FROM #Agent)	

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 323,s.SporttypeID,s.BettypeID,@srecommend,m.CustID,s.MaxPerMatch,m.MaxPerMatch,GETDATE(),1
		FROM #Super323 s
			INNER JOIN #Master323 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID 
		WHERE s.MaxPerMatch<m.MaxPerMatch
			
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 323,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.MaxPerMatch,m.MaxPerMatch,GETDATE(),1
		FROM #Master323 s
			INNER JOIN #Agent323 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.CustID=m.mrecommend
		WHERE s.MaxPerMatch<m.MaxPerMatch

		IF @DisableKeno=0 AND @HideKeno=0
		BEGIN			
			TRUNCATE TABLE #Super323
			TRUNCATE TABLE #Master323
			TRUNCATE TABLE #Agent323	

			INSERT INTO #Super323(SporttypeID ,BettypeID ,MaxPerMatch)
			SELECT 202,1501,MaxPerGameType
			FROM CheckCustDB.dbo.CustGameType cs WITH(NOLOCK) 			
			WHERE cs.custid=@srecommend AND cs.GameTypeID=1
		
			INSERT INTO #Master323(CustID ,SporttypeID ,BettypeID ,MaxPerMatch)
			SELECT c.custid,202,1501,MaxPerGameType
			FROM CheckCustDB.dbo.CustGameType cs WITH(NOLOCK) 
				INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON cs.Custid=c.custid
			WHERE c.srecommend=@srecommend AND c.roleid=3 
				AND c.custid NOT IN(SELECT custid FROM #Dummy) AND cs.GameTypeID=1

			INSERT INTO #Agent323(CustID ,SporttypeID ,BettypeID,MaxPerMatch,mrecommend)
			SELECT cs.custid,202,1501,MaxPerGameType,mrecommend
			FROM CheckCustDB.dbo.CustGameType cs WITH(NOLOCK) 
				INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON cs.Custid=c.custid
			WHERE c.srecommend=@srecommend AND c.roleid=2 
				AND c.custid NOT IN(SELECT custid FROM #Agent)	AND cs.GameTypeID=1

			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 323,s.SporttypeID,s.BettypeID,@srecommend,m.CustID,s.MaxPerMatch,m.MaxPerMatch,GETDATE(),1
			FROM #Super323 s
				INNER JOIN #Master323 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID 
			WHERE s.MaxPerMatch<m.MaxPerMatch
			
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 323,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.MaxPerMatch,m.MaxPerMatch,GETDATE(),1
			FROM #Master323 s
				INNER JOIN #Agent323 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.CustID=m.mrecommend
			WHERE s.MaxPerMatch<m.MaxPerMatch
		END

	END
	IF @RuleId IN (0,324)  
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 324,161,81,s.CustID,NULL,MaxPerBall161,NULL,GETDATE(),1
		FROM CheckCustDB.dbo.custInfo s WITH(NOLOCK) 
		WHERE s.srecommend=@srecommend AND s.MaxPerBall161<0
			AND s.custid NOT IN(SELECT custid FROM #Trade)
			AND s.custid NOT IN(SELECT custid FROM #Dummy)
			AND s.custid NOT IN(SELECT custid FROM #Agent)
	END
	IF @RuleId IN (0,325)
	BEGIN
		CREATE TABLE #Super325	(SporttypeID INT,BettypeID INT,MaxPerBall MONEY,PRIMARY KEY(SporttypeID,BettypeID))
		CREATE TABLE #Master325	(CustID INT,SporttypeID INT,BettypeID INT,MaxPerBall MONEY,PRIMARY KEY(CustID,SporttypeID,BettypeID))
		CREATE TABLE #Agent325	(CustID INT,SporttypeID INT,BettypeID INT,mrecommend INT,MaxPerBall MONEY,PRIMARY KEY(CustID,SporttypeID,BettypeID,mrecommend))		

		INSERT INTO #Super325(SporttypeID ,BettypeID ,MaxPerBall)
		SELECT 161,81,MaxPerBall161
		FROM CheckCustDB.dbo.custInfo cs WITH(NOLOCK) 			
		WHERE cs.custid=@srecommend
		
		INSERT INTO #Master325(CustID ,SporttypeID ,BettypeID ,MaxPerBall)
		SELECT c.custid,161,81,c.MaxPerBall161
		FROM  CheckCustDB.dbo.custInfo c WITH(NOLOCK) 
		WHERE c.srecommend=@srecommend AND c.roleid=3 
			AND c.custid NOT IN(SELECT custid FROM #Dummy)

		INSERT INTO #Agent325(CustID ,SporttypeID ,BettypeID,MaxPerBall,mrecommend)
		SELECT c.custid,161,81,c.MaxPerBall161,mrecommend
		FROM CheckCustDB.dbo.custInfo c WITH(NOLOCK) 
		WHERE c.srecommend=@srecommend AND c.roleid=2 
			AND c.custid NOT IN(SELECT custid FROM #Agent)	

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 325,s.SporttypeID,s.BettypeID,@srecommend,m.CustID,s.MaxPerBall,m.MaxPerBall,GETDATE(),1
		FROM #Super325 s
			INNER JOIN #Master325 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID 
		WHERE s.MaxPerBall<m.MaxPerBall
			
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 325,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.MaxPerBall,m.MaxPerBall,GETDATE(),1
		FROM #Master325 s
			INNER JOIN #Agent325 m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID ANd s.CustID=m.mrecommend
		WHERE s.MaxPerBall<m.MaxPerBall
	END
	IF @RuleId IN (0,326)  
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 326,s.SportType,bettype,s.CustID,NULL,s.minbet,s.maxbet,GETDATE(),1
		FROM CheckCustDB.dbo.Dep_CustSetting s WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND s.minbet>s.maxbet 
			AND s.custid NOT IN(SELECT custid FROM #Trade)
			AND s.custid NOT IN(SELECT custid FROM #Dummy)
			AND s.custid NOT IN(SELECT custid FROM #Agent)

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 326,s.SportType,bettype,s.CustID,NULL,s.minbet,s.maxbet,GETDATE(),1
		FROM CheckCustDB.dbo.Dep_CustSetting3rd s WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND s.minbet>s.maxbet AND sporttype NOT BETWEEN 151 AND 154	
			AND s.custid NOT IN(SELECT custid FROM #Trade)
			AND s.custid NOT IN(SELECT custid FROM #Dummy)
			AND s.custid NOT IN(SELECT custid FROM #Agent)

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 326,s.SportType,bettype,s.CustID,NULL,s.minbet,s.maxbet,GETDATE(),1
		FROM CheckCustDB.dbo.Dep_CustBetSetting_Agent s WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND s.minbet>s.maxbet
			AND s.custid NOT IN(SELECT custid FROM #Trade)
			AND s.custid NOT IN(SELECT custid FROM #Dummy)
			AND s.custid NOT IN(SELECT custid FROM #Agent)

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 326,s.SportType,bettype,s.CustID,NULL,s.minbet,s.maxbet,GETDATE(),1
		FROM CheckCustDB.dbo.Dep_CustBetSetting_Member s WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND s.minbet>s.maxbet
			AND s.custid NOT IN(SELECT custid FROM #Trade)
			AND s.custid NOT IN(SELECT custid FROM #Dummy)
			AND s.custid NOT IN(SELECT custid FROM #Agent)

		IF (@HideKeno=0 AND @DisableKeno=0)
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 326,202,1501,s.CustID,NULL,s.minbet,s.maxbet,GETDATE(),1
			FROM CheckCustDB.dbo.CustGameType s WITH(NOLOCK) 
				INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON s.custid=c.custid
			WHERE c.srecommend=@srecommend AND s.minbet>s.maxbet AND s.GameTypeID=1
				AND s.custid NOT IN(SELECT custid FROM #Trade)
				AND s.custid NOT IN(SELECT custid FROM #Dummy)
				AND s.custid NOT IN(SELECT custid FROM #Agent)
		END
	END
	IF @RuleId IN (0,327)  
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 327,s.SportType,bettype,s.CustID,NULL,s.maxbet,c.maxpermatch,GETDATE(),1
		FROM CheckCustDB.dbo.Dep_CustSetting s WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND s.sporttype=1 AND s.maxbet>c.maxpermatch 
			AND s.custid NOT IN(SELECT custid FROM #Trade)
			AND s.custid NOT IN(SELECT custid FROM #Dummy)
			AND s.custid NOT IN(SELECT custid FROM #Agent)

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 327,s.SportType,bettype,s.CustID,NULL,s.maxbet,c.MaxPerMatch99MP,GETDATE(),1
		FROM CheckCustDB.dbo.Dep_CustSetting s WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND s.sporttype=99 AND bettype =9 AND s.maxbet>c.MaxPerMatch99MP
			AND s.custid NOT IN(SELECT custid FROM #Trade)
			AND s.custid NOT IN(SELECT custid FROM #Dummy)
			AND s.custid NOT IN(SELECT custid FROM #Agent)	

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 327,s.SportType,bettype,s.CustID,NULL,s.maxbet,c.maxpermatch2,GETDATE(),1
		FROM CheckCustDB.dbo.Dep_CustSetting s WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND s.sporttype=2 AND s.maxbet>c.maxpermatch2
			AND s.custid NOT IN(SELECT custid FROM #Trade)
			AND s.custid NOT IN(SELECT custid FROM #Dummy)
			AND s.custid NOT IN(SELECT custid FROM #Agent)	

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 327,s.SportType,bettype,s.CustID,NULL,s.maxbet,c.maxpermatch3,GETDATE(),1
		FROM CheckCustDB.dbo.Dep_CustSetting s WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND s.sporttype=3 AND s.maxbet>c.maxpermatch3
			AND s.custid NOT IN(SELECT custid FROM #Trade)
			AND s.custid NOT IN(SELECT custid FROM #Dummy)
			AND s.custid NOT IN(SELECT custid FROM #Agent)	

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 327,s.SportType,bettype,s.CustID,NULL,s.maxbet,c.maxpermatch5,GETDATE(),1
		FROM CheckCustDB.dbo.Dep_CustSetting s WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND s.sporttype=5 AND s.maxbet>c.maxpermatch5
			AND s.custid NOT IN(SELECT custid FROM #Trade)
			AND s.custid NOT IN(SELECT custid FROM #Dummy)
			AND s.custid NOT IN(SELECT custid FROM #Agent)	
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 327,s.SportType,bettype,s.CustID,NULL,s.maxbet,c.maxpermatch8,GETDATE(),1
		FROM CheckCustDB.dbo.Dep_CustSetting s WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND s.sporttype=8 AND s.maxbet>c.maxpermatch8
			AND s.custid NOT IN(SELECT custid FROM #Trade)
			AND s.custid NOT IN(SELECT custid FROM #Dummy)
			AND s.custid NOT IN(SELECT custid FROM #Agent)	

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 327,s.SportType,bettype,s.CustID,NULL,s.maxbet,c.maxpermatch10,GETDATE(),1
		FROM CheckCustDB.dbo.Dep_CustSetting s WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND s.sporttype=10 AND s.maxbet>c.maxpermatch10
			AND s.custid NOT IN(SELECT custid FROM #Trade)
			AND s.custid NOT IN(SELECT custid FROM #Dummy)
			AND s.custid NOT IN(SELECT custid FROM #Agent)	
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 327,s.SportType,bettype,s.CustID,NULL,s.maxbet,c.maxpermatch11,GETDATE(),1
		FROM CheckCustDB.dbo.Dep_CustSetting s WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND s.sporttype=11 AND s.maxbet>c.maxpermatch11
			AND s.custid NOT IN(SELECT custid FROM #Trade)
			AND s.custid NOT IN(SELECT custid FROM #Dummy)
			AND s.custid NOT IN(SELECT custid FROM #Agent)	

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 327,s.SportType,bettype,s.CustID,NULL,s.maxbet,c.maxpermatch161,GETDATE(),1
		FROM CheckCustDB.dbo.Dep_CustSetting3rd s WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND s.sporttype=161 AND s.maxbet>c.maxpermatch161
			AND s.custid NOT IN(SELECT custid FROM #Trade)
			AND s.custid NOT IN(SELECT custid FROM #Dummy)
			AND s.custid NOT IN(SELECT custid FROM #Agent)	

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 327,s.SportType,bettype,s.CustID,NULL,s.maxbet,c.maxpermatch99,GETDATE(),1
		FROM CheckCustDB.dbo.Dep_CustSetting s WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND s.sporttype=99 AND bettype<>9 AND s.maxbet>c.maxpermatch99
			AND s.custid NOT IN(SELECT custid FROM #Trade)
			AND s.custid NOT IN(SELECT custid FROM #Dummy)
			AND s.custid NOT IN(SELECT custid FROM #Agent)	

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 327,s.SportType,bettype,s.CustID,NULL,s.maxbet,s.MaxPerMatch,GETDATE(),1
		FROM CheckCustDB.dbo.Dep_CustBetSetting_Agent s WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND s.maxbet>s.MaxPerMatch
			AND s.custid NOT IN(SELECT custid FROM #Trade)
			AND s.custid NOT IN(SELECT custid FROM #Dummy)
			AND s.custid NOT IN(SELECT custid FROM #Agent)	

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 327,s.SportType,bettype,s.CustID,NULL,s.maxbet,s.MaxPerMatch,GETDATE(),1
		FROM CheckCustDB.dbo.Dep_CustBetSetting_Member s WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND s.maxbet>s.MaxPerMatch
			AND s.custid NOT IN(SELECT custid FROM #Trade)
			AND s.custid NOT IN(SELECT custid FROM #Dummy)
			AND s.custid NOT IN(SELECT custid FROM #Agent)	

		IF (@HideKeno=0 AND @DisableKeno=0)
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 327,202,1501,s.CustID,NULL,s.maxbet,s.MaxPerGameType,GETDATE(),1
			FROM CheckCustDB.dbo.CustGameType s WITH(NOLOCK) 
				INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON s.custid=c.custid
			WHERE c.srecommend=@srecommend AND s.maxbet>s.MaxPerGameType AND s.GameTypeID=1
				AND s.custid NOT IN(SELECT custid FROM #Trade)
				AND s.custid NOT IN(SELECT custid FROM #Dummy)
				AND s.custid NOT IN(SELECT custid FROM #Agent)	
		END
	END
	IF @RuleId IN (0,328)  
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 328,s.SportType,bettype,s.CustID,NULL,s.maxbet,c.MaxPerBall161,GETDATE(),1
		FROM CheckCustDB.dbo.Dep_CustSetting3rd s WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND s.sporttype=161 AND s.maxbet>c.MaxPerBall161
			AND s.custid NOT IN(SELECT custid FROM #Trade)
			AND s.custid NOT IN(SELECT custid FROM #Dummy)
			AND s.custid NOT IN(SELECT custid FROM #Agent)
	END
	
END
GO