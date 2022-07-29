/*<info serverAlias="DBEXT-bodb02,DBACC-bodb02,DBBOF-bodb02,DBBAL-bodb02" executers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Task_BATransaction_Ins]
AS

/*
	Created by:[Henry]
	Date: 2011-06-20
	Task: Insert BA Bets
	DB: DBEXT.bodb02, DBACC.bodb02, DBBOF.bodb02, DBBAL-bodb02

	Revisions:
		- 20110824@Henry: Change the range of the bettype (not between 31 and 120)
		- 20110909@Viet: revise SP
		- 20111208@Jim: Change bettype condition
		- 20100315@kIWI: Remove @TempBACustID table
		- 20121030@Viet: change the way to get data, reduce load for server
		- 20150127@Don: Expand bet type ranges for Sportbook when processing BA
		- 20150903@Patrick: #42910: Exclude ticket 901 for BetTrade
		- 20160301@Don: Add hard-code of [transid < 100000000000]
		- 20160416@Francis: Revert hard-code of [transid < 100000000000]
		- 20170410@Paul: Implement Cash Out [RedmineID :#71727]
		- 20180806@Patrick: Sync BA ticket to DB042 [Redmine #98631]
		- 20181002@Sophia: Sync BA ticket to DB053 (UAT) [Redmine #99855]
		- 20181025@Sophia: Revert SPs not to sync BA ticket to DB053, due to DB053 has the job Gen BA ticket by itself (PRO) [Redmine #99855]
		- 20181107@Patrick: DB052 Indexes Revolution [Redmine: #103572]
		- 20181120@Sophia: Change 'DB052' To 'DB053' for step switch to DB053 [Redmine: #103653]
		- 20180412@Percy: Expand Sportsbook bettype range - ESports [RedmineID: #100721]
		- 20190226@Percy: Move update max transid after insert data [RedmineID: #109415]
		- 20190311@Parsons: Implement BetBuilder [Redmine: #108995]
		- 20190625@Percy: Change 'DB053' To 'DB052' for step switch to DB052 [Redmine: #103658]
		- 20191010@Percy: Remove table LicenseeBATransaction [RedmineID: #103656]
		- 20201001@Louis: Licensee Spread Setting [RedmineID: #142532]
		- 20210302@Hogan: Hard code Licensee Spread Setting [RedmineID: #148100]
		- 20210315@Hogan: Integrate Cricket AIO [RedmineID: #150386]
		- 20210816@Sophia: add DBBAL [Redmine: #154300]
		- 20220211@Kos: Integrate Cricket phase 2 [RedmineID: #168034]
		- 20220714@Hogan: Integrate Volleyball AIO [RedmineID: #175143]

*/

BEGIN
	SET NOCOUNT ON

	DECLARE @temptrans AS TABLE (
		TransId		BIGINT,
		TransDate	DATETIME,
		CustId		INT,
		Recommend	INT,
		SRecommend	INT)

	DECLARE
		@smallID		BIGINT,
		@maxtransID		BIGINT,
		@currentDate	DATETIME

	-- scan each transid twice to prevent missing by locking
	SELECT @smallID = CAST(ISNULL(vvalue,0) AS BIGINT)
	FROM bodb_licensee.dbo.LICSettings WITH (ROWLOCK)
	WHERE vname = 'BA_transid'

	SELECT @maxtransID = MAX(SequenceID)
	FROM dbo.bettrans WITH(NOLOCK)

	INSERT INTO @temptrans (TransId, TransDate, CustId, Recommend, SRecommend)
	SELECT transid, transdate, custid, recommend, srecommend
	FROM dbo.bettrans WITH(NOLOCK)
	WHERE SequenceID BETWEEN @smallID AND @maxtransID
		AND (bettype < 31
				OR (bettype BETWEEN 121 AND 999)
				OR (bettype BETWEEN 1301 AND 1399)
				OR (bettype BETWEEN 9001 AND 9399)
				OR (bettype BETWEEN 9400 AND 9998)
				OR (bettype BETWEEN 3900 and 3999)
				OR (bettype = 38) -- BetBuilder
			)
		AND statusID <> 121 --DONE
		AND tpositiontaking = 0
		AND (bettype < 901 OR bettype > 904)
		AND (bettype < 911 OR bettype > 914)
		AND bettype <> 999  --Exclude: Licensee Spread Setting
	

	IF @@ROWCOUNT <> 0
	BEGIN
		DELETE @temptrans
		WHERE CustId NOT IN (
				SELECT CustID
				FROM bodb_Licensee.dbo.LicenseeBAHistory WITH (NOLOCK)
				WHERE Status = 'Running'
					OR (Status = 'Done'
						AND DATEDIFF(MINUTE, OffDate, CURRENT_TIMESTAMP) <= 2)

				UNION ALL --Cash Out

				SELECT custid
				FROM dbo.TradeCust WITH(NOLOCK)
				WHERE VendorID = 14
			)

		DELETE t
		FROM @temptrans t
			INNER JOIN bodb_Licensee.dbo.LicenseeBATransaction_active ba WITH(NOLOCK) ON t.TransID = ba.TransID

		INSERT INTO bodb_licensee.dbo.LicenseeBATransaction_active (TransID, Transdate, custid, recommend, srecommend)
		SELECT TransId, TransDate, CustId, Recommend, SRecommend
		FROM @temptrans
	END

	UPDATE bodb_licensee.dbo.LICSettings WITH(ROWLOCK, UPDLOCK)
	SET
		vvalue = vvalue2,
		vvalue2 = CAST(@maxtransID AS VARCHAR(200))
	WHERE vname = 'BA_transid'
END
GO