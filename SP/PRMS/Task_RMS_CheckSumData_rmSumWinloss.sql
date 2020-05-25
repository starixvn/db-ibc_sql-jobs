/*<info serverAlias="DBRMS-bodb_RMS" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_RMS_CheckSumData_rmSumWinloss]
	@winlostdate	DATETIME,
	@ErrCode		INT = 0				OUTPUT,
	@ErrMsg			VARCHAR(1000) = ''	OUTPUT
AS

/*
	Created: 20200512@Percy
	DB: DBRMS-bodb_RMS
	Task: RMS - Check Sum data of rmSumWinloss

	Revisions:
		- 20200512@Percy: Initialize SP [RedmineID: #130275]
*/

BEGIN
	SET NOCOUNT ON

	IF NOT EXISTS (SELECT 1 FROM bodb02.dbo.bettrans14 WITH (NOLOCK) WHERE winlostdate = @winlostdate AND bettype IN (29, 38, 376))
		RETURN

	IF EXISTS (SELECT 1 FROM bodb02.dbo.bettrans WITH (NOLOCK) WHERE winlostdate = @winlostdate AND bettype IN (29, 38, 376))
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg= 'WARNING: Data is still in bettrans.'
		RETURN
	END

	BEGIN TRY
		-- Get sporttype
		BEGIN
			CREATE TABLE #sporttype (refno BIGINT, sporttype INT)
			CREATE CLUSTERED INDEX CIX_refno ON #sporttype (refno)

			-- bettransm
			INSERT INTO #sporttype (refno, sporttype)
			SELECT bm.refno, m.sporttype
			FROM bodb02.dbo.bettrans14 b WITH (NOLOCK)
				INNER JOIN bodb02.dbo.bettransm bm WITH (NOLOCK) ON b.refno = bm.refno
				INNER JOIN bodb02.dbo.match m WITH (NOLOCK) ON bm.matchid = m.matchid
			WHERE b.winlostdate = @winlostdate
				AND b.bettype = 29
				AND b.statusID IN (111, 112, 113)

			-- bettransm14
			INSERT INTO #sporttype (refno, sporttype)
			SELECT bm.refno, m.sporttype
			FROM bodb02.dbo.bettrans14 b WITH (NOLOCK)
				INNER JOIN bodb02.dbo.bettransm14 bm WITH (NOLOCK) ON b.refno = bm.refno
				INNER JOIN bodb02.dbo.match14 m WITH (NOLOCK) ON bm.matchid = m.matchid
			WHERE b.winlostdate = @winlostdate
				AND b.bettype = 29
				AND b.statusID IN (111, 112, 113)

			-- bettransm bk
			DECLARE @sql NVARCHAR(MAX)
			SELECT  @sql = 'SELECT refno, sporttype
							FROM OPENQUERY(DBARC, ''SELECT bm.refno, m.sporttype
													FROM bodb02.dbo.bettrans14 b WITH (NOLOCK)
														INNER JOIN bodb_Archive.dbo.bettransm bm WITH (NOLOCK) ON b.refno = bm.refno
														INNER JOIN bodb_Archive.dbo.match_bk m WITH (NOLOCK) ON bm.matchid = m.matchid
													WHERE b.winlostdate = ''''' + CONVERT(VARCHAR(10), @winlostdate, 120) + '''''
														AND b.bettype = 29
														AND b.statusID IN (111, 112, 113)'')'

			INSERT INTO #sporttype (refno, sporttype)
			EXEC (@sql)
		END

		-- Gen data
		BEGIN
			DELETE dbo.rmSumWinloss WITH (ROWLOCK, UPDLOCK) WHERE winlostdate = @winlostdate

			INSERT INTO dbo.rmSumWinloss
			(
				winlostdate,custid,sporttype,statusid,combo,username,currency,stake,winlost
				,company_stake,company_winlost,actualrate,odds,betcount,recommend,parlaytype
				,scomm,Extra_comm,Extra_stake,Extra_winlost
			)
			SELECT
				b.winlostdate
				,b.custid
				,CASE WHEN b.bettype = 29 THEN s.sporttype ELSE 1 END AS sporttype
				,b.statusid
				,CASE WHEN b.bettype = 29 AND b.betcheck IS NULL THEN LEN(b.betteam) ELSE b.hdp2 END AS combo
				,b.username
				,b.currency
				,SUM(b.stake) AS stake
				,SUM(b.winlost) AS winlost
				,SUM(b.stake * (1 - b.tpositiontaking)) AS company_stake
				,SUM(-(b.winlost - b.stake) * (1 - b.tpositiontaking)) AS company_winlost
				,b.actualrate
				,SUM(b.modds) AS odds
				,COUNT(1) AS betcount
				,b.recommend
				,CASE
					WHEN b.bettype = 29 AND betteam = N'1' THEN 2
					WHEN b.bettype = 29 AND betteam <> N'1' THEN 3
					WHEN b.bettype = 38 THEN 3
					WHEN b.bettype = 376 THEN 4
					ELSE 0 END AS ParlayType
				,SUM(b.scomm) AS scomm
				,SUM(b.scomm * CONVERT(DECIMAL(9,8), b.epositiontaking) / (1 - b.tpositiontaking)) AS Extra_comm
				,SUM(b.stake * CONVERT(DECIMAL(9,8), b.epositiontaking)) AS Extra_stake
				,SUM(-(b.winlost - b.stake) * CONVERT(DECIMAL(9,8), b.epositiontaking)) AS Extra_winlost
			FROM bodb02.dbo.bettrans14 b WITH (NOLOCK)
				OUTER APPLY (
					SELECT CASE
							WHEN COUNT(DISTINCT s.sporttype) = 1 THEN MIN(s.sporttype)
							WHEN MIN(s.sporttype) = 1 THEN -3
							ELSE -1 END AS sporttype
					FROM #sporttype s
					WHERE b.refno = s.refno
						AND b.bettype = 29
				) s
			WHERE b.winlostdate = @winlostdate
				AND b.bettype IN (29, 38, 376)
				AND b.statusID IN (111, 112, 113)
			GROUP BY
				b.winlostdate
				,b.custid
				,CASE WHEN b.bettype = 29 THEN s.sporttype ELSE 1 END
				,b.statusid
				,CASE WHEN b.bettype = 29 AND b.betcheck IS NULL THEN LEN(b.betteam) ELSE b.hdp2 END
				,b.username
				,b.currency
				,b.actualrate
				,b.recommend
				,CASE
					WHEN b.bettype = 29 AND betteam = N'1' THEN 2
					WHEN b.bettype = 29 AND betteam <> N'1' THEN 3
					WHEN b.bettype = 38 THEN 3
					WHEN b.bettype = 376 THEN 4
					ELSE 0 END
		END

		DROP TABLE #sporttype
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 102, @ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH
END
GO