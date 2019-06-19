/*<info serverAlias="DBCHECK-CheckResultDB" executers="" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[DBA_CheckSuspendInfoStatus_Credit]
	@ruleid SMALLINT  = 0
AS
/*
	Created: 20190610@Johnson
	Task: check suspendinfo status for credit
	DB: DBCHECK.CheckResultDB
	
	Revisions:
		- 20190610@Johnson: initial sp [redmine: #105587]
*/
BEGIN
	-------------------PREPARATION: GET LIST SUPER/Master/Agent disabled FIRST----------------------------
		
	CREATE TABLE #DCS_Super (custID INT, reject BIT)
	CREATE TABLE #DCS_Master (custID INT, reject BIT)
	CREATE TABLE #DCS_Agent (custID INT, reject BIT)
	
	INSERT INTO #DCS_Super (custID,reject)
	SELECT ci.CustID, reject
	FROM CheckCustDB.dbo.custInfo CI (NOLOCK) 
		INNER JOIN CheckCustDB.dbo.CustSuper CS WITH (NOLOCK)  ON CI.srecommend = CS.custid AND CS.IsInternal = 0		
	WHERE CI.roleid = 4 		
		AND ci.srecommend NOT IN (SELECT custid FROM CheckCustDB.dbo.Dep_CustSuper WITH(NOLOCK))
		AND CI.Enabled = 1
		AND CI.Currency NOT IN (0,20,72,27)
		AND CI.username NOT LIKE '%Acc%'
		AND CI.username NOT LIKE '%3rdSuper%'
		AND CI.username NOT LIKE 'STEST%'
		AND CI.username NOT LIKE '%cashout%'
		AND CI.username NOT LIKE '%dummy%'
		AND CI.username NOT LIKE '%BetTrade%'
		

	INSERT INTO #DCS_Master (custID,reject)
	SELECT CPS.CustID, reject
	FROM CheckCustDB.dbo.custInfo CI (NOLOCK)
		INNER JOIN CheckCustDB.dbo.CustSuper CS WITH (NOLOCK)  ON CI.srecommend = CS.custid AND CS.IsInternal = 0 		
	WHERE CI.roleid = 3 
		AND cs.CustID IN (SELECT CustID FROM #DCS_Super)		
		AND ci.srecommend NOT IN (SELECT custid FROM CheckCustDB.dbo.Dep_CustSuper WITH(NOLOCK))
		AND CI.Enabled = 1
		AND CI.Currency NOT IN (0,20,72,27)
		AND CI.username NOT LIKE '%Acc%'
		AND CI.username NOT LIKE '%3rdSuper%'
		AND CI.username NOT LIKE 'STEST%'
		AND CI.username NOT LIKE '%cashout%'
		AND CI.username NOT LIKE '%dummy%'
		AND CI.username NOT LIKE '%BetTrade%'
		
	INSERT INTO #DCS_Agent (custID,reject)
	SELECT CPS.CustID, reject
	FROM CheckCustDB.dbo.custInfo CI (NOLOCK)
		INNER JOIN CheckCustDB.dbo.CustSuper CS WITH (NOLOCK)  ON CI.srecommend = CS.custid AND CS.IsInternal = 0 		
	WHERE CI.roleid = 2 
		AND cs.CustID IN (SELECT CustID FROM #DCS_Super)		
		AND ci.srecommend NOT IN (SELECT custid FROM CheckCustDB.dbo.Dep_CustSuper WITH(NOLOCK))
		AND CI.Enabled = 1
		AND CI.Currency NOT IN (0,20,72,27)
		AND CI.username NOT LIKE '%Acc%'
		AND CI.username NOT LIKE '%3rdSuper%'
		AND CI.username NOT LIKE 'STEST%'
		AND CI.username NOT LIKE '%cashout%'
		AND CI.username NOT LIKE '%dummy%'
		AND CI.username NOT LIKE '%BetTrade%'
	-------------------END OF PREPARATION: GET LIST SUPER/Master/Agent disabled FIRST----------------------------
	----------------------------FINAL RESULT ------------------------------------
	-- Rule 17: reject status <> suspendInfo on upline 
	;WITH T AS(
	SELECT ci.custid,ci.roleid,ci.username, ci.reject, 
	CASE WHEN s.reject = 1 THEN 4 
		ELSE (CASE WHEN m.reject = 1 THEN 3 
				ELSE (CASE WHEN a.reject = 1 THEN 2
						ELSE ci.reject END)
				END) 
		END suspendLevel,	
	CASE WHEN s.reject = 1 THEN s.custid 
		ELSE (CASE WHEN m.reject = 1 THEN m.custid 
				ELSE (CASE WHEN a.reject = 1 THEN a.custid
						ELSE ci.custid END)
				END) 
		END custIDB,	
		p.SuspendInfo								
	FROM CheckCustDB.dbo.custInfo ci (nolock)
		INNER JOIN CheckCustDB.dbo.custproductstatus p WITH(NOLOCK) on ci.custid = p.custid
		INNER JOIN #DCS_super s on ci.srecommend = s.custid
		LEFT JOIN #DCS_Master m on ci.mrecommend = m.custid
		LEFT JOIN #DCS_Agent a on ci.recommend = a.custid	
	)
	INSERT INTO [CheckResultDB].[dbo].[CheckStatusResult]
           ([RuleId]
           ,[SportType]
           ,[BetType]
           ,[CustIdA]
           ,[CustIdB]
           ,[ValueA]
           ,[ValueB]
           ,[CreatedDate]
           ,[IsDeposit]) 
	SELECT 17 ruleid, 0, 0, custid as custidA, custidB, reject as valueA, suspendUpline valueB, getdate(), 0     
	FROM t
		CROSS APPLY (SELECT cast(suspendInfo as bit) as suspendUpline FROM CheckCustDB.dbo.f_GetSuspendInfoStatus(suspendLevel,suspendInfo)) s
	WHERE reject <> suspendUpline
END							
GO



	