/*<info serverAlias="DBCUST-CUSTDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_RobotAccounts_VirtualRate_Upd]	
AS
/*
	Created by: 20200114@Johnson	
	Task: Auto adjust VR setting for Robot accounts under IBO
	DB: DBCUST/CUSTDB
	
	Revisions:
		- 20200114@Johnson: initial sp [redmine:#126998]
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @CustIDs VARCHAR(MAX)	
	CREATE TABLE #tblCust (CustID INT PRIMARY KEY,isBA BIT DEFAULT 0, isFinished BIT DEFAULT 0)
	
	INSERT INTO #tblCust(custid)
	EXEC DBONUSER.ON_USER.dbo.Task_RobotAccountsIBO_Sel
			
	UPDATE t
	SET isBA = 1
	FROM #tblCust t
		INNER JOIN Dep_CustBAActive c WITH(NOLOCK) ON t.custid = c.custid
		
	IF (SELECT count(1) FROM #tblCust WHERE isBA = 0) = 0 
		RETURN;
		
	--PROCESSING UPDATE
	DECLARE	@tblVirtualrate		TABLE (
										SportType			INT
									,	BetType				INT
									,	IsLive				BIT
									,	VirtualMultiplier	SMALLMONEY	
									);

	INSERT INTO	@tblVirtualrate (
							SportType
						,	BetType
						,	IsLive
						,	VirtualMultiplier
					)
	SELECT	sporttype,bettype,islive,CASE WHEN sporttype = 2 THEN 3 ELSE 1 END 
	from ProfileVirtualSetting 		
	WHERE sporttype NOT IN (1,43)

	DECLARE	@virtualXML			TABLE (
										seqNo		TINYINT PRIMARY KEY
									,	Pos			VARBINARY(64)
									,	Val			VARBINARY(64)
									);
									
	INSERT INTO @virtualXML
				(	seqNo, Pos, Val                       )
			SELECT	seqNo, p1.Pos, p2.Val
			FROM (
				SELECT	DISTINCT seqNo
				FROM	ProfileVirtualSetting WITH (NOLOCK)
			) pvs
			CROSS APPLY (
				SELECT CONVERT(VARBINARY(64), (
					SELECT	CONVERT(VARCHAR, CAST(ipvs.profileID - 64 * (ipvs.seqNo - 1) AS BINARY(1)), 2)
					FROM		@tblVirtualrate			AS tmp
						INNER JOIN	ProfileVirtualSetting	AS ipvs WITH (NOLOCK)
							ON	tmp.sporttype	= ipvs.sporttype
								AND	tmp.bettype		= ipvs.bettype
								AND	tmp.isLive		= ipvs.islive
					WHERE	ipvs.seqNo = pvs.seqNo
					FOR XML PATH ('')						
				), 2) AS Pos
			) p1
			CROSS APPLY (
				SELECT CONVERT(VARBINARY(64), (
					SELECT	CONVERT(VARCHAR, CAST(CASE WHEN CAST(VirtualMultiplier * 100 AS INT) > 200 THEN ((CAST(VirtualMultiplier * 100 AS INT) - 200) / 5 + 200) ELSE CAST(VirtualMultiplier * 100 AS INT) END AS BINARY(1)), 2)
					FROM		@tblVirtualrate			AS tmp
						INNER JOIN	ProfileVirtualSetting	AS ipvs WITH (NOLOCK)
							ON	tmp.sporttype	= ipvs.sporttype
								AND	tmp.bettype		= ipvs.bettype
								AND	tmp.isLive		= ipvs.islive
					WHERE	ipvs.seqNo = pvs.seqNo
					FOR XML PATH ('')						
				), 2) AS Val
			) p2;
	
	DECLARE @tmp TABLE (custid INT)

	WHILE(1=1)	
	BEGIN
		UPDATE TOP (1000) c		
		SET c.isFinished = 1
		OUTPUT DELETED.custid INTO @tmp
		FROM #tblCust c
		WHERE isBA = 0 
			AND isFinished = 0
		
		IF @@ROWCOUNT = 0 BREAK;
		
		UPDATE cvs
			SET cvs.bitmapVirtual = bm.bitmap
		FROM		CustVirtualSetting	AS cvs WITH(UPDLOCK, ROWLOCK)			
			INNER JOIN	@virtualXML			AS tmp
					ON	cvs.seqNo = tmp.seqNo
			CROSS APPLY (SELECT TOP 1 bitmap FROM dbo.f_GenerateVirtualSetting_inline(cvs.bitmapVirtual, tmp.Val, tmp.Pos)) AS bm
		WHERE	cvs.custid IN (SELECT custid FROM @tmp)
		
		DELETE @tmp
		
		WAITFOR DELAY '0:0:0.28'
		
	END	
END
GO