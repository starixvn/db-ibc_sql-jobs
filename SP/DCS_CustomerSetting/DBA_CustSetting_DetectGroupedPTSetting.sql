alter PROCEDURE dbo.DBA_CustSetting_DetectGroupedPTSetting
(
	@srecommend int = NULL, 
	--@maxCustID int = 0,
	@Threshold_cnt INT = 100,
	@GetTop INT = 10
)
AS
/*
	Created By: Helen
	Created Date: 20151027
	Description: Detect grouped PT setting before maintenance
	DB: DBCust/Custdb
	Param explaination:
		@Threshold_cnt: 100. It means that only detecting supers have more than 100 members
	
*/
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP 10 srecommend
	INTO #srecommend_temp
	FROM custInfo WITH (NOLOCK)	
	WHERE roleid = 1 AND (@srecommend IS NULL OR srecommend = @srecommend)
		--AND Currency = 20 -- UUS
		
	GROUP BY srecommend
	HAVING COUNT(*) >= @Threshold_cnt
	ORDER BY COUNT(*) DESC
	
	CREATE TABLE #tempData (srecommend int,recommend int, custid int, cs1 bigint, cs2 int)
	CREATE TABLE #tempGroup(srecommend int,recommend int, cs1 bigint, cs2 int, memberCNT int, repCustID int)

	;WITH _s as (
		SELECT c.srecommend, c.recommend, c.custid	
			,rdSetting = CAST(DENSE_RANK() OVER(ORDER BY sporttype, bettype, islive, superPT, masterPT, agentPT, isAutoMasterPT, AutoMasterPT, isAutoSuperPT, AutoSuperPT) as INT)
			,rdProduct = CAST(DENSE_RANK() OVER(ORDER BY sporttype, bettype, islive) as INT)
		FROM dbo.custinfo c WITH(NOLOCK)
			INNER JOIN dbo.CustPTSetting3rd_Member pt WITH(NOLOCK) ON c.custid = pt.custid		
		WHERE EXISTS (SELECT 1 FROM #srecommend_temp WHERE srecommend = C.srecommend)
			AND roleid = 1
			--AND c.custid < @maxcustid
	)
	INSERT INTO #tempdata (srecommend, recommend, custid, cs1, cs2)
	SELECT srecommend,recommend, custid, SUM(CONVERT(bigint,rdSetting) + POWER(2, rdProduct%10+1)), CHECKSUM_AGG(CHECKSUM(HASHBYTES('SHA1', CONVERT(nvarchar(max), rdSetting))))
	FROM _s
	GROUP BY srecommend,recommend, custid

	INSERT INTO #tempGroup(srecommend,recommend, cs1, cs2, memberCNT, repCustID)
	SELECT srecommend,recommend, cs1, cs2, memberCnt, repCustID
	FROM (
		SELECT srecommend,recommend, cs1, cs2, rn = ROW_NUMBER() OVER (partition by recommend ORDER BY count(1) desc), memberCnt = count(1), repCustID = max(custid)
		FROM #tempdata
		GROUP BY srecommend,recommend, cs1, cs2
	) x
	WHERE rn = 1
	
	
	SELECT TOP (@GetTop) tempG.srecommend, tempG.recommend,t.GroupedMemberCurrent_cnt , tempG.memberCNT AS GroupedMemberNew_Cnt
			,Diff_cnt= tempG.memberCNT - t.GroupedMemberCurrent_cnt 
			--,Diff_percent = CAST(tempG.memberCNT AS FLOAT) / CAST(t.GroupedMemberCnt_Current AS FLOAT) * 100
	FROM #tempGroup tempG
		CROSS APPLY (SELECT COUNT(CS.CustID) AS GroupedMemberCurrent_cnt
					FROM CustSettingMode3rd CS (NOLOCK)
						JOIN custInfo CI WITH (NOLOCK) ON CS.CustID = CI.custid
					WHERE CI.recommend = tempG.recommend AND CI.roleid = 1
						AND CS.IsGrouped = 1) AS T	
	ORDER BY (tempG.memberCNT - t.GroupedMemberCurrent_cnt) DESC
	
	DROP TABLE #TempData
	DROP TABLE #tempGroup
	
	SET NOCOUNT OFF
END




