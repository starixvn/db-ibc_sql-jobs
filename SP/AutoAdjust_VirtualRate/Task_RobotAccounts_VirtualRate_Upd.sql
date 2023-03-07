/*<info serverAlias="DBCUST-CUSTDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_RobotAccounts_VirtualRate_Upd]	
AS
/*
	Created by: 20200114@Johnson	
	Task: Auto adjust VR setting for Robot accounts under IBO
	DB: DBCUST/CUSTDB
	
	Revisions:
		- 20200114@Johnson: initial sp [redmine:#126998]
		- 20200221@Johnson: adjust VR setting = 0 for Basketball [Redmine:#128966]
		- 20200617@Eden: Virtual Rate for Basketball [Redmine: #134978] 
		- 20210510@Eden: Enhancement for not relying on DB On_User [redmine: #154507]
		- 20230307@Johnson: Return Basketball VR to its original state [redmine:#184339]
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @startRun datetime  
	DECLARE @endRun datetime  
	DECLARE @duration int 
		
	CREATE TABLE #tblCust (CustID INT PRIMARY KEY,isBA BIT DEFAULT 0, isFinished BIT DEFAULT 0, isLog BIT DEFAULT 0)
	
	SET @startRun = GETDATE() 
	
	INSERT INTO #tblCust(custid)
	EXEC dbo.Task_RobotAccountsIBO_Sel_Wrapper
			
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
	SELECT	sporttype,bettype,islive, 1 
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
	
	--LOGGING
	DECLARE @LogSPData VARCHAR(MAX) = '',
			@custid INT
	
	SELECT @LogSPData =
		(
			SELECT SportType
				,BetType
				,IsLive
				,VirtualMultiplier
			FROM @tblVirtualrate
			ORDER BY sporttype,isLive DESC,bettype
			FOR XML  RAW('s')
		)
	
	SELECT @LogSPData = '<R>' + @LogSPData + '</R>'
	
	SET @endRun = GETDATE()  
	SET @duration  = DATEDIFF (millisecond,@startRun,@endRun) 
	  
	WHILE(1=1)
	BEGIN
		UPDATE TOP (1) t
		SET @custid = custid,
			isLog = 1	
		FROM #tblCust t
		WHERE isLog = 0
			AND isBA = 0
		
		IF @@ROWCOUNT = 0
			BREAK;
		
		EXEC Acc_WriteLog_UserLog_RunSP_Wrapper
			@UserID = 862400,--Starix2
			@CustID = @CustID,
			@ActionID = 810,
			@TrackingValue = @LogSPData,
			@duration = @duration	
	END
END
GO