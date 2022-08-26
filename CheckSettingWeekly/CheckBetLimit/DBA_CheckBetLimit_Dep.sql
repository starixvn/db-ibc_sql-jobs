/*<info serverAlias="DBCHECK-CheckResultDB" executers="" viewers="" isFunction="0"></info>*/
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
		- 20190809@Winnie:	Fix Rule 326 - [Redmine: #118471]
		- 20190916@Winnie:	Remove check MuayThai - [Redmine: #120271]
		- 20191122@Johnson: revise sp [redmine:#123732]
		- 20200116@Johnson: remove AG [redmine:#127252]
		- 20200206@Johnson: exclude closed customers[redmine:#127831]
		- 20200409@Tiara: Change data source from Customer to Custinfo [redmine #132051]
		- 20201211@Winfred: Remove OddAdj Acc[redmine:#147005]
		- 20220407@Winfred: LG Virtual Sports - Add rule for new product for setting type 11 [redmine:#170454]
		- 20220301@Eden: Deposit - Sportsbook - Revise customer settings [Redmine: #167898] 
		
	Param's Explanation:   
	 @RuleId = 0 : 'all'  
	 @RuleId IN (317->328)  
*/  
BEGIN
	SET NOCOUNT ON
	
	IF @srecommend IN(1752415,932209,1574083,179457)--'AB88SuperRM' , '12BETSuperSD$',MS88SuperBND,'ITSA'
	RETURN
	
	IF (SELECT ISNULL(closed,0) FROM CheckCustDB.dbo.custInfo WITH(NOLOCK) WHERE custid = @srecommend) = 1
	RETURN
	
	CREATE TABLE #Dummy (CustID INT PRIMARY KEY)
	CREATE TABLE #ExcludeAgent (CustID INT PRIMARY KEY)
	CREATE TABLE #ExcludeMember (CustID INT PRIMARY KEY)
	CREATE TABLE #TmpCust (CustID INT PRIMARY KEY)
	
	DECLARE @count INT
	
	CREATE TABLE #tblCustClosed (custid INT PRIMARY KEY, roleid TINYINT)
	
	INSERT INTO #tblCustClosed (custid,roleid)
	SELECT custid,roleid
	FROM CheckCustDB.dbo.custInfo WITH(NOLOCK) 
	WHERE srecommend = @srecommend AND closed = 1
	
	SELECT @count = COUNT(1)
	FROM CheckCustDB.dbo.custInfo WITH(NOLOCK)
	WHERE srecommend = @srecommend

	INSERT INTO #Dummy(CustID)
	SELECT CustID FROM CheckCustDB.dbo.custInfo WITH(NOLOCK) WHERE srecommend=@srecommend AND roleid=3 AND (username LIKE '%Acc%' OR username LIKE '%LocalBank%' OR username LIKE '%AFF%' OR username LIKE 'AB88'+'CAS%' )

	INSERT INTO #ExcludeAgent(CustID)
	SELECT CustID FROM CheckCustDB.dbo.Customer WITH(NOLOCK) WHERE username IN('12BETSD$02','12BETSD$01')
	UNION
	SELECT CustID FROM CheckCustDB.dbo.Customer WITH(NOLOCK) WHERE mrecommend IN(SELECT custid FROM #Dummy) AND roleID=2

	INSERT INTO #ExcludeMember(CustID)
	SELECT CustID FROM CheckCustDB.dbo.custInfo WITH(NOLOCK) WHERE srecommend=@srecommend AND roleid=1 AND (username LIKE '%Bettrade%' OR username LIKE '%CashOut%' OR username LIKE '%ClearBal%' OR username LIKE '%OddsAdj%')
	UNION
	SELECT CustID FROM CheckCustDB.dbo.Customer WITH(NOLOCK) WHERE recommend IN(SELECT custid FROM #ExcludeAgent) AND roleID=1
	UNION
	SELECT CustID FROM CheckCustDB.dbo.Customer WITH(NOLOCK) WHERE mrecommend IN(SELECT custid FROM #Dummy) AND roleID=1
		
	CREATE TABLE #Dep_CustSetting_Super (custid INT,SporttypeID INT,BettypeID INT, Minbet MONEY, MaxBet MONEY, MaxPermatch MONEY, MaxPerNumber MONEY,MaxPayoutPerMatch MONEY PRIMARY KEY(SporttypeID,BettypeID))
    CREATE TABLE #Dep_CustSetting_Master (CustID INT,SporttypeID INT,BettypeID INT, Minbet MONEY, MaxBet MONEY, MaxPermatch MONEY, MaxPerNumber MONEY,MaxPayoutPerMatch MONEY  PRIMARY KEY(CustID,SporttypeID,BettypeID))
    CREATE TABLE #Dep_CustSetting_Agent (CustID INT, mrecommend INT, SporttypeID INT,BettypeID INT, Minbet MONEY, MaxBet MONEY, MaxPermatch MONEY, MaxPerNumber MONEY,MaxPayoutPerMatch MONEY  PRIMARY KEY(CustID,SporttypeID,BettypeID))
	CREATE TABLE #Dep_CustSettingGroup_Member (AgentID INT, mrecommend INT, SporttypeID INT,BettypeID INT, Minbet MONEY, MaxBet MONEY, MaxPermatch MONEY, MaxPerNumber MONEY,MaxPayoutPerMatch MONEY  PRIMARY KEY(AgentID,SporttypeID,BettypeID))
		
	---------------------------------------------------------------------------------
	--Begin Dep_CustBetSettingGame_xxx
	INSERT INTO #Dep_CustSetting_Super(CustID,SporttypeID ,BettypeID,Minbet,MaxBet,MaxPermatch,MaxPerNumber,MaxPayoutPerMatch)
	SELECT cs.custid, cs.sporttype,cs.bettype,cs.Minbet,cs.MaxBet,cs.MaxPermatch,cs.MaxPerNumber,cs.MaxPayoutPerMatch
	FROM CheckCustDB.dbo.Dep_CustBetSettingGame_Agent cs WITH(NOLOCK) 				
	WHERE cs.custid=@srecommend 
			
	INSERT INTO #Dep_CustSetting_Master(CustID,SporttypeID ,BettypeID,Minbet,MaxBet,MaxPermatch,MaxPerNumber,MaxPayoutPerMatch)
	SELECT cs.custid, cs.sporttype,cs.bettype,cs.Minbet,cs.MaxBet,cs.MaxPermatch,cs.MaxPerNumber,cs.MaxPayoutPerMatch
	FROM CheckCustDB.dbo.Dep_CustBetSettingGame_Agent cs WITH(NOLOCK) 
		INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON cs.CustID = ci.custid		
	WHERE ci.srecommend=@srecommend 
		AND ci.roleID = 3
		AND ci.custid NOT IN(SELECT custid FROM #Dummy)
		
	INSERT INTO #Dep_CustSetting_Agent(CustID,SporttypeID ,BettypeID,Minbet,MaxBet,MaxPermatch,MaxPerNumber,MaxPayoutPerMatch,mrecommend)
	SELECT cs.custid, cs.sporttype,cs.bettype,cs.Minbet,cs.MaxBet,cs.MaxPermatch,cs.MaxPerNumber,cs.MaxPayoutPerMatch,ci.mrecommend
	FROM CheckCustDB.dbo.Dep_CustBetSettingGame_Agent cs WITH(NOLOCK) 
		INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON cs.CustID = ci.custid		
	WHERE ci.srecommend=@srecommend 
		AND ci.roleID = 2
		AND ci.custid NOT IN(SELECT custid FROM #ExcludeAgent)

	INSERT INTO #Dep_CustSettingGroup_Member(AgentID,SporttypeID ,BettypeID,Minbet,MaxBet,MaxPermatch,MaxPerNumber,MaxPayoutPerMatch,mrecommend)
	SELECT cs.AgentID, cs.sporttype,cs.bettype,cs.Minbet,cs.MaxBet,cs.MaxPermatch,cs.MaxPerNumber,cs.MaxPayoutPerMatch,ci.mrecommend
	FROM CheckCustDB.dbo.Dep_CustBetSettingGameGroup_Member cs WITH(NOLOCK) 
		INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON cs.AgentID = ci.custid		
	WHERE ci.srecommend=@srecommend 
		AND ci.roleID = 2
		AND ci.custid NOT IN(SELECT custid FROM #ExcludeAgent)
	
			
	IF @ruleid IN (0,317)--Missing bet limit setting	
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 317,s.SporttypeID,s.BettypeID,s.custid,ci.CustID,1,0,GETDATE(),1
		FROM CheckCustDB.dbo.custInfo CI (NOLOCK)
			CROSS APPLY (SELECT custid, sporttypeID, bettypeID FROM #Dep_CustSetting_Super) s
			LEFT JOIN #Dep_CustSetting_Master m ON ci.custid = m.custid 
												AND s.SporttypeID=m.SporttypeID 
												AND s.BettypeID=m.BettypeID 
		WHERE ci.srecommend=@srecommend 
			AND ci.roleID = 3
			AND ci.custid NOT IN(SELECT custid FROM #Dummy)
			AND ci.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 3)
			AND m.CustID IS NULL
	
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 317,s.SporttypeID,s.BettypeID,s.custid,ci.CustID,1,0,GETDATE(),1
		FROM CheckCustDB.dbo.custInfo CI (NOLOCK)
			CROSS APPLY (SELECT custid, sporttypeID, bettypeID FROM #Dep_CustSetting_Super) s
			LEFT JOIN #Dep_CustSetting_Agent m ON ci.custid = m.custid 
												AND s.SporttypeID=m.SporttypeID 
												AND s.BettypeID=m.BettypeID 
		WHERE ci.srecommend=@srecommend 
			AND ci.roleID = 2
			AND ci.custid NOT IN(SELECT custid FROM #ExcludeAgent)
			AND ci.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 2)
			AND m.CustID IS NULL

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 317,s.SporttypeID,s.BettypeID,s.custid,ci.CustID,1,0,GETDATE(),1
		FROM CheckCustDB.dbo.custInfo CI (NOLOCK)
			CROSS APPLY (SELECT custid, sporttypeID, bettypeID FROM #Dep_CustSetting_Super) s
			LEFT JOIN #Dep_CustSettingGroup_Member m ON ci.custid = m.AgentID 
												AND s.SporttypeID=m.SporttypeID 
												AND s.BettypeID=m.BettypeID 
		WHERE ci.srecommend=@srecommend 
			AND ci.roleID = 2
			AND ci.custid NOT IN(SELECT custid FROM #ExcludeAgent)
			AND ci.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 2)
			AND m.AgentID IS NULL
				
		INSERT INTO #tmpCust(custid)
		SELECT custid
		FROM (	SELECT ci.custid,(SELECT count(1) 
								FROM CheckCustDB.dbo.Dep_CustBetSettingGame_Member cs WITH(NOLOCK) 
								WHERE cs.custid = ci.custid) cnt 	
				FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)	
					INNER JOIN CheckCustDB.dbo.Dep_CustSettingMode sm WITH(NOLOCK) ON sm.CustID = ci.custid AND sm.IsGroupedBetLimit = 0									
				WHERE ci.srecommend = @srecommend
					AND ci.roleid = 1					
					AND ci.custid NOT IN(SELECT custid FROM #ExcludeMember)
					AND ci.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 1)
		)t	
		WHERE cnt <> (SELECT COUNT(1) FROM #Dep_CustSetting_Super)
			
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 317,s.Sporttype,s.Bettype,@srecommend,ci.custid,1,0,GETDATE(),1
		FROM  #tmpCust ci 
			CROSS APPLY (SELECT sporttypeID as sporttype ,bettypeID as bettype FROM #Dep_CustSetting_Super) s
			LEFT JOIN CheckCustDB.dbo.Dep_CustBetSettingGame_Member cs WITH(NOLOCK) ON cs.custid = ci.custid 
														AND cs.sporttype = s.sporttype 
														AND cs.bettype = s.bettype 
		WHERE cs.custid IS NULL
			AND ci.custid NOT IN (SELECT custid FROM #tblCustClosed)
	END
	
	IF @RuleId IN(0,318)--minbet < 0		
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 318,s.sporttypeID,s.bettypeID,s.CustID,NULL,Minbet,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Super s
		WHERE s.minbet<0 
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 318,s.sporttypeID,s.bettypeID,s.CustID,NULL,Minbet,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Master s
		WHERE s.minbet<0 
			AND custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 3)
			AND s.custid NOT IN(SELECT custid FROM #Dummy)
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 318,s.sporttypeID,s.bettypeID,s.CustID,NULL,Minbet,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Agent s
		WHERE s.minbet<0 
			AND custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 2)
			AND s.custid NOT IN(SELECT custid FROM #ExcludeAgent)

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 318,s.sporttypeID,s.bettypeID,s.AgentID,NULL,Minbet,NULL,GETDATE(),1
		FROM #Dep_CustSettingGroup_Member s
		WHERE s.minbet<0 
			AND AgentID NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 2)
			AND s.AgentID NOT IN(SELECT custid FROM #ExcludeAgent)
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 318,cs.sporttype,cs.bettype,cs.CustID,NULL,Minbet,NULL,GETDATE(),1
		FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
			INNER JOIN CheckCustDB.dbo.Dep_CustBetSettingGame_Member cs WITH(NOLOCK) ON cs.custid = ci.custid 			
		WHERE ci.srecommend = @srecommend
			AND ci.roleid = 1
			AND ci.custid NOT IN(SELECT custid FROM #ExcludeMember)	
			AND ci.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 1)
			AND cs.minbet< 0 
	END	
	
	IF @RuleId IN (0,319)  --Super Minbet > Master Minbet > Agent Minbet
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 319,s.SporttypeID,s.BettypeID,s.custid,m.CustID,s.Minbet,m.Minbet,GETDATE(),1
		FROM #Dep_CustSetting_Super s
			INNER JOIN #Dep_CustSetting_Master m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID
		WHERE s.Minbet>m.Minbet
			AND m.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 3)
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 319,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.Minbet,m.Minbet,GETDATE(),1
		FROM #Dep_CustSetting_Master s
			INNER JOIN #Dep_CustSetting_Agent m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND m.mrecommend=s.CustID
		WHERE s.Minbet>m.Minbet
			AND m.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 2)
	END
	
	IF @RuleId IN(0,320)--maxbet < 0
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 320,s.sporttypeID,s.bettypeID,s.CustID,NULL,maxbet,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Super s
		WHERE s.maxbet<0 
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 320,s.sporttypeID,s.bettypeID,s.CustID,NULL,maxbet,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Master s
		WHERE s.maxbet<0 
			AND custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 3)
			AND s.custid NOT IN(SELECT custid FROM #Dummy)
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 320,s.sporttypeID,s.bettypeID,s.CustID,NULL,maxbet,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Agent s
		WHERE s.maxbet<0 
			AND custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 2)
			AND s.custid NOT IN(SELECT custid FROM #ExcludeAgent)

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 320,s.sporttypeID,s.bettypeID,s.AgentID,NULL,maxbet,NULL,GETDATE(),1
		FROM #Dep_CustSettingGroup_Member s
		WHERE s.maxbet<0 
			AND AgentID NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 2)
			AND s.AgentID NOT IN(SELECT custid FROM #ExcludeAgent)
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 320,cs.sporttype,cs.bettype,cs.CustID,NULL,maxbet,NULL,GETDATE(),1
		FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
			INNER JOIN CheckCustDB.dbo.Dep_CustBetSettingGame_Member cs WITH(NOLOCK) ON cs.custid = ci.custid 			
		WHERE ci.srecommend = @srecommend
			AND ci.roleid = 1
			AND ci.custid NOT IN(SELECT custid FROM #ExcludeMember)	
			AND ci.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 1)
			AND cs.maxbet< 0 
	END
	
	IF @RuleId IN (0,321)  --Super Maxbet < Master Maxbet < Agent Maxbet
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 321,s.SporttypeID,s.BettypeID,s.custid,m.CustID,s.Maxbet,m.Maxbet,GETDATE(),1
		FROM #Dep_CustSetting_Super s
			INNER JOIN #Dep_CustSetting_Master m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID
		WHERE s.Maxbet<m.Maxbet
			AND m.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 3)
			
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 321,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.Maxbet,m.Maxbet,GETDATE(),1
		FROM #Dep_CustSetting_Master s
			INNER JOIN #Dep_CustSetting_Agent m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.CustID=m.mrecommend
		WHERE s.Maxbet<m.Maxbet
			AND m.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 2)
	END
	
	IF @RuleId IN (0,322)  --Max per match < 0	
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 322,s.sporttypeID,s.bettypeID,s.CustID,NULL,MaxPermatch,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Super s
		WHERE s.MaxPermatch<0 
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 322,s.sporttypeID,s.bettypeID,s.CustID,NULL,MaxPermatch,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Master s
		WHERE s.MaxPermatch<0 
			AND custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 3)
			AND s.custid NOT IN(SELECT custid FROM #Dummy)
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 322,s.sporttypeID,s.bettypeID,s.CustID,NULL,MaxPermatch,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Agent s
		WHERE s.MaxPermatch<0 
			AND custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 2)
			AND s.custid NOT IN(SELECT custid FROM #ExcludeAgent)

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 322,s.sporttypeID,s.bettypeID,s.AgentID,NULL,MaxPermatch,NULL,GETDATE(),1
		FROM #Dep_CustSettingGroup_Member s
		WHERE s.MaxPermatch<0 
			AND AgentID NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 2)
			AND s.AgentID NOT IN(SELECT custid FROM #ExcludeAgent)
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 322,cs.sporttype,cs.bettype,cs.CustID,NULL,cs.MaxPermatch,NULL,GETDATE(),1
		FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
			INNER JOIN CheckCustDB.dbo.Dep_CustBetSettingGame_Member cs WITH(NOLOCK) ON cs.custid = ci.custid 			
		WHERE ci.srecommend = @srecommend
			AND ci.roleid = 1
			AND ci.custid NOT IN(SELECT custid FROM #ExcludeMember)	
			AND ci.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 1)
			AND cs.MaxPermatch< 0 
	END
	
	IF @RuleId IN (0,323)  --Super mpx < Master mpx < Agent mpx
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 323,s.SporttypeID,s.BettypeID,s.custid,m.CustID,s.MaxPerMatch,m.MaxPerMatch,GETDATE(),1
		FROM #Dep_CustSetting_Super s
			INNER JOIN #Dep_CustSetting_Master m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID
		WHERE s.MaxPerMatch<m.MaxPerMatch
			AND m.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 3)
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 323,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.MaxPerMatch,m.MaxPerMatch,GETDATE(),1
		FROM #Dep_CustSetting_Master s
			INNER JOIN #Dep_CustSetting_Agent m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.CustID=m.mrecommend
		WHERE s.MaxPerMatch<m.MaxPerMatch
			AND m.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 2)
	END

	IF @RuleId IN (0,324)  --Max per ball < 0		
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 324,s.sporttypeID,s.bettypeID,s.CustID,NULL,MaxPerNumber,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Super s
		WHERE s.MaxPerNumber<0 
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 324,s.sporttypeID,s.bettypeID,s.CustID,NULL,MaxPerNumber,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Master s
		WHERE s.MaxPerNumber<0 
			AND custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 3)
			AND s.custid NOT IN(SELECT custid FROM #Dummy)
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 324,s.sporttypeID,s.bettypeID,s.CustID,NULL,MaxPerNumber,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Agent s
		WHERE s.MaxPerNumber<0 
			AND custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 2)
			AND s.custid NOT IN(SELECT custid FROM #ExcludeAgent)

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 324,s.sporttypeID,s.bettypeID,s.AgentID,NULL,MaxPerNumber,NULL,GETDATE(),1
		FROM #Dep_CustSettingGroup_Member s
		WHERE s.MaxPerNumber<0 
			AND AgentID NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 2)
			AND s.AgentID NOT IN(SELECT custid FROM #ExcludeAgent)
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 324,cs.sporttype,cs.bettype,cs.CustID,NULL,MaxPerNumber,NULL,GETDATE(),1
		FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
			INNER JOIN CheckCustDB.dbo.Dep_CustBetSettingGame_Member cs WITH(NOLOCK) ON cs.custid = ci.custid 			
		WHERE ci.srecommend = @srecommend
			AND ci.roleid = 1
			AND ci.custid NOT IN(SELECT custid FROM #ExcludeMember)	
			AND ci.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 1)
			AND cs.MaxPerNumber< 0 
	END
	
	IF @RuleId IN (0,325)  --Super mpb < Master mpb < Agent mpb
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 325,s.SporttypeID,s.BettypeID,s.custid,m.CustID,s.MaxPerNumber,m.MaxPerNumber,GETDATE(),1
		FROM #Dep_CustSetting_Super s
			INNER JOIN #Dep_CustSetting_Master m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID
		WHERE s.MaxPerNumber<m.MaxPerNumber
			AND m.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 3)
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 325,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.MaxPerNumber,m.MaxPerNumber,GETDATE(),1
		FROM #Dep_CustSetting_Master s
			INNER JOIN #Dep_CustSetting_Agent m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.CustID=m.mrecommend
		WHERE s.MaxPerNumber<m.MaxPerNumber
			AND m.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 2)
	END

	IF @RuleId IN (0,342)  --Max Payout Per Match < 0				
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 342,s.sporttypeID,s.bettypeID,s.CustID,NULL,MaxPayoutPerMatch,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Super s
		WHERE s.MaxPayoutPerMatch<0 
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 342,s.sporttypeID,s.bettypeID,s.CustID,NULL,MaxPayoutPerMatch,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Master s
		WHERE s.MaxPayoutPerMatch<0 
			AND custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 3)
			AND s.custid NOT IN(SELECT custid FROM #Dummy)
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 342,s.sporttypeID,s.bettypeID,s.CustID,NULL,MaxPayoutPerMatch,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Agent s
		WHERE s.MaxPayoutPerMatch<0 
			AND custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 2)
			AND s.custid NOT IN(SELECT custid FROM #ExcludeAgent)

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 342,s.sporttypeID,s.bettypeID,s.AgentID,NULL,MaxPayoutPerMatch,NULL,GETDATE(),1
		FROM #Dep_CustSettingGroup_Member s
		WHERE s.MaxPayoutPerMatch<0 
			AND AgentID NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 2)
			AND s.AgentID NOT IN(SELECT custid FROM #ExcludeAgent)
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 342,cs.sporttype,cs.bettype,cs.CustID,NULL,MaxPayoutPerMatch,NULL,GETDATE(),1
		FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
			INNER JOIN CheckCustDB.dbo.Dep_CustBetSettingGame_Member cs WITH(NOLOCK) ON cs.custid = ci.custid 			
		WHERE ci.srecommend = @srecommend
			AND ci.roleid = 1
			AND ci.custid NOT IN(SELECT custid FROM #ExcludeMember)	
			AND ci.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 1)
			AND cs.MaxPayoutPerMatch< 0 
	END
	
	IF @RuleId IN (0,343)  --Super mppm < Master mppm < Agent mppm		
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 343,s.SporttypeID,s.BettypeID,s.custid,m.CustID,s.MaxPayoutPerMatch,m.MaxPayoutPerMatch,GETDATE(),1
		FROM #Dep_CustSetting_Super s
			INNER JOIN #Dep_CustSetting_Master m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID
		WHERE s.MaxPayoutPerMatch<m.MaxPayoutPerMatch
			AND m.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 3)
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 343,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.MaxPayoutPerMatch,m.MaxPayoutPerMatch,GETDATE(),1
		FROM #Dep_CustSetting_Master s
			INNER JOIN #Dep_CustSetting_Agent m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.CustID=m.mrecommend
		WHERE s.MaxPayoutPerMatch<m.MaxPayoutPerMatch
			AND m.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 2)
	END
	
	IF @RuleId IN (0,326)  --Minbet > Maxbet
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 326,s.sporttypeID,s.bettypeID,s.CustID,NULL,minbet,maxbet,GETDATE(),1
		FROM #Dep_CustSetting_Super s
		WHERE s.minbet>s.maxbet 	 
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 326,s.sporttypeID,s.bettypeID,s.CustID,NULL,minbet,maxbet,GETDATE(),1
		FROM #Dep_CustSetting_Master s
		WHERE s.minbet>s.maxbet 
			AND custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 3)
			AND s.custid NOT IN(SELECT custid FROM #Dummy)
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 326,s.sporttypeID,s.bettypeID,s.CustID,NULL,minbet,maxbet,GETDATE(),1
		FROM #Dep_CustSetting_Agent s
		WHERE s.minbet>s.maxbet
			AND custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 2)
			AND s.custid NOT IN(SELECT custid FROM #ExcludeAgent)

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 326,s.sporttypeID,s.bettypeID,s.AgentID,NULL,minbet,maxbet,GETDATE(),1
		FROM #Dep_CustSettingGroup_Member s
		WHERE s.minbet>s.maxbet
			AND AgentID NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 2)
			AND s.AgentID NOT IN(SELECT custid FROM #ExcludeAgent)
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 326,cs.sporttype,cs.bettype,cs.CustID,NULL,minbet,maxbet,GETDATE(),1
		FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
			INNER JOIN CheckCustDB.dbo.Dep_CustBetSettingGame_Member cs WITH(NOLOCK) ON cs.custid = ci.custid 				
		WHERE ci.srecommend = @srecommend
			AND ci.roleid = 1
			AND ci.custid NOT IN(SELECT custid FROM #ExcludeMember)	
			AND ci.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 1)
			AND cs.minbet>cs.maxbet	
	END
	
	IF @RuleId IN (0,327) --Maxbet > Maxpermatch		
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 327,s.sporttypeID,s.bettypeID,s.CustID,NULL,Maxbet,maxpermatch,GETDATE(),1
		FROM #Dep_CustSetting_Super s
		WHERE maxbet>maxpermatch  
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 327,s.sporttypeID,s.bettypeID,s.CustID,NULL,Maxbet,maxpermatch,GETDATE(),1
		FROM #Dep_CustSetting_Master s
		WHERE maxbet>maxpermatch 
			AND custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 3)
			AND s.custid NOT IN(SELECT custid FROM #Dummy)
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 327,s.sporttypeID,s.bettypeID,s.CustID,NULL,Maxbet,maxpermatch,GETDATE(),1
		FROM #Dep_CustSetting_Agent s
		WHERE maxbet>maxpermatch 
			AND custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 2)
			AND s.custid NOT IN(SELECT custid FROM #ExcludeAgent)

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 327,s.sporttypeID,s.bettypeID,s.AgentID,NULL,Maxbet,maxpermatch,GETDATE(),1
		FROM #Dep_CustSettingGroup_Member s
		WHERE maxbet>maxpermatch 
			AND AgentID NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 2)
			AND s.AgentID NOT IN(SELECT custid FROM #ExcludeAgent)
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 327,cs.sporttype,cs.bettype,cs.CustID,NULL,Maxbet,cs.maxpermatch,GETDATE(),1
		FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
			INNER JOIN CheckCustDB.dbo.Dep_CustBetSettingGame_Member cs WITH(NOLOCK) ON cs.custid = ci.custid 				
		WHERE ci.srecommend = @srecommend
			AND ci.roleid = 1
			AND ci.custid NOT IN(SELECT custid FROM #ExcludeMember)	
			AND ci.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 1)
			AND cs.maxbet> cs.maxpermatch			
	END

	/*
	IF @RuleId IN (0,328) --Maxbet > Max Per Ball			
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 328,s.sporttypeID,s.bettypeID,s.CustID,NULL,Maxbet,MaxPerNumber,GETDATE(),1
		FROM #Dep_CustSetting_Super s
		WHERE maxbet>MaxPerNumber  
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 328,s.sporttypeID,s.bettypeID,s.CustID,NULL,Maxbet,MaxPerNumber,GETDATE(),1
		FROM #Dep_CustSetting_Master s
		WHERE maxbet>MaxPerNumber 
			AND custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 3)
			AND s.custid NOT IN(SELECT custid FROM #Dummy)
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 328,s.sporttypeID,s.bettypeID,s.CustID,NULL,Maxbet,MaxPerNumber,GETDATE(),1
		FROM #Dep_CustSetting_Agent s
		WHERE maxbet>MaxPerNumber 
			AND custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 2)
			AND s.custid NOT IN(SELECT custid FROM #ExcludeAgent)

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 328,s.sporttypeID,s.bettypeID,s.AgentID,NULL,Maxbet,MaxPerNumber,GETDATE(),1
		FROM #Dep_CustSettingGroup_Member s
		WHERE maxbet>MaxPerNumber 
			AND AgentID NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 2)
			AND s.AgentID NOT IN(SELECT custid FROM #ExcludeAgent)
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 328,cs.sporttype,cs.bettype,cs.CustID,NULL,Maxbet,cs.MaxPerNumber,GETDATE(),1
		FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
			INNER JOIN CheckCustDB.dbo.Dep_CustBetSettingGame_Member cs WITH(NOLOCK) ON cs.custid = ci.custid 				
		WHERE ci.srecommend = @srecommend
			AND ci.roleid = 1
			AND ci.custid NOT IN(SELECT custid FROM #ExcludeMember)	
			AND ci.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 1)
			AND cs.maxbet> cs.MaxPerNumber			
	END
	*/

	IF @RuleId IN (0,344) --Max Per Match > Max Payout Per Match			
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 344,s.sporttypeID,s.bettypeID,s.CustID,NULL,MaxPermatch,MaxPayoutPerMatch,GETDATE(),1
		FROM #Dep_CustSetting_Super s
		WHERE MaxPermatch>MaxPayoutPerMatch  
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 344,s.sporttypeID,s.bettypeID,s.CustID,NULL,MaxPermatch,MaxPayoutPerMatch,GETDATE(),1
		FROM #Dep_CustSetting_Master s
		WHERE MaxPermatch>MaxPayoutPerMatch 
			AND custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 3)
			AND s.custid NOT IN(SELECT custid FROM #Dummy)
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 344,s.sporttypeID,s.bettypeID,s.CustID,NULL,MaxPermatch,MaxPayoutPerMatch,GETDATE(),1
		FROM #Dep_CustSetting_Agent s
		WHERE MaxPermatch>MaxPayoutPerMatch 
			AND custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 2)
			AND s.custid NOT IN(SELECT custid FROM #ExcludeAgent)

		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 344,s.sporttypeID,s.bettypeID,s.AgentID,NULL,MaxPermatch,MaxPayoutPerMatch,GETDATE(),1
		FROM #Dep_CustSettingGroup_Member s
		WHERE MaxPermatch>MaxPayoutPerMatch 
			AND AgentID NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 2)
			AND s.AgentID NOT IN(SELECT custid FROM #ExcludeAgent)
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 344,cs.sporttype,cs.bettype,cs.CustID,NULL,cs.MaxPermatch,cs.MaxPayoutPerMatch,GETDATE(),1
		FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
			INNER JOIN CheckCustDB.dbo.Dep_CustBetSettingGame_Member cs WITH(NOLOCK) ON cs.custid = ci.custid 				
		WHERE ci.srecommend = @srecommend
			AND ci.roleid = 1
			AND ci.custid NOT IN(SELECT custid FROM #ExcludeMember)	
			AND ci.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 1)
			AND cs.MaxPermatch> cs.MaxPayoutPerMatch			
	END

	
	TRUNCATE TABLE #Dep_CustSetting_Super
	TRUNCATE TABLE #Dep_CustSetting_Master
	TRUNCATE TABLE #Dep_CustSetting_Agent
	TRUNCATE TABLE #tmpCust
	TRUNCATE TABLE #Dep_CustSettingGroup_Member
	--End Dep_CustBetSettingGame_xxx
	---------------------------------------------------------------------------------
	
	
	---------------------------------------------------------------------------------
	--Begin Dep_CustBetSetting_Agent
	INSERT INTO #Dep_CustSetting_Super(CustID,SporttypeID ,BettypeID,Minbet,MaxBet,MaxPermatch)
	SELECT cs.custid, cs.sporttype,cs.bettype,Minbet,MaxBet,cs.MaxPermatch
	FROM CheckCustDB.dbo.Dep_CustBetSetting_Agent cs WITH(NOLOCK) 				
	WHERE cs.custid=@srecommend 
			
	INSERT INTO #Dep_CustSetting_Master(CustID,SporttypeID,BettypeID,Minbet,MaxBet,MaxPermatch)
	SELECT cs.custid, cs.sporttype,cs.bettype,Minbet,MaxBet,cs.MaxPermatch
	FROM CheckCustDB.dbo.Dep_CustBetSetting_Agent cs WITH(NOLOCK) 
		INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON cs.CustID = ci.custid		
	WHERE ci.srecommend=@srecommend 
		AND ci.roleID = 3
		AND ci.custid NOT IN(SELECT custid FROM #Dummy)
		
	INSERT INTO #Dep_CustSetting_Agent(CustID,mrecommend,SporttypeID,BettypeID,Minbet,MaxBet,MaxPermatch)
	SELECT cs.custid,ci.mrecommend, cs.sporttype,cs.bettype,Minbet,MaxBet,cs.MaxPermatch
	FROM CheckCustDB.dbo.Dep_CustBetSetting_Agent cs WITH(NOLOCK) 
		INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON cs.CustID = ci.custid		
	WHERE ci.srecommend=@srecommend 
		AND ci.roleID = 2
		AND ci.custid NOT IN(SELECT custid FROM #ExcludeAgent)
	
	
	--product has offered Bet limit
	DECLARE @currency INT
	
	SELECT @currency = currency	FROM CheckCustDB.dbo.customer WITH(NOLOCK) WHERE custid = @srecommend

	CREATE TABLE #OfferedProductList(ProductID TINYINT, ProductSettingID TINYINT, SportType SMALLINT ,BetType SMALLINT,SettingType TINYINT)
	INSERT INTO #OfferedProductList (ProductID, ProductSettingID, SportType, BetType, SettingType)
	SELECT DISTINCT ProductID, ps.ProductSettingID, SportType, BetType, SettingType
	FROM CheckCustDB.dbo.Dep_ProductSetting pd WITH (NOLOCK)
		INNER JOIN CheckCustDB.dbo.Dep_ProductSettingDetail ps WITH(NOLOCK) ON pd.ProductSettingID = ps.ProductSettingID
	WHERE pd.SettingType IN (2,10,11,12)  AND ps.SettingStatus = 0
		
	CREATE TABLE #GlobalSetting([SportType] [smallint] ,[BetType] [smallint], Maxbet [MONEY], Minbet [MONEY])
	INSERT INTO #GlobalSetting(SportType,BetType,Maxbet,Minbet)
	SELECT s.Sporttype,s.Bettype,ISNULL(s.MaxBet,0),ISNULL(s.MinBet,0)
	FROM CheckCustDB.dbo.Dep_ProductBetSetting s WITH(NOLOCK) 
		INNER JOIN #OfferedProductList p ON p.SportType = s.Sporttype AND p.Bettype = s.Bettype AND p.SettingType = 11
	WHERE s.Currency = @currency 
		AND (ISNULL(s.MaxBet,0) <> 0 OR ISNULL(s.MinBet,0) <> 0)
	
	IF @ruleid IN (0,317)
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 317,s.SporttypeID,s.BettypeID,s.custid,ci.CustID,1,0,GETDATE(),1
		FROM CheckCustDB.dbo.custInfo CI (NOLOCK)
			CROSS APPLY (SELECT custid, sporttypeID, bettypeID FROM #Dep_CustSetting_Super) s
			LEFT JOIN #Dep_CustSetting_Master m ON ci.custid = m.custid 
												AND s.SporttypeID=m.SporttypeID 
												AND s.BettypeID=m.BettypeID 
		WHERE ci.srecommend=@srecommend 
			AND ci.roleID = 3
			AND ci.custid NOT IN(SELECT custid FROM #Dummy)
			AND ci.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 3)
			AND m.CustID IS NULL
	
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 317,s.SporttypeID,s.BettypeID,s.custid,ci.CustID,1,0,GETDATE(),1
		FROM CheckCustDB.dbo.custInfo CI (NOLOCK)
			CROSS APPLY (SELECT custid, sporttypeID, bettypeID FROM #Dep_CustSetting_Super) s
			LEFT JOIN #Dep_CustSetting_Agent m ON ci.custid = m.custid 
												AND s.SporttypeID=m.SporttypeID 
												AND s.BettypeID=m.BettypeID
		WHERE ci.srecommend=@srecommend 
			AND ci.roleID = 2
			AND ci.custid NOT IN(SELECT custid FROM #ExcludeAgent)
			AND ci.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 2)
			AND m.CustID IS NULL
				
		IF @count > 200000
		BEGIN
			INSERT INTO #tmpCust
			SELECT custid
			FROM (	SELECT ci.custid,(SELECT count(1) 
									FROM CheckCustDB.dbo.Dep_CustBetSetting_Member cs WITH(NOLOCK) 
									WHERE cs.custid = ci.custid) cnt 	
					FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)										
					WHERE ci.srecommend = @srecommend
						AND ci.roleid = 1					
						AND ci.custid NOT IN(SELECT custid FROM #ExcludeMember)
						AND ci.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 1)
			)t	
			WHERE cnt <> (SELECT COUNT(1) FROM #Dep_CustSetting_Super)
			OPTION (OPTIMIZE FOR (@srecommend = 10580722))	
		END
		ELSE
		BEGIN
			INSERT INTO #tmpCust
			SELECT custid
			FROM (	SELECT ci.custid,(SELECT count(1) 
									FROM CheckCustDB.dbo.Dep_CustBetSetting_Member cs WITH(NOLOCK) 
									WHERE cs.custid = ci.custid) cnt 	
					FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)										
					WHERE ci.srecommend = @srecommend
						AND ci.roleid = 1					
						AND ci.custid NOT IN(SELECT custid FROM #ExcludeMember)
						AND ci.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 1)
			)t	
			WHERE cnt <> (SELECT COUNT(1) FROM #Dep_CustSetting_Super)				
		END
			
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 317,s.Sporttype,s.Bettype,@srecommend,ci.custid,1,0,GETDATE(),1
		FROM  #tmpCust ci 
			CROSS APPLY (SELECT sporttypeID as sporttype ,bettypeID as bettype FROM #Dep_CustSetting_Super) s
			LEFT JOIN CheckCustDB.dbo.Dep_CustBetSetting_Member cs WITH(NOLOCK) ON cs.custid = ci.custid 
														AND cs.sporttype = s.sporttype 
														AND cs.bettype = s.bettype 
		WHERE cs.custid IS NULL
			AND ci.custid NOT IN (SELECT custid FROM #tblCustClosed)
	END
	
	IF @RuleId IN(0,318)
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 318,s.sporttypeID,s.bettypeID,s.CustID,NULL,Minbet,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Super s
		WHERE s.minbet<0 
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 318,s.sporttypeID,s.bettypeID,s.CustID,NULL,Minbet,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Master s
		WHERE s.minbet<0 
			AND custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 3)
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 318,s.sporttypeID,s.bettypeID,s.CustID,NULL,Minbet,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Agent s
		WHERE s.minbet<0 
			AND custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 2)
		
		IF @count > 200000
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 318,cs.sporttype,cs.bettype,cs.CustID,NULL,Minbet,NULL,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Dep_CustBetSetting_Member cs WITH(NOLOCK) ON cs.custid = ci.custid 				
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #ExcludeMember)	
				AND ci.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 1)
				AND cs.minbet< 0 
			OPTION (OPTIMIZE FOR (@srecommend = 10580722))
		END
		ELSE
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 318,cs.sporttype,cs.bettype,cs.CustID,NULL,Minbet,NULL,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Dep_CustBetSetting_Member cs WITH(NOLOCK) ON cs.custid = ci.custid 				
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #ExcludeMember)	
				AND ci.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 1)
				AND cs.minbet< 0 	
		END		
	END	
	
	IF @RuleId IN (0,319)  
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 319,s.SporttypeID,s.BettypeID,s.custid,m.CustID,s.Minbet,m.Minbet,GETDATE(),1
		FROM #Dep_CustSetting_Super s
			INNER JOIN #Dep_CustSetting_Master m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID
		WHERE s.Minbet>m.Minbet
			AND m.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 3)
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 319,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.Minbet,m.Minbet,GETDATE(),1
		FROM #Dep_CustSetting_Master s
			INNER JOIN #Dep_CustSetting_Agent m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND m.mrecommend=s.CustID
		WHERE s.Minbet>m.Minbet
			AND m.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 2)
	END
	
	IF @RuleId IN(0,320)
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 320,s.sporttypeID,s.bettypeID,s.CustID,NULL,Maxbet,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Super s
		WHERE s.Maxbet<0 	 
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 320,s.sporttypeID,s.bettypeID,s.CustID,NULL,Maxbet,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Master s
		WHERE s.Maxbet<0 	
			AND custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 3)
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 320,s.sporttypeID,s.bettypeID,s.CustID,NULL,Maxbet,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Agent s
		WHERE s.Maxbet<0 	
			AND custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 2)
		
		IF @count > 200000
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 320,cs.sporttype,cs.bettype,cs.CustID,NULL,Maxbet,NULL,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Dep_CustBetSetting_Member cs WITH(NOLOCK) ON cs.custid = ci.custid 				
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 1)
				AND ci.custid NOT IN(SELECT custid FROM #ExcludeMember)	
				AND cs.Maxbet< 0 	
			OPTION (OPTIMIZE FOR (@srecommend = 10580722))		
		END
		ELSE
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 320,cs.sporttype,cs.bettype,cs.CustID,NULL,Maxbet,NULL,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Dep_CustBetSetting_Member cs WITH(NOLOCK) ON cs.custid = ci.custid 				
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 1)
				AND ci.custid NOT IN(SELECT custid FROM #ExcludeMember)	
				AND cs.Maxbet< 0 	
		END		
	END
	
	IF @RuleId IN (0,321)  
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 321,s.SporttypeID,s.BettypeID,s.custid,m.CustID,s.Maxbet,m.Maxbet,GETDATE(),1
		FROM #Dep_CustSetting_Super s
			INNER JOIN #Dep_CustSetting_Master m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID
		WHERE s.Maxbet<m.Maxbet
			AND m.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 3)
			
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 321,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.Maxbet,m.Maxbet,GETDATE(),1
		FROM #Dep_CustSetting_Master s
			INNER JOIN #Dep_CustSetting_Agent m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.CustID=m.mrecommend
		WHERE s.Maxbet<m.Maxbet
			AND m.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 2)
	END
	
	IF @RuleId IN (0,322)  
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 322,s.sporttypeID,s.bettypeID,s.CustID,NULL,MaxPerMatch,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Super s
		WHERE s.MaxPerMatch<0 AND s.SporttypeID IN (SELECT SportType FROM #OfferedProductList WHERE SettingType NOT IN (11) )
					
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 322,s.sporttypeID,s.bettypeID,s.CustID,NULL,MaxPerMatch,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Master s
		WHERE s.MaxPerMatch<0 AND s.SporttypeID IN (SELECT SportType FROM #OfferedProductList WHERE SettingType NOT IN (11) )
			AND custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 3)
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 322,s.sporttypeID,s.bettypeID,s.CustID,NULL,MaxPerMatch,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Agent s
		WHERE s.MaxPerMatch<0 AND s.SporttypeID IN (SELECT SportType FROM #OfferedProductList WHERE SettingType NOT IN (11) )
			AND custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 2)
		
		IF @count > 200000
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 322,cs.sporttype,cs.bettype,cs.CustID,NULL,cs.MaxPerMatch,NULL,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Dep_CustBetSetting_Member cs WITH(NOLOCK) ON cs.custid = ci.custid 				
				INNER JOIN #OfferedProductList opl WITH(NOLOCK) ON cs.SportType = opl.SportType AND cs.BetType = opl.BetType AND opl.SettingType NOT IN (11)
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #ExcludeMember)	
				AND ci.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 1)
				AND cs.MaxPerMatch< 0 
			OPTION (OPTIMIZE FOR (@srecommend = 10580722))
		END
		ELSE
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 322,cs.sporttype,cs.bettype,cs.CustID,NULL,cs.MaxPerMatch,NULL,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Dep_CustBetSetting_Member cs WITH(NOLOCK) ON cs.custid = ci.custid 				
				INNER JOIN #OfferedProductList opl WITH(NOLOCK) ON cs.SportType = opl.SportType AND cs.BetType = opl.BetType AND opl.SettingType NOT IN (11) 				
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #ExcludeMember)	
				AND ci.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 1)
				AND cs.MaxPerMatch< 0 
		END		
	END
	
	IF @RuleId IN (0,323)  
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 323,s.SporttypeID,s.BettypeID,s.custid,m.CustID,s.MaxPerMatch,m.MaxPerMatch,GETDATE(),1
		FROM #Dep_CustSetting_Super s
			INNER JOIN #Dep_CustSetting_Master m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID
		WHERE s.MaxPerMatch<m.MaxPerMatch AND s.SporttypeID IN (SELECT SportType FROM #OfferedProductList WHERE SettingType NOT IN (11) )
			AND m.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 3)
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 323,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.MaxPerMatch,m.MaxPerMatch,GETDATE(),1
		FROM #Dep_CustSetting_Master s
			INNER JOIN #Dep_CustSetting_Agent m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.CustID=m.mrecommend
		WHERE s.MaxPerMatch<m.MaxPerMatch AND s.SporttypeID IN (SELECT SportType FROM #OfferedProductList WHERE SettingType NOT IN (11) )
			AND m.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 2)
	END
	
	IF @RuleId IN (0,326)  
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 326,s.sporttypeID,s.bettypeID,s.CustID,NULL,minbet,maxbet,GETDATE(),1
		FROM #Dep_CustSetting_Super s
		WHERE s.minbet>s.maxbet 	 
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 326,s.sporttypeID,s.bettypeID,s.CustID,NULL,minbet,maxbet,GETDATE(),1
		FROM #Dep_CustSetting_Master s
		WHERE s.minbet>s.maxbet 
			AND custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 3)
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 326,s.sporttypeID,s.bettypeID,s.CustID,NULL,minbet,maxbet,GETDATE(),1
		FROM #Dep_CustSetting_Agent s
		WHERE s.minbet>s.maxbet
			AND custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 2)
		
		IF @count > 200000
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 326,cs.sporttype,cs.bettype,cs.CustID,NULL,minbet,maxbet,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Dep_CustBetSetting_Member cs WITH(NOLOCK) ON cs.custid = ci.custid 				
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #ExcludeMember)	
				AND ci.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 1)
				AND cs.minbet>cs.maxbet 
			OPTION (OPTIMIZE FOR (@srecommend = 10580722))
		END	
		ELSE
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 326,cs.sporttype,cs.bettype,cs.CustID,NULL,minbet,maxbet,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Dep_CustBetSetting_Member cs WITH(NOLOCK) ON cs.custid = ci.custid 				
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #ExcludeMember)	
				AND ci.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 1)
				AND cs.minbet>cs.maxbet
		END		
	END
	
	IF @RuleId IN (0,327)  
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 327,s.sporttypeID,s.bettypeID,s.CustID,NULL,Maxbet,maxpermatch,GETDATE(),1
		FROM #Dep_CustSetting_Super s
		WHERE maxbet>maxpermatch  AND s.SporttypeID IN (SELECT SportType FROM #OfferedProductList WHERE SettingType NOT IN (11) )
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 327,s.sporttypeID,s.bettypeID,s.CustID,NULL,Maxbet,maxpermatch,GETDATE(),1
		FROM #Dep_CustSetting_Master s
		WHERE maxbet>maxpermatch AND s.SporttypeID IN (SELECT SportType FROM #OfferedProductList WHERE SettingType NOT IN (11) )
			AND custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 3)
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 327,s.sporttypeID,s.bettypeID,s.CustID,NULL,Maxbet,maxpermatch,GETDATE(),1
		FROM #Dep_CustSetting_Agent s
		WHERE maxbet>maxpermatch AND s.SporttypeID IN (SELECT SportType FROM #OfferedProductList WHERE SettingType NOT IN (11) )
			AND custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 2)
		
		IF @count > 200000
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 327,cs.sporttype,cs.bettype,cs.CustID,NULL,Maxbet,cs.maxpermatch,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Dep_CustBetSetting_Member cs WITH(NOLOCK) ON cs.custid = ci.custid 
				INNER JOIN #OfferedProductList opl WITH(NOLOCK) ON cs.SportType = opl.SportType AND cs.BetType = opl.BetType AND opl.SettingType NOT IN (11) 
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #ExcludeMember)	
				AND ci.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 1)
				AND cs.maxbet> cs.maxpermatch
			OPTION (OPTIMIZE FOR (@srecommend = 10580722))
		END
		ELSE
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 327,cs.sporttype,cs.bettype,cs.CustID,NULL,Maxbet,cs.maxpermatch,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Dep_CustBetSetting_Member cs WITH(NOLOCK) ON cs.custid = ci.custid 
				INNER JOIN #OfferedProductList opl WITH(NOLOCK) ON cs.SportType = opl.SportType AND cs.BetType = opl.BetType AND opl.SettingType NOT IN (11) 
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #ExcludeMember)	
				AND ci.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 1)
				AND cs.maxbet> cs.maxpermatch		
		END		
	END
	-- Rule 329: Maxbet > Global Maxbet -- only settingtype = 11	
	IF @RuleId IN (0,329)  
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 329,s.sporttypeID,s.bettypeID,s.CustID,NULL,s.Maxbet,t2.maxbet,GETDATE(),1
		FROM #Dep_CustSetting_Super s
			INNER JOIN #GlobalSetting T2 ON s.sporttypeID = t2.SportType AND s.bettypeID = t2.BetType AND t2.Maxbet <> 0
		WHERE s.maxbet > T2.Maxbet AND s.Maxbet >= 1
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 329,s.sporttypeID,s.bettypeID,s.CustID,NULL,s.Maxbet,t2.maxbet,GETDATE(),1
		FROM #Dep_CustSetting_Master s
			INNER JOIN #GlobalSetting T2 ON s.sporttypeID = t2.SportType AND s.bettypeID = t2.BetType AND t2.Maxbet <> 0
		WHERE s.maxbet > T2.Maxbet AND s.Maxbet >= 1
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 329,s.sporttypeID,s.bettypeID,s.CustID,NULL,s.Maxbet,t2.maxbet,GETDATE(),1
		FROM #Dep_CustSetting_Agent s
			INNER JOIN #GlobalSetting T2 ON s.sporttypeID = t2.SportType AND s.bettypeID = t2.BetType AND t2.Maxbet <> 0
		WHERE s.maxbet > T2.Maxbet AND s.Maxbet >= 1
		
		IF @count > 200000
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 329,cs.sporttype,cs.bettype,cs.CustID,NULL,cs.Maxbet,t2.maxbet,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Dep_CustBetSetting_Member cs WITH(NOLOCK) ON cs.custid = ci.custid 
				INNER JOIN #GlobalSetting T2 ON cs.sporttype = t2.SportType AND cs.bettype = t2.BetType AND t2.Maxbet <> 0
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #ExcludeMember)	
				AND ci.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 1)
				AND cs.maxbet> T2.Maxbet AND cs.Maxbet >= 1
			OPTION (OPTIMIZE FOR (@srecommend = 10580722))
		END
		ELSE
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 329,cs.sporttype,cs.bettype,cs.CustID,NULL,cs.Maxbet,t2.maxbet,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Dep_CustBetSetting_Member cs WITH(NOLOCK) ON cs.custid = ci.custid
				INNER JOIN #GlobalSetting T2 ON cs.sporttype = t2.SportType AND cs.bettype = t2.BetType AND t2.Maxbet <> 0
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #ExcludeMember)	
				AND ci.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 1)
				AND cs.maxbet> T2.Maxbet AND cs.Maxbet >= 1		
		END	

	END
	-- Minbet < Global Minbet -- only settingtype = 11	
	IF @RuleId IN (0,330)  
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 330,s.sporttypeID,s.bettypeID,s.CustID,NULL,s.minbet,t2.Minbet,GETDATE(),1
		FROM #Dep_CustSetting_Super s
			INNER JOIN #GlobalSetting T2 ON s.sporttypeID = t2.SportType AND s.bettypeID = t2.BetType AND t2.Minbet <> 0
		WHERE s.minbet < T2.minbet AND s.Maxbet >= 1
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 330,s.sporttypeID,s.bettypeID,s.CustID,NULL,s.minbet,t2.Minbet,GETDATE(),1
		FROM #Dep_CustSetting_Master s
			INNER JOIN #GlobalSetting T2 ON s.sporttypeID = t2.SportType AND s.bettypeID = t2.BetType AND t2.Minbet <> 0
		WHERE s.minbet < T2.minbet AND s.Maxbet >= 1
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 330,s.sporttypeID,s.bettypeID,s.CustID,NULL,s.minbet,t2.Minbet,GETDATE(),1
		FROM #Dep_CustSetting_Agent s
			INNER JOIN #GlobalSetting T2 ON s.sporttypeID = t2.SportType AND s.bettypeID = t2.BetType AND t2.Minbet <> 0
		WHERE s.minbet < T2.minbet AND s.Maxbet >= 1
		
		IF @count > 200000
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 330,cs.sporttype,cs.bettype,cs.CustID,NULL,cs.minbet,t2.Minbet,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Dep_CustBetSetting_Member cs WITH(NOLOCK) ON cs.custid = ci.custid 
				INNER JOIN #GlobalSetting T2 ON cs.sporttype = t2.SportType AND cs.bettype = t2.BetType AND t2.Minbet <> 0
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #ExcludeMember)	
				AND ci.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 1)
				AND cs.minbet< T2.minbet AND cs.Maxbet >= 1
			OPTION (OPTIMIZE FOR (@srecommend = 10580722))
		END
		ELSE
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 330,cs.sporttype,cs.bettype,cs.CustID,NULL,cs.minbet,t2.Minbet,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Dep_CustBetSetting_Member cs WITH(NOLOCK) ON cs.custid = ci.custid
				INNER JOIN #GlobalSetting T2 ON cs.sporttype = t2.SportType AND cs.bettype = t2.BetType AND t2.Minbet <> 0
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #ExcludeMember)	
				AND ci.custid NOT IN (SELECT custid FROM #tblCustClosed WHERE roleid = 1)
				AND cs.minbet< T2.minbet AND cs.Maxbet >= 1		
		END	

	END
	--End Dep_CustBetSetting_Agent
	---------------------------------------------------------------------------------

	DROP TABLE #Dep_CustSetting_Super
	DROP TABLE #Dep_CustSetting_Master
	DROP TABLE #Dep_CustSetting_Agent
	DROP TABLE #tmpCust
	DROP TABLE #Dummy
	DROP TABLE #ExcludeAgent
	DROP TABLE #ExcludeMember
	DROP TABLE #tblCustClosed
	DROP TABLE #Dep_CustSettingGroup_Member
END		
GO