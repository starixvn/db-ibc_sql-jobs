/*<info serverAlias="DBCHECK-CheckResultDB" executers="" viewers="" isFunction="0"></info>*/
USE CheckResultDB
GO
ALTER PROCEDURE [dbo].[DBA_CheckPositionTaking_DepCustSetting3rd]
(
	@srecommend	INT   
	,@RuleId		SMALLINT = 0  
)
AS
/*
	Created: 20180827@Winnie.Vu
	Task :   Check PT rules (Deposit)
	DB: DB052.CheckResultDB
	Original:

	Revisions:
		-20180827@Winnie.Vu: Create SP
		-20190128@Winnie: Update PT RedmineID:#108062
	Param's Explanation:
	
*/
SET NOCOUNT ON
BEGIN
	IF @srecommend IN(1752415,932209,1574083,179457)--'AB88SuperRM' , '12BETSuperSD$',MS88SuperBND,'ITSA'
	RETURN
	DECLARE @site VARCHAR(20)	
	SELECT @site = Site FROM CheckCustDB.dbo.Dep_CustSuper WITH(NOLOCK) WHERE custid=@srecommend
	CREATE TABLE #tmpDumMember (CustID INT , username VARCHAR(30),RoleID INT,PRIMARY KEY(CustID,RoleID))
	CREATE TABLE #Trade (CustID INT PRIMARY KEY)
	CREATE TABLE #Dummy (CustID INT PRIMARY KEY)

	INSERT INTO #tmpDumMember(custid, username,RoleID)
	SELECT c.CustID, fc.username,c.RoleID
	FROM CheckCustDB.dbo.custInfo c WITH(NOLOCK) 
	 CROSS APPLY (
	  SELECT TOP 1 custid, username
	  FROM CheckCustDB.dbo.Customer cc WITH(NOLOCK)
	  WHERE c.custid = cc.custid 
	 ) fc
	WHERE c.srecommend = @srecommend
	 AND c.roleid IN(1,3)	
	 AND c.Enabled=1



	INSERT INTO #Dummy(CustID)
	SELECT d.custid
	FROM #tmpDumMember d
	WHERE (username LIKE '%Acc%' OR username LIKE '%AFF%' OR username LIKE '%LocalBank%' OR username like 'AB88'+'CAS%')	
	AND d.RoleID=3

	INSERT INTO #Trade(CustID)
	SELECT d.custid
	FROM #tmpDumMember d
	WHERE (username LIKE '%Bettrade%' OR username LIKE '%CashOut%' OR username LIKE '%TransferUUS%' OR username LIKE '%ClearBal%')
	AND d.RoleID=1
	UNION
	SELECT c.CustID
	FROM CheckCustDB.dbo.CustInfo c WITH(NOLOCK)
		INNER JOIN #Dummy d ON c.mrecommend=d.CustID

	DELETE m
	FROM #tmpDumMember m
		INNER JOIN #Trade t ON m.CustID=t.CustID
	
	IF @RuleId IN (0,44)  
	BEGIN
		CREATE TABLE #tmpS(Sporttype INT, Bettype INT, Islive BIT, PT SMALLMONEY,PRIMARY KEY(Sporttype,Bettype,Islive))
		CREATE TABLE #tmpM(CustID INT,Sporttype INT, Bettype INT, Islive BIT, PT SMALLMONEY,PRIMARY KEY(CustID,Sporttype,Bettype,Islive))
				
		INSERT INTO #tmpS (Sporttype , Bettype , Islive , PT)
		SELECT s.sporttype,s.bettype,s.islive,s.spositiontaking
		FROM CheckCustDB.dbo.Dep_CustSetting3rd s WITH(NOLOCK)			
		WHERE s.custid=@srecommend AND sporttype NOT BETWEEN 151 AND 154 
		
		INSERT INTO #tmpM (CustID,Sporttype , Bettype , Islive , PT)
		SELECT c.custid, s.sporttype,s.bettype,s.islive,s.mpositiontaking
		FROM CheckCustDB.dbo.Dep_CustSetting3rd s WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.CustInfo c WITH(NOLOCK) ON s.custid=c.custid	
		WHERE c.srecommend=@srecommend AND c.roleid=3 AND c.custid NOT IN(SELECT custid FROM #Dummy)
			AND sporttype NOT BETWEEN 151 AND 154 

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 44,s.sporttype,s.bettype,@srecommend,m.CustID,s.PT ,m.PT,GETDATE(),s.islive 
		FROM #tmpS s 
			INNER JOIN #tmpM m ON s.Sporttype=m.Sporttype AND s.Bettype=m.Bettype AND s.Islive=m.Islive
		WHERE s.PT<>m.PT		
	END
	IF @RuleId IN (0,45)  
	BEGIN
		CREATE TABLE #tmpM45(CustID INT,Sporttype INT, Bettype INT, Islive BIT, PT SMALLMONEY,PRIMARY KEY(CustID,Sporttype,Bettype,Islive))
		CREATE TABLE #tmpA45(CustID INT,Sporttype INT, Bettype INT, Islive BIT,mrecommend INT, PT SMALLMONEY,PRIMARY KEY(CustID,Sporttype,Bettype,Islive,mrecommend))

		
		INSERT INTO #tmpM45 (CustID, Sporttype , Bettype , Islive , PT)
		SELECT s.custid, s.sporttype,s.bettype,s.islive,s.mpositiontaking
		FROM CheckCustDB.dbo.Dep_CustSetting3rd s WITH(NOLOCK)	
			INNER JOIN CheckCustDB.dbo.CustInfo c WITH(NOLOCK) ON s.custid=c.custid		
		WHERE c.srecommend=@srecommend AND c.roleid=3 AND c.custid NOT IN(SELECT custid FROM #Dummy)
			AND sporttype NOT BETWEEN 151 AND 154 
		
		INSERT INTO #tmpA45 (CustID,Sporttype , Bettype , Islive , PT,mrecommend)
		SELECT c.custid, s.sporttype,s.bettype,s.islive,s.apositiontaking,c.mrecommend
		FROM CheckCustDB.dbo.Dep_CustSetting3rd s WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.CustInfo c WITH(NOLOCK) ON s.custid=c.custid	
		WHERE c.srecommend=@srecommend AND c.roleid=2
			AND sporttype NOT BETWEEN 151 AND 154 

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 45,s.sporttype,s.bettype,s.CustID,m.CustID,s.PT ,m.PT,GETDATE(),s.islive 
		FROM #tmpM45 s 
			INNER JOIN #tmpA45 m ON s.Sporttype=m.Sporttype AND s.Bettype=m.Bettype AND s.Islive=m.Islive AND s.CustID=m.mrecommend
		WHERE s.PT<>m.PT


	END
	IF @RuleId IN (0,46)  
	BEGIN		
		CREATE TABLE #tmpA1(CustID INT,Sporttype INT, Bettype INT, Islive BIT,recommend INT, PT SMALLMONEY,PRIMARY KEY(CustID,Sporttype,Bettype,Islive,recommend))
		CREATE TABLE #tmpA2(CustID INT,Sporttype INT, Bettype INT, Islive BIT, PT SMALLMONEY,PRIMARY KEY(CustID,Sporttype,Bettype,Islive))	
		
		INSERT INTO #tmpA2 (CustID, Sporttype , Bettype , Islive , PT)
		SELECT s.custid, s.sporttype,s.bettype,s.islive,s.apositiontaking
		FROM CheckCustDB.dbo.Dep_CustSetting3rd s WITH(NOLOCK)	
			INNER JOIN CheckCustDB.dbo.CustInfo c WITH(NOLOCK) ON s.custid=c.custid		
		WHERE c.srecommend=@srecommend AND c.roleid=2 AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)
			AND sporttype NOT BETWEEN 151 AND 154 
		
		INSERT INTO #tmpA1 (CustID,Sporttype , Bettype , Islive , PT,recommend)
		SELECT c.custid, s.sporttype,s.bettype,s.islive,s.apositiontaking,c.recommend
		FROM CheckCustDB.dbo.Dep_CustSetting3rd s WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.custInfo c WITH(NOLOCK) ON s.custid=c.custid				
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND c.custid NOT IN(SELECT custid FROM #Trade)
			AND sporttype NOT BETWEEN 151 AND 154 

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 46,s.sporttype,s.bettype,s.CustID,m.CustID,s.PT ,m.PT,GETDATE(),s.islive 
		FROM #tmpA1 s 
			INNER JOIN #tmpA2 m ON s.Sporttype=m.Sporttype AND s.Bettype=m.Bettype AND s.Islive=m.Islive AND m.CustID=s.recommend
		WHERE s.PT<>m.PT		

	END

	IF @RuleId IN(0,48)
	BEGIN		
		
		IF @site NOT IN('HAIFA','KeenOcean','WeBet168','NextBet','Opal88','BBIN2','9wickets')		
		BEGIN
			IF @site IN('Lucky88', '11bet', 'Fabet', 'One88' , 'FB88')
			BEGIN
				INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
				SELECT 48,s.sporttype,s.bettype,s.custid,NULL,s.apositiontaking,NULL,GETDATE(),s.islive 
				FROM CheckCustDB.dbo.Dep_CustSetting3rd s WITH(NOLOCK)		
					INNER JOIN #tmpDumMember c  ON s.custid=c.custid		
				WHERE c.roleid=1 AND s.sporttype=161 AND (s.apositiontaking <> 0.85 OR s.mpositiontaking<>0 OR s.spositiontaking<>0)	
				
			END
			ELSE
			BEGIN			
				INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
				SELECT 48,s.sporttype,s.bettype,s.custid,NULL,s.apositiontaking,NULL,GETDATE(),s.islive 
				FROM CheckCustDB.dbo.Dep_CustSetting3rd s WITH(NOLOCK)		
					INNER JOIN #tmpDumMember c  ON s.custid=c.custid	
				WHERE  c.roleid=1 AND s.sporttype=161 AND (s.apositiontaking <> 0.88 OR s.mpositiontaking<>0 OR s.spositiontaking<>0)
					
			END
		END	
	END

	
	IF @RuleId IN (0,53)
	BEGIN	
	
		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 53,s.sporttype,s.bettype,c.custid,NULL,s.spositiontaking+s.mpositiontaking+s.apositiontaking,NULL,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustSetting3rd s WITH(NOLOCK)
			INNER JOIN #tmpDumMember c  ON s.custid=c.custid	
			INNER JOIN CheckCustDB.dbo.Dep_CustBAActive BA WITH(NOLOCK) ON c.custid=BA.CustId
		WHERE c.roleid=1 AND s.spositiontaking+s.mpositiontaking+s.apositiontaking <> 0
			
	END
END
	
