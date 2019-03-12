/*<info serverAlias="DBCHECK-CheckResultDB" executers="" viewers="" isFunction="0"></info>*/
USE CheckResultDB
GO
ALTER PROCEDURE [dbo].[DBA_CheckPositionTaking_DepCustSettingGame]
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

	SELECT @site = Site FROM CheckCustDB.dbo.Dep_CustSuper WITH(NOLOCK) WHERE custid=@srecommend

	DELETE m
	FROM #tmpDumMember m
		INNER JOIN #Trade t ON m.CustID=t.CustID	
	
	IF @RuleId IN (0,50)  
	BEGIN
		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 50,s.sporttype,s.bettype,s.custid,NULL,s.apositiontaking,NULL,GETDATE(),0
			FROM CheckCustDB.dbo.CustSettingGame s WITH(NOLOCK)							
				INNER JOIN #tmpDumMember c ON s.custid=c.custid	
			WHERE
				c.roleid=1 AND (s.bettype BETWEEN 1501 AND 1524) AND (s.apositiontaking <> 0.9	OR s.mpositiontaking<>0 OR s.spositiontaking<>0)
	END

END
	
