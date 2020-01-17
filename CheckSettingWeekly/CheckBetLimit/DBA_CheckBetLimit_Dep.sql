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
	CREATE TABLE #TmpCust (CustID INT PRIMARY KEY)
	
	DECLARE @HideKeno BIT
	DECLARE @DisableKeno BIT,
			@count INT
	
	SELECT @count = COUNT(1)
	FROM CheckCustDB.dbo.custInfo WITH(NOLOCK)
	WHERE srecommend = @srecommend
	
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
		
	---------------------------------------------------------------------------------
	--non-DCS 
	CREATE TABLE #SportTypeCheck (SportType SMALLINT, BetType SMALLINT, MaxPerMatchName VARCHAR(200) )	
	INSERT INTO #SportTypeCheck 
	VALUES
		(1,1,'MaxPerMatch'),
		(2,1,'MaxPerMatch2'),
		(3,1,'MaxPerMatch3'),
		(5,1,'MaxPerMatch5'),
		(8,1,'MaxPerMatch8'),
		(10,1,'MaxPerMatch10'),
		(11,1,'MaxPerMatch11'),		
		(99,1,'MaxPerMatch99'),
		(99,9,'MaxPerMatch99MP')
		
	CREATE TABLE #Dep_CustSetting_Super	(custid INT,SporttypeID INT,BettypeID INT, islive BIT DEFAULT 0, Minbet MONEY, MaxBet MONEY, MaxPermatch MONEY, MaxPerBall MONEY PRIMARY KEY(SporttypeID,BettypeID,IsLive))
	CREATE TABLE #Dep_CustSetting_Master (CustID INT,SporttypeID INT,BettypeID INT, islive BIT DEFAULT 0, Minbet MONEY, MaxBet MONEY, MaxPermatch MONEY, MaxPerBall MONEY PRIMARY KEY(CustID,SporttypeID,BettypeID,IsLive))
	CREATE TABLE #Dep_CustSetting_Agent	(CustID INT, mrecommend INT, SporttypeID INT,BettypeID INT, islive BIT DEFAULT 0, Minbet MONEY, MaxBet MONEY, MaxPermatch MONEY, MaxPerBall MONEY PRIMARY KEY(CustID,SporttypeID,BettypeID,IsLive))
	
	INSERT INTO #Dep_CustSetting_Super(CustID,SporttypeID ,BettypeID,islive,Minbet,MaxBet,MaxPermatch)
	SELECT cs.custid, cs.sporttype,cs.bettype,cs.islive,Minbet,MaxBet,a.MaxPermatch
	FROM CheckCustDB.dbo.Dep_CustSetting cs WITH(NOLOCK) 
		INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON cs.CustID = ci.custid
		CROSS APPLY( VALUES
					('MaxPerMatch',CI.MaxPerMatch),
					('MaxPerMatch2',CI.MaxPerMatch2),
					('MaxPerMatch3',CI.MaxPerMatch3),
					('MaxPerMatch5',CI.MaxPerMatch5),
					('MaxPerMatch8',CI.MaxPerMatch8),
					('MaxPerMatch10',CI.MaxPerMatch10),
					('MaxPerMatch11',CI.MaxPerMatch11),
					('MaxPerMatch99',CI.MaxPerMatch99),
					('MaxPerMatch99MP',CI.MaxPerMatch99MP)
             ) AS A(columnname, MaxPerMatch)
		INNER JOIN #SportTypeCheck S ON S.MaxPerMatchName = A.columnname AND cs.SportType = s.SportType AND cs.BetType = s.BetType
  
	WHERE cs.custid=@srecommend AND cs.sporttype NOT BETWEEN 151 AND 154 AND cs.sporttype <>44
	
	INSERT INTO #Dep_CustSetting_Master(CustID,SporttypeID ,BettypeID,islive,Minbet,MaxBet,MaxPermatch)
	SELECT cs.custid, cs.sporttype,cs.bettype,cs.islive,Minbet,MaxBet,a.MaxPermatch
	FROM CheckCustDB.dbo.Dep_CustSetting cs WITH(NOLOCK) 
		INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON cs.CustID = ci.custid
		CROSS APPLY( VALUES
					('MaxPerMatch',CI.MaxPerMatch),
					('MaxPerMatch2',CI.MaxPerMatch2),
					('MaxPerMatch3',CI.MaxPerMatch3),
					('MaxPerMatch5',CI.MaxPerMatch5),
					('MaxPerMatch8',CI.MaxPerMatch8),
					('MaxPerMatch10',CI.MaxPerMatch10),
					('MaxPerMatch11',CI.MaxPerMatch11),					
					('MaxPerMatch99',CI.MaxPerMatch99),
					('MaxPerMatch99MP',CI.MaxPerMatch99MP)
             ) AS A(columnname, MaxPerMatch)
		INNER JOIN #SportTypeCheck S ON S.MaxPerMatchName = A.columnname AND cs.SportType = s.SportType AND cs.BetType = s.BetType
  
	WHERE ci.srecommend=@srecommend 
		AND ci.roleID = 3
		AND ci.custid NOT IN(SELECT custid FROM #Dummy)
		AND cs.sporttype NOT BETWEEN 151 AND 154 
		AND cs.sporttype <>44
	
	
	INSERT INTO #Dep_CustSetting_Agent(CustID,mrecommend,SporttypeID ,BettypeID,islive,Minbet,MaxBet,MaxPermatch)
	SELECT cs.custid,ci.mrecommend, cs.sporttype,cs.bettype,cs.islive,Minbet,MaxBet,a.MaxPermatch
	FROM CheckCustDB.dbo.Dep_CustSetting cs WITH(NOLOCK) 
		INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON cs.CustID = ci.custid
		CROSS APPLY( VALUES
					('MaxPerMatch',CI.MaxPerMatch),
					('MaxPerMatch2',CI.MaxPerMatch2),
					('MaxPerMatch3',CI.MaxPerMatch3),
					('MaxPerMatch5',CI.MaxPerMatch5),
					('MaxPerMatch8',CI.MaxPerMatch8),
					('MaxPerMatch10',CI.MaxPerMatch10),
					('MaxPerMatch11',CI.MaxPerMatch11),					
					('MaxPerMatch99',CI.MaxPerMatch99),
					('MaxPerMatch99MP',CI.MaxPerMatch99MP)
             ) AS A(columnname, MaxPerMatch)
		INNER JOIN #SportTypeCheck S ON S.MaxPerMatchName = A.columnname AND cs.SportType = s.SportType AND cs.BetType = s.BetType
  
	WHERE ci.srecommend=@srecommend 
		AND ci.roleID = 2
		AND ci.custid NOT IN(SELECT custid FROM #Agent)
		AND cs.sporttype NOT BETWEEN 151 AND 154 
		AND cs.sporttype <>44
		
	IF @ruleid IN (0,317)	
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 317,s.SporttypeID,s.BettypeID,s.custid,ci.CustID,1,0,GETDATE(),1
		FROM CheckCustDB.dbo.custInfo CI (NOLOCK)
			CROSS APPLY (SELECT custid, sporttypeID, bettypeID,islive FROM #Dep_CustSetting_Super) s
			LEFT JOIN #Dep_CustSetting_Master m ON ci.custid = m.custid 
												AND s.SporttypeID=m.SporttypeID 
												AND s.BettypeID=m.BettypeID 
												AND s.islive = m.islive
		WHERE ci.srecommend=@srecommend 
			AND ci.roleID = 3
			AND ci.custid NOT IN(SELECT custid FROM #Dummy)
			AND m.CustID IS NULL
			
	
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 317,s.SporttypeID,s.BettypeID,s.custid,ci.CustID,1,0,GETDATE(),1
		FROM CheckCustDB.dbo.custInfo CI (NOLOCK)
			CROSS APPLY (SELECT custid, sporttypeID, bettypeID,islive FROM #Dep_CustSetting_Super) s
			LEFT JOIN #Dep_CustSetting_Agent m ON ci.custid = m.custid 
												AND s.SporttypeID=m.SporttypeID 
												AND s.BettypeID=m.BettypeID 
												AND s.islive = m.islive
		WHERE ci.srecommend=@srecommend 
			AND ci.roleID = 2
			AND ci.custid NOT IN(SELECT custid FROM #Agent)
			AND m.CustID IS NULL
		
		IF @count > 200000
		BEGIN
			INSERT INTO #tmpCust
			SELECT custid
			FROM (	SELECT ci.custid,(SELECT count(1) 
									FROM CheckCustDB.dbo.Dep_CustSetting cs WITH(NOLOCK)  	
										INNER JOIN #SportTypeCheck s on cs.sporttype = s.SportType and cs.bettype = s.BetType and islive = 0
									WHERE cs.custid = ci.custid) cnt 	
					FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)										
					WHERE ci.srecommend = @srecommend
						AND ci.roleid = 1					
						AND ci.custid NOT IN(SELECT custid FROM #Trade)
			)t	
			WHERE cnt <> (SELECT COUNT(1) FROM #SportTypeCheck)
			OPTION (OPTIMIZE FOR (@srecommend = 10580722))	
		END
		ELSE
		BEGIN
			INSERT INTO #tmpCust
			SELECT custid
			FROM (	SELECT ci.custid,(SELECT count(1) 
									FROM CheckCustDB.dbo.Dep_CustSetting cs WITH(NOLOCK)  	
										INNER JOIN #SportTypeCheck s on cs.sporttype = s.SportType and cs.bettype = s.BetType and islive = 0
									WHERE cs.custid = ci.custid) cnt 	
					FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)										
					WHERE ci.srecommend = @srecommend
						AND ci.roleid = 1					
						AND ci.custid NOT IN(SELECT custid FROM #Trade)
			)t	
			WHERE cnt <> (SELECT COUNT(1) FROM #SportTypeCheck)			
		END
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 317,s.Sporttype,s.Bettype,@srecommend,ci.custid,1,0,GETDATE(),1
		FROM  #tmpCust ci 
			CROSS APPLY #SportTypeCheck s
			LEFT JOIN CheckCustDB.dbo.Dep_CustSetting cs WITH(NOLOCK) ON cs.custid = ci.custid 
														AND cs.sporttype = s.sporttype 
														AND cs.bettype = s.bettype 
														AND cs.islive = 0
		WHERE cs.custid IS NULL
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
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 318,s.sporttypeID,s.bettypeID,s.CustID,NULL,Minbet,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Agent s
		WHERE s.minbet<0 
		
		IF @count > 200000
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 318,cs.sporttype,cs.bettype,cs.CustID,NULL,Minbet,NULL,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Dep_CustSetting cs WITH(NOLOCK) ON cs.custid = ci.custid 	
				INNER JOIN #SportTypeCheck s on cs.sporttype = s.SportType and cs.bettype = s.BetType and islive = 0
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #Trade)	
				AND cs.minbet< 0
			OPTION (OPTIMIZE FOR (@srecommend = 10580722))
		END
		ELSE
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 318,cs.sporttype,cs.bettype,cs.CustID,NULL,Minbet,NULL,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Dep_CustSetting cs WITH(NOLOCK) ON cs.custid = ci.custid 	
				INNER JOIN #SportTypeCheck s on cs.sporttype = s.SportType and cs.bettype = s.BetType and islive = 0
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #Trade)	
				AND cs.minbet< 0			
		END
	END	
	
	IF @RuleId IN (0,319)  
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 319,s.SporttypeID,s.BettypeID,s.custid,m.CustID,s.Minbet,m.Minbet,GETDATE(),1
		FROM #Dep_CustSetting_Super s
			INNER JOIN #Dep_CustSetting_Master m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.IsLive=m.IsLive
		WHERE s.Minbet>m.Minbet
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 319,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.Minbet,m.Minbet,GETDATE(),1
		FROM #Dep_CustSetting_Master s
			INNER JOIN #Dep_CustSetting_Agent m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.IsLive=m.IsLive AND m.mrecommend=s.CustID
		WHERE s.Minbet>m.Minbet
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
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 320,s.sporttypeID,s.bettypeID,s.CustID,NULL,Maxbet,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Agent s
		WHERE s.Maxbet<0 	
		
		IF @count > 200000
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 320,cs.sporttype,cs.bettype,cs.CustID,NULL,Maxbet,NULL,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Dep_CustSetting cs WITH(NOLOCK) ON cs.custid = ci.custid 	
				INNER JOIN #SportTypeCheck s on cs.sporttype = s.SportType and cs.bettype = s.BetType and islive = 0
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #Trade)	
				AND cs.maxbet< 0 	
			OPTION (OPTIMIZE FOR (@srecommend = 10580722))		
		END
		ELSE
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 320,cs.sporttype,cs.bettype,cs.CustID,NULL,Maxbet,NULL,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Dep_CustSetting cs WITH(NOLOCK) ON cs.custid = ci.custid 	
				INNER JOIN #SportTypeCheck s on cs.sporttype = s.SportType and cs.bettype = s.BetType and islive = 0
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #Trade)	
				AND cs.maxbet< 0 	
		END
	END
	
	IF @RuleId IN (0,321)  
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 321,s.SporttypeID,s.BettypeID,s.custid,m.CustID,s.Maxbet,m.Maxbet,GETDATE(),1
		FROM #Dep_CustSetting_Super s
			INNER JOIN #Dep_CustSetting_Master m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.IsLive=m.IsLive
		WHERE s.Maxbet<m.Maxbet
			
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 321,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.Maxbet,m.Maxbet,GETDATE(),1
		FROM #Dep_CustSetting_Master s
			INNER JOIN #Dep_CustSetting_Agent m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.IsLive=m.IsLive AND s.CustID=m.mrecommend
		WHERE s.Maxbet<m.Maxbet
	END
	
	IF @RuleId IN (0,322)  
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 322,s.sporttypeID,s.bettypeID,s.CustID,NULL,MaxPerMatch,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Super s
		WHERE s.MaxPerMatch<0 
					
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 322,s.sporttypeID,s.bettypeID,s.CustID,NULL,MaxPerMatch,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Master s
		WHERE s.MaxPerMatch<0 
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 322,s.sporttypeID,s.bettypeID,s.CustID,NULL,MaxPerMatch,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Agent s
		WHERE s.MaxPerMatch<0 
		
		IF @count > 200000
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 322,s.sporttype,s.bettype,ci.CustID,NULL,a.MaxPerMatch,NULL,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)	
				CROSS APPLY( VALUES
						('MaxPerMatch',CI.MaxPerMatch),
						('MaxPerMatch2',CI.MaxPerMatch2),
						('MaxPerMatch3',CI.MaxPerMatch3),
						('MaxPerMatch5',CI.MaxPerMatch5),
						('MaxPerMatch8',CI.MaxPerMatch8),
						('MaxPerMatch10',CI.MaxPerMatch10),
						('MaxPerMatch11',CI.MaxPerMatch11),
						('MaxPerMatch99',CI.MaxPerMatch99),
						('MaxPerMatch99MP',CI.MaxPerMatch99MP)
				 ) AS A(columnname, MaxPerMatch)
			INNER JOIN #SportTypeCheck S ON S.MaxPerMatchName = A.columnname 
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #Trade)	
				AND a.MaxPerMatch< 0
			OPTION (OPTIMIZE FOR (@srecommend = 10580722))
		END
		ELSE
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 322,s.sporttype,s.bettype,ci.CustID,NULL,a.MaxPerMatch,NULL,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)	
				CROSS APPLY( VALUES
						('MaxPerMatch',CI.MaxPerMatch),
						('MaxPerMatch2',CI.MaxPerMatch2),
						('MaxPerMatch3',CI.MaxPerMatch3),
						('MaxPerMatch5',CI.MaxPerMatch5),
						('MaxPerMatch8',CI.MaxPerMatch8),
						('MaxPerMatch10',CI.MaxPerMatch10),
						('MaxPerMatch11',CI.MaxPerMatch11),
						('MaxPerMatch99',CI.MaxPerMatch99),
						('MaxPerMatch99MP',CI.MaxPerMatch99MP)
				 ) AS A(columnname, MaxPerMatch)
			INNER JOIN #SportTypeCheck S ON S.MaxPerMatchName = A.columnname 
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #Trade)	
				AND a.MaxPerMatch< 0
		END		
	END
	
	IF @RuleId IN (0,323)  
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 323,s.SporttypeID,s.BettypeID,s.custid,m.CustID,s.MaxPerMatch,m.MaxPerMatch,GETDATE(),1
		FROM #Dep_CustSetting_Super s
			INNER JOIN #Dep_CustSetting_Master m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.islive = m.islive
		WHERE s.MaxPerMatch<m.MaxPerMatch
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 323,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.MaxPerMatch,m.MaxPerMatch,GETDATE(),1
		FROM #Dep_CustSetting_Master s
			INNER JOIN #Dep_CustSetting_Agent m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.islive = m.islive AND s.CustID=m.mrecommend
		WHERE s.MaxPerMatch<m.MaxPerMatch			
	END
	
	IF @RuleId IN (0,326)  
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 326,s.sporttypeID,s.bettypeID,s.CustID,NULL,MinBet,Maxbet,GETDATE(),1
		FROM #Dep_CustSetting_Super s
		WHERE s.minbet>s.maxbet 	 
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 326,s.sporttypeID,s.bettypeID,s.CustID,NULL,MinBet,Maxbet,GETDATE(),1
		FROM #Dep_CustSetting_Master s
		WHERE s.minbet>s.maxbet 	 
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 326,s.sporttypeID,s.bettypeID,s.CustID,NULL,MinBet,Maxbet,GETDATE(),1
		FROM #Dep_CustSetting_Agent s
		WHERE s.minbet>s.maxbet
		
		IF @count > 200000
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 326,cs.sporttype,cs.bettype,cs.CustID,NULL,cs.MinBet,cs.Maxbet,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Dep_CustSetting cs WITH(NOLOCK) ON cs.custid = ci.custid 	
				INNER JOIN #SportTypeCheck s on cs.sporttype = s.SportType and cs.bettype = s.BetType and islive = 0
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #Trade)	
				AND cs.minbet>cs.maxbet
			OPTION (OPTIMIZE FOR (@srecommend = 10580722))
		END
		ELSE 
		BEGIN		
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 326,cs.sporttype,cs.bettype,cs.CustID,NULL,cs.MinBet,cs.Maxbet,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Dep_CustSetting cs WITH(NOLOCK) ON cs.custid = ci.custid 	
				INNER JOIN #SportTypeCheck s on cs.sporttype = s.SportType and cs.bettype = s.BetType and islive = 0
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #Trade)	
				AND cs.minbet>cs.maxbet
		END		
	END
	
	IF @RuleId IN (0,327)  
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 327,s.sporttypeID,s.bettypeID,s.CustID,NULL,Maxbet,maxpermatch,GETDATE(),1
		FROM #Dep_CustSetting_Super s
		WHERE maxbet>maxpermatch  
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 327,s.sporttypeID,s.bettypeID,s.CustID,NULL,Maxbet,maxpermatch,GETDATE(),1
		FROM #Dep_CustSetting_Master s
		WHERE maxbet>maxpermatch 
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 327,s.sporttypeID,s.bettypeID,s.CustID,NULL,Maxbet,maxpermatch,GETDATE(),1
		FROM #Dep_CustSetting_Agent s
		WHERE maxbet>maxpermatch 
		
		IF @count > 200000
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 327,cs.sporttype,cs.bettype,cs.CustID,NULL,cs.Maxbet,a.maxpermatch,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)	
				CROSS APPLY( VALUES
						('MaxPerMatch',CI.MaxPerMatch),
						('MaxPerMatch2',CI.MaxPerMatch2),
						('MaxPerMatch3',CI.MaxPerMatch3),
						('MaxPerMatch5',CI.MaxPerMatch5),
						('MaxPerMatch8',CI.MaxPerMatch8),
						('MaxPerMatch10',CI.MaxPerMatch10),
						('MaxPerMatch11',CI.MaxPerMatch11),
						('MaxPerMatch99',CI.MaxPerMatch99),
						('MaxPerMatch99MP',CI.MaxPerMatch99MP)
				 ) AS A(columnname, MaxPerMatch)
				INNER JOIN #SportTypeCheck S ON S.MaxPerMatchName = A.columnname
				INNER JOIN CheckCustDB.dbo.Dep_CustSetting cs WITH(NOLOCK) ON cs.custid = ci.custid AND cs.SportType = s.SportType AND cs.BetType = s.BetType	AND cs.islive = 0
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #Trade)	
				AND cs.maxbet> a.maxpermatch
			OPTION (OPTIMIZE FOR (@srecommend = 10580722))
		END
		ELSE 
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 327,cs.sporttype,cs.bettype,cs.CustID,NULL,cs.Maxbet,a.maxpermatch,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)	
				CROSS APPLY( VALUES
						('MaxPerMatch',CI.MaxPerMatch),
						('MaxPerMatch2',CI.MaxPerMatch2),
						('MaxPerMatch3',CI.MaxPerMatch3),
						('MaxPerMatch5',CI.MaxPerMatch5),
						('MaxPerMatch8',CI.MaxPerMatch8),
						('MaxPerMatch10',CI.MaxPerMatch10),
						('MaxPerMatch11',CI.MaxPerMatch11),
						('MaxPerMatch99',CI.MaxPerMatch99),
						('MaxPerMatch99MP',CI.MaxPerMatch99MP)
				 ) AS A(columnname, MaxPerMatch)
				INNER JOIN #SportTypeCheck S ON S.MaxPerMatchName = A.columnname
				INNER JOIN CheckCustDB.dbo.Dep_CustSetting cs WITH(NOLOCK) ON cs.custid = ci.custid AND cs.SportType = s.SportType AND cs.BetType = s.BetType	AND cs.islive = 0
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #Trade)	
				AND cs.maxbet> a.maxpermatch
		END
	END
	
	TRUNCATE TABLE #Dep_CustSetting_Super
	TRUNCATE TABLE #Dep_CustSetting_Master
	TRUNCATE TABLE #Dep_CustSetting_Agent
	TRUNCATE TABLE #tmpCust
	
	--END Dep_CustSetting
	---------------------------------------------------------------------------------

		
	---------------------------------------------------------------------------------
	--Begin Dep_CustSetting3rd
	INSERT INTO #Dep_CustSetting_Super(CustID,SporttypeID ,BettypeID,islive,Minbet,MaxBet,MaxPermatch,MaxPerBall)
	SELECT cs.custid, cs.sporttype,cs.bettype,cs.islive,Minbet,MaxBet,MaxPermatch161,MaxPerBall161
	FROM CheckCustDB.dbo.Dep_CustSetting3rd cs WITH(NOLOCK) 
		INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON cs.CustID = ci.custid				
	WHERE cs.custid=@srecommend 
		AND cs.sporttype = 161
	
	INSERT INTO #Dep_CustSetting_Master(CustID,SporttypeID ,BettypeID,islive,Minbet,MaxBet,MaxPermatch,MaxPerBall)
	SELECT cs.custid, cs.sporttype,cs.bettype,cs.islive,Minbet,MaxBet,ci.MaxPermatch161,MaxPerBall161
	FROM CheckCustDB.dbo.Dep_CustSetting3rd cs WITH(NOLOCK) 
		INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON cs.CustID = ci.custid		
	WHERE ci.srecommend=@srecommend 
		AND ci.roleID = 3
		AND ci.custid NOT IN(SELECT custid FROM #Dummy)
		AND cs.sporttype = 161
			
	INSERT INTO #Dep_CustSetting_Agent(CustID,mrecommend,SporttypeID ,BettypeID,islive,Minbet,MaxBet,MaxPermatch,MaxPerBall)
	SELECT cs.custid,ci.mrecommend, cs.sporttype,cs.bettype,cs.islive,Minbet,MaxBet,MaxPermatch161,MaxPerBall161
	FROM CheckCustDB.dbo.Dep_CustSetting3rd cs WITH(NOLOCK) 
		INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON cs.CustID = ci.custid		
	WHERE ci.srecommend=@srecommend 
		AND ci.roleID = 2
		AND ci.custid NOT IN(SELECT custid FROM #Agent)
		AND cs.sporttype = 161
		
	IF @RuleId IN (0,317)  
	BEGIN 
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 317,s.SporttypeID,s.BettypeID,s.custid,ci.CustID,1,0,GETDATE(),1
		FROM CheckCustDB.dbo.custInfo CI (NOLOCK)
			CROSS APPLY (SELECT custid, sporttypeID, bettypeID,islive FROM #Dep_CustSetting_Super) s
			LEFT JOIN #Dep_CustSetting_Master m ON ci.custid = m.custid 
												AND s.SporttypeID=m.SporttypeID 
												AND s.BettypeID=m.BettypeID 
												AND s.islive = m.islive
		WHERE ci.srecommend=@srecommend 
			AND ci.roleID = 3
			AND ci.custid NOT IN(SELECT custid FROM #Dummy)
			AND m.CustID IS NULL
	
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 317,s.SporttypeID,s.BettypeID,s.custid,ci.CustID,1,0,GETDATE(),1
		FROM CheckCustDB.dbo.custInfo CI (NOLOCK)
			CROSS APPLY (SELECT custid, sporttypeID, bettypeID,islive FROM #Dep_CustSetting_Super) s
			LEFT JOIN #Dep_CustSetting_Agent m ON ci.custid = m.custid 
												AND s.SporttypeID=m.SporttypeID 
												AND s.BettypeID=m.BettypeID 
												AND s.islive = m.islive
		WHERE ci.srecommend=@srecommend 
			AND ci.roleID = 2
			AND ci.custid NOT IN(SELECT custid FROM #Agent)
			AND m.CustID IS NULL
		
		IF @count > 200000
		BEGIN
			INSERT INTO #tmpCust
			SELECT custid
			FROM (	SELECT ci.custid,(SELECT count(1) 
									FROM CheckCustDB.dbo.Dep_CustSetting3rd cs WITH(NOLOCK) 
									WHERE cs.custid = ci.custid AND cs.sporttype = 161) cnt 	
					FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)										
					WHERE ci.srecommend = @srecommend
						AND ci.roleid = 1					
						AND ci.custid NOT IN(SELECT custid FROM #Trade)
			)t	
			WHERE cnt <> (SELECT COUNT(1) FROM #Dep_CustSetting_Super)
			OPTION (OPTIMIZE FOR (@srecommend = 10580722))	
		END
		ELSE
		BEGIN
			INSERT INTO #tmpCust
			SELECT custid
			FROM (	SELECT ci.custid,(SELECT count(1) 
									FROM CheckCustDB.dbo.Dep_CustSetting3rd cs WITH(NOLOCK) 
									WHERE cs.custid = ci.custid AND cs.sporttype = 161) cnt 	
					FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)										
					WHERE ci.srecommend = @srecommend
						AND ci.roleid = 1					
						AND ci.custid NOT IN(SELECT custid FROM #Trade)
			)t	
			WHERE cnt <> (SELECT COUNT(1) FROM #Dep_CustSetting_Super)				
		END
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 317,s.Sporttype,s.Bettype,@srecommend,ci.custid,1,0,GETDATE(),1
		FROM  #tmpCust ci 
			CROSS APPLY (SELECT sporttypeID as sporttype ,bettypeID as bettype FROM #Dep_CustSetting_Super) s
			LEFT JOIN CheckCustDB.dbo.Dep_CustSetting3rd cs WITH(NOLOCK) ON cs.custid = ci.custid 
														AND cs.sporttype = s.sporttype 
														AND cs.bettype = s.bettype 
		WHERE cs.custid IS NULL
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
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 318,s.sporttypeID,s.bettypeID,s.CustID,NULL,Minbet,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Agent s
		WHERE s.minbet<0 
		
		IF @count > 200000
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 318,cs.sporttype,cs.bettype,cs.CustID,NULL,Minbet,NULL,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Dep_CustSetting3rd cs WITH(NOLOCK) ON cs.custid = ci.custid 				
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #Trade)	
				AND cs.minbet< 0 
				AND cs.sporttype = 161
			OPTION (OPTIMIZE FOR (@srecommend = 10580722))
		END
		ELSE
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 318,cs.sporttype,cs.bettype,cs.CustID,NULL,Minbet,NULL,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Dep_CustSetting3rd cs WITH(NOLOCK) ON cs.custid = ci.custid 				
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #Trade)	
				AND cs.minbet< 0 
				AND cs.sporttype = 161
		END			
	END	
	
	IF @RuleId IN (0,319)  
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 319,s.SporttypeID,s.BettypeID,s.custid,m.CustID,s.Minbet,m.Minbet,GETDATE(),1
		FROM #Dep_CustSetting_Super s
			INNER JOIN #Dep_CustSetting_Master m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.IsLive=m.IsLive
		WHERE s.Minbet>m.Minbet
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 319,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.Minbet,m.Minbet,GETDATE(),1
		FROM #Dep_CustSetting_Master s
			INNER JOIN #Dep_CustSetting_Agent m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.IsLive=m.IsLive AND m.mrecommend=s.CustID
		WHERE s.Minbet>m.Minbet
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
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 320,s.sporttypeID,s.bettypeID,s.CustID,NULL,Maxbet,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Agent s
		WHERE s.Maxbet<0 	
		
		IF @count > 200000
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 320,cs.sporttype,cs.bettype,cs.CustID,NULL,Maxbet,NULL,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Dep_CustSetting3rd cs WITH(NOLOCK) ON cs.custid = ci.custid 				
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #Trade)	
				AND cs.Maxbet< 0 
				AND cs.sporttype = 161	
			OPTION (OPTIMIZE FOR (@srecommend = 10580722))		
		END
		ELSE
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 320,cs.sporttype,cs.bettype,cs.CustID,NULL,Maxbet,NULL,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Dep_CustSetting3rd cs WITH(NOLOCK) ON cs.custid = ci.custid 				
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #Trade)	
				AND cs.Maxbet< 0 
				AND cs.sporttype = 161
		END		
	END
	
	IF @RuleId IN (0,321)  
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 321,s.SporttypeID,s.BettypeID,s.custid,m.CustID,s.Maxbet,m.Maxbet,GETDATE(),1
		FROM #Dep_CustSetting_Super s
			INNER JOIN #Dep_CustSetting_Master m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.IsLive=m.IsLive
		WHERE s.Maxbet<m.Maxbet
			
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 321,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.Maxbet,m.Maxbet,GETDATE(),1
		FROM #Dep_CustSetting_Master s
			INNER JOIN #Dep_CustSetting_Agent m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.IsLive=m.IsLive AND s.CustID=m.mrecommend
		WHERE s.Maxbet<m.Maxbet
	END
	
	IF @RuleId IN (0,322)  
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 322,s.sporttypeID,s.bettypeID,s.CustID,NULL,MaxPerMatch,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Super s
		WHERE s.MaxPerMatch<0 
			AND bettypeID = 81
			AND sporttypeID = 161
			
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 322,s.sporttypeID,s.bettypeID,s.CustID,NULL,MaxPerMatch,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Master s
		WHERE s.MaxPerMatch<0 
			AND bettypeID = 81
			AND sporttypeID = 161
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 322,s.sporttypeID,s.bettypeID,s.CustID,NULL,MaxPerMatch,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Agent s
		WHERE s.MaxPerMatch<0 
			AND bettypeID = 81
			AND sporttypeID = 161
		
		IF @count > 200000
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 322,161,81,s.CustID,NULL,s.MaxPerMatch161,NULL,GETDATE(),1
			FROM CheckCustDB.dbo.custInfo s WITH(NOLOCK) 			
			WHERE s.srecommend=@srecommend 
				AND roleID = 1
				AND s.custid NOT IN(SELECT custid FROM #Trade)
				AND s.MaxPerMatch161<0
			OPTION (OPTIMIZE FOR (@srecommend = 10580722))
		END	
		ELSE
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 322,161,81,s.CustID,NULL,s.MaxPerMatch161,NULL,GETDATE(),1
			FROM CheckCustDB.dbo.custInfo s WITH(NOLOCK) 			
			WHERE s.srecommend=@srecommend 
				AND roleID = 1
				AND s.custid NOT IN(SELECT custid FROM #Trade)
				AND s.MaxPerMatch161<0
		END		
	END
	
	IF @RuleId IN (0,323)  
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 323,s.SporttypeID,s.BettypeID,s.custid,m.CustID,s.MaxPerMatch,m.MaxPerMatch,GETDATE(),1
		FROM #Dep_CustSetting_Super s
			INNER JOIN #Dep_CustSetting_Master m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.islive = m.islive
		WHERE s.MaxPerMatch<m.MaxPerMatch
			AND s.bettypeID = 81
			AND s.sporttypeID = 161
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 323,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.MaxPerMatch,m.MaxPerMatch,GETDATE(),1
		FROM #Dep_CustSetting_Master s
			INNER JOIN #Dep_CustSetting_Agent m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.islive = m.islive AND s.CustID=m.mrecommend
		WHERE s.MaxPerMatch<m.MaxPerMatch
			AND s.bettypeID = 81
			AND s.sporttypeID = 161
	END
	
	IF @RuleId IN (0,324)  
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 324,s.sporttypeID,s.bettypeID,s.CustID,NULL,MaxPerBall,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Super s
		WHERE s.MaxPerBall<0 
			AND s.bettypeID = 81
			AND s.sporttypeID = 161
			
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 324,s.sporttypeID,s.bettypeID,s.CustID,NULL,MaxPerBall,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Master s
		WHERE s.MaxPerBall<0 
			AND s.bettypeID = 81
			AND s.sporttypeID = 161
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 324,s.sporttypeID,s.bettypeID,s.CustID,NULL,MaxPerBall,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Agent s
		WHERE s.MaxPerBall<0 
			AND s.bettypeID = 81
			AND s.sporttypeID = 161
		
		IF @count > 200000
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 324,161,81,s.CustID,NULL,s.MaxPerBall161,NULL,GETDATE(),1
			FROM CheckCustDB.dbo.custInfo s WITH(NOLOCK) 			
			WHERE s.srecommend=@srecommend 
				AND roleID = 1
				AND s.custid NOT IN(SELECT custid FROM #Trade)
				AND s.MaxPerBall161<0	
			OPTION (OPTIMIZE FOR (@srecommend = 10580722))		
		END	
		ELSE
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 324,161,81,s.CustID,NULL,s.MaxPerBall161,NULL,GETDATE(),1
			FROM CheckCustDB.dbo.custInfo s WITH(NOLOCK) 			
			WHERE s.srecommend=@srecommend 
				AND roleID = 1
				AND s.custid NOT IN(SELECT custid FROM #Trade)
				AND s.MaxPerBall161<0
		END		
	END
	
	IF @RuleId IN (0,325)
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 325,s.SporttypeID,s.BettypeID,s.custid,m.CustID,s.MaxPerBall,m.MaxPerBall,GETDATE(),1
		FROM #Dep_CustSetting_Super s
			INNER JOIN #Dep_CustSetting_Master m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID 
		WHERE s.MaxPerBall<m.MaxPerBall
			AND s.bettypeID = 81
			AND s.sporttypeID = 161
			
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 325,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.MaxPerBall,m.MaxPerBall,GETDATE(),1
		FROM #Dep_CustSetting_Master s
			INNER JOIN #Dep_CustSetting_Agent m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID ANd s.CustID=m.mrecommend
		WHERE s.MaxPerBall<m.MaxPerBall
			AND s.bettypeID = 81
			AND s.sporttypeID = 161
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
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 326,s.sporttypeID,s.bettypeID,s.CustID,NULL,minbet,maxbet,GETDATE(),1
		FROM #Dep_CustSetting_Agent s
		WHERE s.minbet>s.maxbet
		
		IF @count > 200000
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 326,cs.sporttype,cs.bettype,cs.CustID,NULL,minbet,maxbet,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Dep_CustSetting3rd cs WITH(NOLOCK) ON cs.custid = ci.custid 				
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #Trade)	
				AND cs.minbet>cs.maxbet
				AND cs.sporttype = 161
			OPTION (OPTIMIZE FOR (@srecommend = 10580722))
		END	
		ELSE
		BEGIN			
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 326,cs.sporttype,cs.bettype,cs.CustID,NULL,minbet,maxbet,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Dep_CustSetting3rd cs WITH(NOLOCK) ON cs.custid = ci.custid 				
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #Trade)	
				AND cs.minbet>cs.maxbet
				AND cs.sporttype = 161
		END
	END
	
	IF @RuleId IN (0,327)  
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 327,s.sporttypeID,s.bettypeID,s.CustID,NULL,Maxbet,maxpermatch,GETDATE(),1
		FROM #Dep_CustSetting_Super s
		WHERE maxbet>maxpermatch  
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 327,s.sporttypeID,s.bettypeID,s.CustID,NULL,Maxbet,maxpermatch,GETDATE(),1
		FROM #Dep_CustSetting_Master s
		WHERE maxbet>maxpermatch 
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 327,s.sporttypeID,s.bettypeID,s.CustID,NULL,Maxbet,maxpermatch,GETDATE(),1
		FROM #Dep_CustSetting_Agent s
		WHERE maxbet>maxpermatch 
		
		IF @count > 200000
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 327,cs.sporttype,cs.bettype,cs.CustID,NULL,maxbet,maxpermatch161,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Dep_CustSetting3rd cs WITH(NOLOCK) ON cs.custid = ci.custid 				
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #Trade)	
				AND cs.maxbet> ci.maxpermatch161 
				AND cs.sporttype = 161
			OPTION (OPTIMIZE FOR (@srecommend = 10580722))
		END	
		ELSE 
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 327,cs.sporttype,cs.bettype,cs.CustID,NULL,maxbet,maxpermatch161,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Dep_CustSetting3rd cs WITH(NOLOCK) ON cs.custid = ci.custid 				
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #Trade)	
				AND cs.maxbet> ci.maxpermatch161 
				AND cs.sporttype = 161
		END		
		
	END
	
	--20200116@Johnson: remove rule 328 from checking
	/*
	IF @RuleId IN (0,328)  
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 328,s.sporttypeID,s.bettypeID,s.CustID,NULL,Maxbet,MaxPerBall,GETDATE(),1
		FROM #Dep_CustSetting_Super s
		WHERE maxbet>MaxPerBall  
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 328,s.sporttypeID,s.bettypeID,s.CustID,NULL,Maxbet,MaxPerBall,GETDATE(),1
		FROM #Dep_CustSetting_Master s
		WHERE maxbet>MaxPerBall 
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 328,s.sporttypeID,s.bettypeID,s.CustID,NULL,Maxbet,MaxPerBall,GETDATE(),1
		FROM #Dep_CustSetting_Agent s
		WHERE maxbet>MaxPerBall 
		
		IF @count > 200000
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 328,cs.sporttype,cs.bettype,cs.CustID,NULL,maxbet,ci.MaxPerBall161,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Dep_CustSetting3rd cs WITH(NOLOCK) ON cs.custid = ci.custid 				
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #Trade)	
				AND cs.maxbet> ci.MaxPerBall161 
				AND cs.sporttype = 161
			OPTION (OPTIMIZE FOR (@srecommend = 10580722))
		END	
		ELSE
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 328,cs.sporttype,cs.bettype,cs.CustID,NULL,maxbet,ci.MaxPerBall161,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Dep_CustSetting3rd cs WITH(NOLOCK) ON cs.custid = ci.custid 				
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #Trade)	
				AND cs.maxbet> ci.MaxPerBall161 
				AND cs.sporttype = 161
		END		
	END
	*/
	
	TRUNCATE TABLE #Dep_CustSetting_Super
	TRUNCATE TABLE #Dep_CustSetting_Master
	TRUNCATE TABLE #Dep_CustSetting_Agent	
	TRUNCATE TABLE #tmpCust
	--End Dep_CustSetting3rd
	---------------------------------------------------------------------------------

	---------------------------------------------------------------------------------
	--BEGIN Dep_CustSettingGame
	--20200116@Johnson: remove AG checking
	/*
	INSERT INTO #Dep_CustSetting_Super(custid,SporttypeID ,BettypeID)
	SELECT cs.custid,cs.sporttype,cs.bettype
	FROM CheckCustDB.dbo.Dep_CustSettingGame cs WITH(NOLOCK) 			
	WHERE cs.CustID=@srecommend AND cs.sporttype<>203	

	INSERT INTO #Dep_CustSetting_Master(CustID ,SporttypeID ,BettypeID)
	SELECT c.custid,cs.sporttype,cs.bettype
	FROM CheckCustDB.dbo.Dep_CustSettingGame cs WITH(NOLOCK) 
		INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON cs.Custid=c.custid
	WHERE c.srecommend=@srecommend AND c.roleid=3 AND cs.sporttype<>203
		AND c.custid NOT IN(SELECT custid FROM #Dummy)	

	INSERT INTO #Dep_CustSetting_Agent(CustID ,SporttypeID ,BettypeID)
	SELECT c.custid,cs.sporttype,cs.bettype
	FROM CheckCustDB.dbo.Dep_CustSettingGame cs WITH(NOLOCK) 
		INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON cs.Custid=c.custid
	WHERE c.srecommend=@srecommend AND c.roleid=2 AND cs.sporttype<>203
		AND c.custid NOT IN(SELECT custid FROM #Agent)
		
	INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
	SELECT 317,s.SporttypeID,s.BettypeID,s.custid,ci.CustID,1,0,GETDATE(),1
	FROM CheckCustDB.dbo.custInfo CI (NOLOCK)
		CROSS APPLY (SELECT custid, sporttypeID, bettypeID,islive FROM #Dep_CustSetting_Super) s
		LEFT JOIN #Dep_CustSetting_Master m ON ci.custid = m.custid 
											AND s.SporttypeID=m.SporttypeID 
											AND s.BettypeID=m.BettypeID 
											AND s.islive = m.islive
	WHERE ci.srecommend=@srecommend 
		AND ci.roleID = 3
		AND ci.custid NOT IN(SELECT custid FROM #Dummy)
		AND m.CustID IS NULL
	
	INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
	SELECT 317,s.SporttypeID,s.BettypeID,s.custid,ci.CustID,1,0,GETDATE(),1
	FROM CheckCustDB.dbo.custInfo CI (NOLOCK)
		CROSS APPLY (SELECT custid, sporttypeID, bettypeID,islive FROM #Dep_CustSetting_Super) s
		LEFT JOIN #Dep_CustSetting_Agent m ON ci.custid = m.custid 
											AND s.SporttypeID=m.SporttypeID 
											AND s.BettypeID=m.BettypeID 
											AND s.islive = m.islive
	WHERE ci.srecommend=@srecommend 
		AND ci.roleID = 2
		AND ci.custid NOT IN(SELECT custid FROM #Agent)
		AND m.CustID IS NULL
	
	IF @count > 200000
	BEGIN
		INSERT INTO #tmpCust
		SELECT custid
		FROM (	SELECT ci.custid,(SELECT count(1) 
								FROM CheckCustDB.dbo.Dep_CustSettingGame cs WITH(NOLOCK) 
								WHERE cs.custid = ci.custid AND cs.sporttype <>203) cnt 	
				FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)										
				WHERE ci.srecommend = @srecommend
					AND ci.roleid = 1					
					AND ci.custid NOT IN(SELECT custid FROM #Trade)
		)t	
		WHERE cnt <> (SELECT COUNT(1) FROM #Dep_CustSetting_Super)
		OPTION (OPTIMIZE FOR (@srecommend = 10580722))	
	END
	ELSE
	BEGIN
		INSERT INTO #tmpCust
		SELECT custid
		FROM (	SELECT ci.custid,(SELECT count(1) 
								FROM CheckCustDB.dbo.Dep_CustSettingGame cs WITH(NOLOCK) 
								WHERE cs.custid = ci.custid AND cs.sporttype <>203) cnt 	
				FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)										
				WHERE ci.srecommend = @srecommend
					AND ci.roleid = 1					
					AND ci.custid NOT IN(SELECT custid FROM #Trade)
		)t	
		WHERE cnt <> (SELECT COUNT(1) FROM #Dep_CustSetting_Super)				
	END
	
	INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
	SELECT 317,s.Sporttype,s.Bettype,@srecommend,ci.custid,1,0,GETDATE(),1
	FROM  #tmpCust ci 
		CROSS APPLY (SELECT sporttypeID as sporttype ,bettypeID as bettype FROM #Dep_CustSetting_Super) s
		LEFT JOIN CheckCustDB.dbo.Dep_CustSettingGame cs WITH(NOLOCK) ON cs.custid = ci.custid 
													AND cs.sporttype = s.sporttype 
													AND cs.bettype = s.bettype 
	WHERE cs.custid IS NULL		
	
	TRUNCATE TABLE #Dep_CustSetting_Super
	TRUNCATE TABLE #Dep_CustSetting_Master
	TRUNCATE TABLE #Dep_CustSetting_Agent
	TRUNCATE TABLE #tmpCust
	*/
	--End Dep_CustSettingGame
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
		AND ci.custid NOT IN(SELECT custid FROM #Agent)
		
	
	IF @ruleid IN (0,317)
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 317,s.SporttypeID,s.BettypeID,s.custid,ci.CustID,1,0,GETDATE(),1
		FROM CheckCustDB.dbo.custInfo CI (NOLOCK)
			CROSS APPLY (SELECT custid, sporttypeID, bettypeID,islive FROM #Dep_CustSetting_Super) s
			LEFT JOIN #Dep_CustSetting_Master m ON ci.custid = m.custid 
												AND s.SporttypeID=m.SporttypeID 
												AND s.BettypeID=m.BettypeID 
												AND s.islive = m.islive
		WHERE ci.srecommend=@srecommend 
			AND ci.roleID = 3
			AND ci.custid NOT IN(SELECT custid FROM #Dummy)
			AND m.CustID IS NULL
	
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 317,s.SporttypeID,s.BettypeID,s.custid,ci.CustID,1,0,GETDATE(),1
		FROM CheckCustDB.dbo.custInfo CI (NOLOCK)
			CROSS APPLY (SELECT custid, sporttypeID, bettypeID,islive FROM #Dep_CustSetting_Super) s
			LEFT JOIN #Dep_CustSetting_Agent m ON ci.custid = m.custid 
												AND s.SporttypeID=m.SporttypeID 
												AND s.BettypeID=m.BettypeID 
												AND s.islive = m.islive
		WHERE ci.srecommend=@srecommend 
			AND ci.roleID = 2
			AND ci.custid NOT IN(SELECT custid FROM #Agent)
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
						AND ci.custid NOT IN(SELECT custid FROM #Trade)
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
						AND ci.custid NOT IN(SELECT custid FROM #Trade)
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
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 318,s.sporttypeID,s.bettypeID,s.CustID,NULL,Minbet,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Agent s
		WHERE s.minbet<0 
		
		IF @count > 200000
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 318,cs.sporttype,cs.bettype,cs.CustID,NULL,Minbet,NULL,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Dep_CustBetSetting_Member cs WITH(NOLOCK) ON cs.custid = ci.custid 				
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #Trade)	
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
				AND ci.custid NOT IN(SELECT custid FROM #Trade)	
				AND cs.minbet< 0 	
		END		
	END	
	
	IF @RuleId IN (0,319)  
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 319,s.SporttypeID,s.BettypeID,s.custid,m.CustID,s.Minbet,m.Minbet,GETDATE(),1
		FROM #Dep_CustSetting_Super s
			INNER JOIN #Dep_CustSetting_Master m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.IsLive=m.IsLive
		WHERE s.Minbet>m.Minbet
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 319,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.Minbet,m.Minbet,GETDATE(),1
		FROM #Dep_CustSetting_Master s
			INNER JOIN #Dep_CustSetting_Agent m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.IsLive=m.IsLive AND m.mrecommend=s.CustID
		WHERE s.Minbet>m.Minbet
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
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 320,s.sporttypeID,s.bettypeID,s.CustID,NULL,Maxbet,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Agent s
		WHERE s.Maxbet<0 	
		
		IF @count > 200000
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 320,cs.sporttype,cs.bettype,cs.CustID,NULL,Maxbet,NULL,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Dep_CustBetSetting_Member cs WITH(NOLOCK) ON cs.custid = ci.custid 				
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #Trade)	
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
				AND ci.custid NOT IN(SELECT custid FROM #Trade)	
				AND cs.Maxbet< 0 	
		END		
	END
	
	IF @RuleId IN (0,321)  
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 321,s.SporttypeID,s.BettypeID,s.custid,m.CustID,s.Maxbet,m.Maxbet,GETDATE(),1
		FROM #Dep_CustSetting_Super s
			INNER JOIN #Dep_CustSetting_Master m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.IsLive=m.IsLive
		WHERE s.Maxbet<m.Maxbet
			
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 321,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.Maxbet,m.Maxbet,GETDATE(),1
		FROM #Dep_CustSetting_Master s
			INNER JOIN #Dep_CustSetting_Agent m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.IsLive=m.IsLive AND s.CustID=m.mrecommend
		WHERE s.Maxbet<m.Maxbet
	END
	
	IF @RuleId IN (0,322)  
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 322,s.sporttypeID,s.bettypeID,s.CustID,NULL,MaxPerMatch,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Super s
		WHERE s.MaxPerMatch<0 
					
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 322,s.sporttypeID,s.bettypeID,s.CustID,NULL,MaxPerMatch,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Master s
		WHERE s.MaxPerMatch<0 
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 322,s.sporttypeID,s.bettypeID,s.CustID,NULL,MaxPerMatch,NULL,GETDATE(),1
		FROM #Dep_CustSetting_Agent s
		WHERE s.MaxPerMatch<0 
		
		IF @count > 200000
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 322,cs.sporttype,cs.bettype,cs.CustID,NULL,cs.MaxPerMatch,NULL,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Dep_CustBetSetting_Member cs WITH(NOLOCK) ON cs.custid = ci.custid 				
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #Trade)	
				AND cs.MaxPerMatch< 0 
			OPTION (OPTIMIZE FOR (@srecommend = 10580722))
		END
		ELSE
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 322,cs.sporttype,cs.bettype,cs.CustID,NULL,cs.MaxPerMatch,NULL,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Dep_CustBetSetting_Member cs WITH(NOLOCK) ON cs.custid = ci.custid 				
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #Trade)	
				AND cs.MaxPerMatch< 0 
		END		
	END
	
	IF @RuleId IN (0,323)  
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 323,s.SporttypeID,s.BettypeID,s.custid,m.CustID,s.MaxPerMatch,m.MaxPerMatch,GETDATE(),1
		FROM #Dep_CustSetting_Super s
			INNER JOIN #Dep_CustSetting_Master m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.islive = m.islive
		WHERE s.MaxPerMatch<m.MaxPerMatch
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 323,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.MaxPerMatch,m.MaxPerMatch,GETDATE(),1
		FROM #Dep_CustSetting_Master s
			INNER JOIN #Dep_CustSetting_Agent m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.islive = m.islive AND s.CustID=m.mrecommend
		WHERE s.MaxPerMatch<m.MaxPerMatch			
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
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 326,s.sporttypeID,s.bettypeID,s.CustID,NULL,minbet,maxbet,GETDATE(),1
		FROM #Dep_CustSetting_Agent s
		WHERE s.minbet>s.maxbet
		
		IF @count > 200000
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 326,cs.sporttype,cs.bettype,cs.CustID,NULL,minbet,maxbet,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Dep_CustBetSetting_Member cs WITH(NOLOCK) ON cs.custid = ci.custid 				
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #Trade)	
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
				AND ci.custid NOT IN(SELECT custid FROM #Trade)	
				AND cs.minbet>cs.maxbet
		END		
	END
	
	IF @RuleId IN (0,327)  
	BEGIN
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 327,s.sporttypeID,s.bettypeID,s.CustID,NULL,Maxbet,maxpermatch,GETDATE(),1
		FROM #Dep_CustSetting_Super s
		WHERE maxbet>maxpermatch  
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 327,s.sporttypeID,s.bettypeID,s.CustID,NULL,Maxbet,maxpermatch,GETDATE(),1
		FROM #Dep_CustSetting_Master s
		WHERE maxbet>maxpermatch 
		
		INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
		SELECT 327,s.sporttypeID,s.bettypeID,s.CustID,NULL,Maxbet,maxpermatch,GETDATE(),1
		FROM #Dep_CustSetting_Agent s
		WHERE maxbet>maxpermatch 
		
		IF @count > 200000
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 327,cs.sporttype,cs.bettype,cs.CustID,NULL,Maxbet,cs.maxpermatch,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Dep_CustBetSetting_Member cs WITH(NOLOCK) ON cs.custid = ci.custid 				
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #Trade)	
				AND cs.maxbet> cs.maxpermatch
			OPTION (OPTIMIZE FOR (@srecommend = 10580722))
		END
		ELSE
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 327,cs.sporttype,cs.bettype,cs.CustID,NULL,Maxbet,cs.maxpermatch,GETDATE(),1
			FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Dep_CustBetSetting_Member cs WITH(NOLOCK) ON cs.custid = ci.custid 				
			WHERE ci.srecommend = @srecommend
				AND ci.roleid = 1
				AND ci.custid NOT IN(SELECT custid FROM #Trade)	
				AND cs.maxbet> cs.maxpermatch		
		END		
	END
	
	TRUNCATE TABLE #Dep_CustSetting_Super
	TRUNCATE TABLE #Dep_CustSetting_Master
	TRUNCATE TABLE #Dep_CustSetting_Agent
	TRUNCATE TABLE #tmpCust
	--End Dep_CustBetSetting_Agent
	---------------------------------------------------------------------------------
	
	---------------------------------------------------------------------------------
	--Begin CustGameType
	IF @HideKeno=0 AND @DisableKeno=0
	BEGIN
		INSERT INTO #Dep_CustSetting_Super(CustID,SporttypeID ,BettypeID,Minbet,MaxBet,MaxPermatch)
		SELECT cs.custid, 202,1501,Minbet,MaxBet,cs.MaxPerGameType
		FROM CheckCustDB.dbo.CustGameType cs WITH(NOLOCK) 				
		WHERE cs.custid=@srecommend 
			AND cs.gameTypeID = 1
				
		INSERT INTO #Dep_CustSetting_Master(CustID,SporttypeID,BettypeID,Minbet,MaxBet,MaxPermatch)
		SELECT cs.custid, 202,1501,Minbet,MaxBet,cs.MaxPerGameType
		FROM CheckCustDB.dbo.CustGameType cs WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON cs.CustID = ci.custid		
		WHERE ci.srecommend=@srecommend 
			AND ci.roleID = 3
			AND ci.custid NOT IN(SELECT custid FROM #Dummy)
			AND cs.gameTypeID = 1
		
		INSERT INTO #Dep_CustSetting_Agent(CustID,mrecommend,SporttypeID,BettypeID,Minbet,MaxBet,MaxPermatch)
		SELECT cs.custid,ci.mrecommend, 202,1501,Minbet,MaxBet,cs.MaxPerGameType
		FROM CheckCustDB.dbo.CustGameType cs WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON cs.CustID = ci.custid		
		WHERE ci.srecommend=@srecommend 
			AND ci.roleID = 2
			AND ci.custid NOT IN(SELECT custid FROM #Agent)
			AND cs.gameTypeID = 1
			
		/*
		INSERT INTO #Dep_CustSetting_Member(CustID,SporttypeID ,BettypeID,Num,Minbet,MaxBet,MaxPermatch)
		SELECT cs.custid, 202,1501,
				(	
					SELECT COUNT(cs2.custid)
					FROM CheckCustDB.dbo.CustGameType cs2 WITH(NOLOCK) 			
					WHERE cs2.custid= cs.custid
						AND cs2.GameTypeID = cs.GameTypeID				
				),Minbet,MaxBet,cs.MaxPerGameType
		FROM CheckCustDB.dbo.CustGameType cs WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON cs.CustID = ci.custid		
		WHERE ci.srecommend=@srecommend 
			AND ci.roleID = 1
			AND ci.custid NOT IN(SELECT custid FROM #Trade)
			AND cs.gameTypeID = 1		
		*/
		
		IF @ruleid IN (0,317)
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 317,s.SporttypeID,s.BettypeID,s.custid,ci.CustID,1,0,GETDATE(),1
			FROM CheckCustDB.dbo.custInfo CI (NOLOCK)
				CROSS APPLY (SELECT custid, sporttypeID, bettypeID,islive FROM #Dep_CustSetting_Super) s
				LEFT JOIN #Dep_CustSetting_Master m ON ci.custid = m.custid 
													AND s.SporttypeID=m.SporttypeID 
													AND s.BettypeID=m.BettypeID 
													AND s.islive = m.islive
			WHERE ci.srecommend=@srecommend 
				AND ci.roleID = 3
				AND ci.custid NOT IN(SELECT custid FROM #Dummy)
				AND m.CustID IS NULL
		
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 317,s.SporttypeID,s.BettypeID,s.custid,ci.CustID,1,0,GETDATE(),1
			FROM CheckCustDB.dbo.custInfo CI (NOLOCK)
				CROSS APPLY (SELECT custid, sporttypeID, bettypeID,islive FROM #Dep_CustSetting_Super) s
				LEFT JOIN #Dep_CustSetting_Agent m ON ci.custid = m.custid 
													AND s.SporttypeID=m.SporttypeID 
													AND s.BettypeID=m.BettypeID 
													AND s.islive = m.islive
			WHERE ci.srecommend=@srecommend 
				AND ci.roleID = 2
				AND ci.custid NOT IN(SELECT custid FROM #Agent)
				AND m.CustID IS NULL
			
			IF @count > 200000
			BEGIN
				INSERT INTO #tmpCust
				SELECT custid
				FROM (	SELECT ci.custid,(SELECT count(1) 
										FROM CheckCustDB.dbo.CustGameType cs WITH(NOLOCK) 
										WHERE cs.custid = ci.custid  AND cs.gameTypeID = 1) cnt 	
						FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)										
						WHERE ci.srecommend = @srecommend
							AND ci.roleid = 1					
							AND ci.custid NOT IN(SELECT custid FROM #Trade)
				)t	
				WHERE cnt <> (SELECT COUNT(1) FROM #Dep_CustSetting_Super)
				OPTION (OPTIMIZE FOR (@srecommend = 10580722))	
			END
			ELSE
			BEGIN
				INSERT INTO #tmpCust
				SELECT custid
				FROM (	SELECT ci.custid,(SELECT count(1) 
										FROM CheckCustDB.dbo.CustGameType cs WITH(NOLOCK) 
										WHERE cs.custid = ci.custid  AND cs.gameTypeID = 1) cnt 	
						FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)										
						WHERE ci.srecommend = @srecommend
							AND ci.roleid = 1					
							AND ci.custid NOT IN(SELECT custid FROM #Trade)
				)t	
				WHERE cnt <> (SELECT COUNT(1) FROM #Dep_CustSetting_Super)				
			END
			
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 317,202,1501,@srecommend,ci.custid,1,0,GETDATE(),1
			FROM  #tmpCust ci 				
				LEFT JOIN CheckCustDB.dbo.CustGameType cs WITH(NOLOCK) ON cs.custid = ci.custid 
															AND cs.GameTypeID = 1
			WHERE cs.custid IS NULL
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
			
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 318,s.sporttypeID,s.bettypeID,s.CustID,NULL,Minbet,NULL,GETDATE(),1
			FROM #Dep_CustSetting_Agent s
			WHERE s.minbet<0 
			
			IF @count > 200000
			BEGIN
				INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
				SELECT 318,202,1501,cs.CustID,NULL,Minbet,NULL,GETDATE(),1
				FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
					INNER JOIN CheckCustDB.dbo.CustGameType cs WITH(NOLOCK) ON cs.custid = ci.custid 				
				WHERE ci.srecommend = @srecommend
					AND ci.roleid = 1
					AND ci.custid NOT IN(SELECT custid FROM #Trade)	
					AND cs.minbet< 0  				
				OPTION (OPTIMIZE FOR (@srecommend = 10580722))
			END
			ELSE
			BEGIN
				INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
				SELECT 318,202,1501,cs.CustID,NULL,Minbet,NULL,GETDATE(),1
				FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
					INNER JOIN CheckCustDB.dbo.CustGameType cs WITH(NOLOCK) ON cs.custid = ci.custid 				
				WHERE ci.srecommend = @srecommend
					AND ci.roleid = 1
					AND ci.custid NOT IN(SELECT custid FROM #Trade)	
					AND cs.minbet< 0 
			END	
		END	
		
		IF @RuleId IN (0,319)  
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 319,s.SporttypeID,s.BettypeID,s.custid,m.CustID,s.Minbet,m.Minbet,GETDATE(),1
			FROM #Dep_CustSetting_Super s
				INNER JOIN #Dep_CustSetting_Master m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.IsLive=m.IsLive
			WHERE s.Minbet>m.Minbet
			
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 319,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.Minbet,m.Minbet,GETDATE(),1
			FROM #Dep_CustSetting_Master s
				INNER JOIN #Dep_CustSetting_Agent m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.IsLive=m.IsLive AND m.mrecommend=s.CustID
			WHERE s.Minbet>m.Minbet
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
			
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 320,s.sporttypeID,s.bettypeID,s.CustID,NULL,Maxbet,NULL,GETDATE(),1
			FROM #Dep_CustSetting_Agent s
			WHERE s.Maxbet<0 	
			
			IF @count > 200000
			BEGIN
				INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
				SELECT 320,202,1501,cs.CustID,NULL,Maxbet,NULL,GETDATE(),1
				FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
					INNER JOIN CheckCustDB.dbo.CustGameType cs WITH(NOLOCK) ON cs.custid = ci.custid 				
				WHERE ci.srecommend = @srecommend
					AND ci.roleid = 1
					AND ci.custid NOT IN(SELECT custid FROM #Trade)	
					AND cs.Maxbet< 0 		
				OPTION (OPTIMIZE FOR (@srecommend = 10580722))
			END
			ELSE
			BEGIN	
				INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
				SELECT 320,202,1501,cs.CustID,NULL,Maxbet,NULL,GETDATE(),1
				FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
					INNER JOIN CheckCustDB.dbo.CustGameType cs WITH(NOLOCK) ON cs.custid = ci.custid 				
				WHERE ci.srecommend = @srecommend
					AND ci.roleid = 1
					AND ci.custid NOT IN(SELECT custid FROM #Trade)	
					AND cs.Maxbet< 0 		
			END		
		END
		
		IF @RuleId IN (0,321)  
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 321,s.SporttypeID,s.BettypeID,s.custid,m.CustID,s.Maxbet,m.Maxbet,GETDATE(),1
			FROM #Dep_CustSetting_Super s
				INNER JOIN #Dep_CustSetting_Master m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.IsLive=m.IsLive
			WHERE s.Maxbet<m.Maxbet
				
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 321,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.Maxbet,m.Maxbet,GETDATE(),1
			FROM #Dep_CustSetting_Master s
				INNER JOIN #Dep_CustSetting_Agent m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.IsLive=m.IsLive AND s.CustID=m.mrecommend
			WHERE s.Maxbet<m.Maxbet
		END
		
		IF @RuleId IN (0,322)  
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 322,s.sporttypeID,s.bettypeID,s.CustID,NULL,MaxPerMatch,NULL,GETDATE(),1
			FROM #Dep_CustSetting_Super s
			WHERE s.MaxPerMatch<0 
						
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 322,s.sporttypeID,s.bettypeID,s.CustID,NULL,MaxPerMatch,NULL,GETDATE(),1
			FROM #Dep_CustSetting_Master s
			WHERE s.MaxPerMatch<0 
			
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 322,s.sporttypeID,s.bettypeID,s.CustID,NULL,MaxPerMatch,NULL,GETDATE(),1
			FROM #Dep_CustSetting_Agent s
			WHERE s.MaxPerMatch<0 
			
			IF @count > 200000
			BEGIN
				INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
				SELECT 322,202,1501,cs.CustID,NULL,MaxPerGameType,NULL,GETDATE(),1
				FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
					INNER JOIN CheckCustDB.dbo.CustGameType cs WITH(NOLOCK) ON cs.custid = ci.custid 				
				WHERE ci.srecommend = @srecommend
					AND ci.roleid = 1
					AND ci.custid NOT IN(SELECT custid FROM #Trade)	
					AND cs.MaxPerGameType< 0  
				OPTION (OPTIMIZE FOR (@srecommend = 10580722))
			END
			ELSE
			BEGIN	
				INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
				SELECT 322,202,1501,cs.CustID,NULL,MaxPerGameType,NULL,GETDATE(),1
				FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
					INNER JOIN CheckCustDB.dbo.CustGameType cs WITH(NOLOCK) ON cs.custid = ci.custid 				
				WHERE ci.srecommend = @srecommend
					AND ci.roleid = 1
					AND ci.custid NOT IN(SELECT custid FROM #Trade)	
					AND cs.MaxPerGameType< 0  
			END		
		END
		
		IF @RuleId IN (0,323)  
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 323,s.SporttypeID,s.BettypeID,s.custid,m.CustID,s.MaxPerMatch,m.MaxPerMatch,GETDATE(),1
			FROM #Dep_CustSetting_Super s
				INNER JOIN #Dep_CustSetting_Master m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.islive = m.islive
			WHERE s.MaxPerMatch<m.MaxPerMatch
			
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 323,s.SporttypeID,s.BettypeID,s.CustID,m.CustID,s.MaxPerMatch,m.MaxPerMatch,GETDATE(),1
			FROM #Dep_CustSetting_Master s
				INNER JOIN #Dep_CustSetting_Agent m ON  s.SporttypeID=m.SporttypeID AND s.BettypeID=m.BettypeID AND s.islive = m.islive AND s.CustID=m.mrecommend
			WHERE s.MaxPerMatch<m.MaxPerMatch			
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
			
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 326,s.sporttypeID,s.bettypeID,s.CustID,NULL,minbet,maxbet,GETDATE(),1
			FROM #Dep_CustSetting_Agent s
			WHERE s.minbet>s.maxbet
			
			IF @count > 200000
			BEGIN
				INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
				SELECT 326,202,1501,cs.CustID,NULL,minbet,maxbet,GETDATE(),1
				FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
					INNER JOIN CheckCustDB.dbo.CustGameType cs WITH(NOLOCK) ON cs.custid = ci.custid 				
				WHERE ci.srecommend = @srecommend
					AND ci.roleid = 1
					AND ci.custid NOT IN(SELECT custid FROM #Trade)	
					AND cs.minbet>cs.maxbet 
				OPTION (OPTIMIZE FOR (@srecommend = 10580722))
			END
			ELSE
			BEGIN
				INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
				SELECT 326,202,1501,cs.CustID,NULL,minbet,maxbet,GETDATE(),1
				FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
					INNER JOIN CheckCustDB.dbo.CustGameType cs WITH(NOLOCK) ON cs.custid = ci.custid 				
				WHERE ci.srecommend = @srecommend
					AND ci.roleid = 1
					AND ci.custid NOT IN(SELECT custid FROM #Trade)	
					AND cs.minbet>cs.maxbet 
			END		
		END
		
		IF @RuleId IN (0,327)  
		BEGIN
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 327,s.sporttypeID,s.bettypeID,s.CustID,NULL,Maxbet,maxpermatch,GETDATE(),1
			FROM #Dep_CustSetting_Super s
			WHERE maxbet>maxpermatch  
			
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 327,s.sporttypeID,s.bettypeID,s.CustID,NULL,Maxbet,maxpermatch,GETDATE(),1
			FROM #Dep_CustSetting_Master s
			WHERE maxbet>maxpermatch 
			
			INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
			SELECT 327,s.sporttypeID,s.bettypeID,s.CustID,NULL,Maxbet,maxpermatch,GETDATE(),1
			FROM #Dep_CustSetting_Agent s
			WHERE maxbet>maxpermatch 
			
			IF @count > 200000
			BEGIN
				INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
				SELECT 327,202,1501,cs.CustID,NULL,maxbet,MaxPerGameType,GETDATE(),1
				FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
					INNER JOIN CheckCustDB.dbo.CustGameType cs WITH(NOLOCK) ON cs.custid = ci.custid 				
				WHERE ci.srecommend = @srecommend
					AND ci.roleid = 1
					AND ci.custid NOT IN(SELECT custid FROM #Trade)	
					AND cs.maxbet> cs.MaxPerGameType
				OPTION (OPTIMIZE FOR (@srecommend = 10580722))
			END
			ELSE
			BEGIN
				INSERT INTO [dbo].[CheckBetLimitResult](RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsDeposit])
				SELECT 327,202,1501,cs.CustID,NULL,maxbet,MaxPerGameType,GETDATE(),1
				FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)			
					INNER JOIN CheckCustDB.dbo.CustGameType cs WITH(NOLOCK) ON cs.custid = ci.custid 				
				WHERE ci.srecommend = @srecommend
					AND ci.roleid = 1
					AND ci.custid NOT IN(SELECT custid FROM #Trade)	
					AND cs.maxbet> cs.MaxPerGameType
			END		
		END
	END
	--End CustGameType
	---------------------------------------------------------------------------------

END		