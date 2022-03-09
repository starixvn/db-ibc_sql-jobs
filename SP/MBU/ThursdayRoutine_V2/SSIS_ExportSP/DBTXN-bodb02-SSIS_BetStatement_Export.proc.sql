/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_BetStatement_Export]
	@winlostdate smalldatetime=null
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]	
	Database: DBTXN.bodb02
	Original: Task_Archive_SelectBetStatement
	
	Revisions:
		- 20130831@Bobby: Init
 */
BEGIN 
	SET NOCOUNT ON 

	Declare @min_winlostdate smalldatetime,
			@max_winlostdate smalldatetime


	SELECT
		@min_winlostdate = @winlostdate,
		@max_winlostdate = @winlostdate

	--SELECT
	--	@min_winlostdate = MIN(winlostdate),
	--	@max_winlostdate = MAX(winlostdate)
	--FROM dbo.Task_ArchiveDate

	-- custid, accdate, totalamt, transtype, transdesc
	-- Member - winlost & commission & Grand Prize
	--INSERT INTO DB06.bodb_Report.dbo.statement
	select custid,winlostdate accdate,sum(winlost-actual_stake) totalamt,CAST('BET' AS varchar(128)) transtype, CAST('Betting' AS varchar(1000)) AS transdesc
		from bettrans14 bettrans with (nolock)
		where bettype between 1 and 19999 and winlostdate BETWEEN @min_winlostdate AND @max_winlostdate
		group by winlostdate,custid
		--HAVING sum(winlost-actual_stake) <> 0
	UNION ALL
	--INSERT INTO DB06.bodb_Report.dbo.statement
		select custid,winlostdate accdate,sum(playercomm) totalamt,'COM' transtype, 'Commission' transdesc
		from dbo.bettrans14 bettrans  with (nolock)
		where bettype between 1 and 19999 and winlostdate BETWEEN @min_winlostdate AND @max_winlostdate
		group by winlostdate,custid
		HAVING sum(playercomm) <> 0

	UNION ALL
	--INSERT INTO DB06.bodb_Report.dbo.statement
	SELECT custid, accdate, SUM(totalamt) as totalamt, 'GP' AS transtype, 'Grand Prize' AS transdesc
	FROM (
			--SELECT b.custid, b.winlostdate AS accdate, SUM(bm.winlost - bm.stake) AS totalamt
			--FROM bettrans14 b WITH (NOLOCK)
			--	INNER JOIN bettransm14 bm WITH (NOLOCK)
			--		ON b.refno = bm.refno
			--WHERE b.bettype = 18000
			--	AND b.winlostdate BETWEEN @min_winlostdate AND @max_winlostdate
			--	AND bm.statuswinlost <> 0
			--GROUP BY b.winlostdate, b.custid
			--HAVING SUM(bm.winlost - bm.stake) <> 0

			--UNION ALL
			SELECT b.custid, b.winlostdate AS accdate, SUM(b.WinAmount) AS totalamt
			FROM dbo.PayoutTrans b WITH(NOLOCK) 
			WHERE b.winlostdate BETWEEN @min_winlostdate AND @max_winlostdate	
				  AND PayoutStatusId IN (4, 5)  ----- 'Completed', 'Expired'			
			GROUP BY b.winlostdate, b.custid
			HAVING SUM(b.WinAmount) <> 0
		) GP
	GROUP BY custid, accdate

		

	UNION ALL
	-- Agent - position & commission
	--INSERT INTO DB06.bodb_Report.dbo.statement
		select recommend,winlostdate accdate,sum(awinlost) totalamt,'POS' transtype, 'Position' transdesc
		from dbo.bettrans14 bettrans with (nolock)
		where bettype between 1 and 19999 and winlostdate BETWEEN @min_winlostdate AND @max_winlostdate
		group by winlostdate,recommend
		HAVING sum(awinlost) <> 0
	UNION ALL
	--INSERT INTO DB06.bodb_Report.dbo.statement
		select recommend,winlostdate accdate,sum(comm-playercomm) totalamt,'COM' transtype, 'Commission' transdesc
		from dbo.bettrans14 bettrans  with (nolock)
		where bettype between 1 and 19999 and winlostdate BETWEEN @min_winlostdate AND @max_winlostdate
		group by winlostdate,recommend
		HAVING sum(comm-playercomm) <> 0
	UNION ALL
	-- Master - position & commission
	--INSERT INTO DB06.bodb_Report.dbo.statement
		select mrecommend,winlostdate accdate,sum(mwinlost) totalamt,'POS' transtype, 'Position' transdesc
		from dbo.bettrans14 bettrans with (nolock)
		where bettype between 1 and 19999 and winlostdate BETWEEN @min_winlostdate AND @max_winlostdate
		group by winlostdate,mrecommend
		HAVING sum(mwinlost) <> 0
	UNION ALL
	--INSERT INTO DB06.bodb_Report.dbo.statement
		select mrecommend,winlostdate accdate,sum(acomm-comm) totalamt,'COM' transtype, 'Commission' transdesc
		from dbo.bettrans14 bettrans with (nolock)
		where bettype between 1 and 19999 and winlostdate BETWEEN @min_winlostdate AND @max_winlostdate
		group by winlostdate,mrecommend
		HAVING sum(acomm-comm) <> 0
	UNION ALL
	-- Super - position & commission
	--INSERT INTO DB06.bodb_Report.dbo.statement
		select srecommend,winlostdate accdate,sum(swinlost) totalamt,'POS' transtype, 'Position' transdesc
		from dbo.bettrans14 bettrans with (nolock)
		where bettype between 1 and 19999 and winlostdate BETWEEN @min_winlostdate AND @max_winlostdate
		group by winlostdate,srecommend
		HAVING sum(swinlost) <> 0
	UNION ALL
	--INSERT INTO DB06.bodb_Report.dbo.statement
		select srecommend,winlostdate accdate,sum(scomm-acomm) totalamt,'COM' transtype, 'Commission' transdesc
		from dbo.bettrans14 bettrans with (nolock)
		where bettype between 1 and 19999 and winlostdate BETWEEN @min_winlostdate AND @max_winlostdate
		group by winlostdate,srecommend
		HAVING sum(scomm-acomm) <> 0

END
GO
