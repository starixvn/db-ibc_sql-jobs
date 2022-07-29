/*<info serverAlias="DBSID-bodb02" executers="" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE [dbo].[SiteDB_Task_BATransaction_Ins]
AS

/*
	Created by: Evan 
	Original: Task_BATransaction_Ins
	Task:  Insert BA Bets for SiteDB
	DB: DBSID-bodb02

	Revisions:
		- 20220724@Evan: Add SP for SiteDB  [Redmine: #175297]

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
	FROM dbo.LICSettings WITH (ROWLOCK)
	WHERE vname = 'BA_transid'

	SELECT @maxtransID = MAX(TransId)
	FROM dbo.bettrans WITH(NOLOCK)

	INSERT INTO @temptrans (TransId, TransDate, CustId, Recommend, SRecommend)
	SELECT transid, transdate, custid, recommend, srecommend
	FROM dbo.bettrans WITH(NOLOCK)
	WHERE TransId BETWEEN @smallID AND @maxtransID
		AND (bettype < 31
				OR (bettype BETWEEN 121 AND 999)
				OR (bettype BETWEEN 1301 AND 1399)
				OR (bettype BETWEEN 9001 AND 9399)
				OR (bettype BETWEEN 9400 AND 9998)
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
				FROM  DBCUST.bodb_Licensee.dbo.LicenseeBAHistory WITH (NOLOCK)
				WHERE Status = 'Running' 
					OR (Status = 'Done'
						AND DATEDIFF(MINUTE, OffDate, CURRENT_TIMESTAMP) <= 2)

				UNION ALL --Cash Out

				SELECT custid
				FROM DBCUST.CustDB.dbo.TradeCust WITH(NOLOCK)
				WHERE VendorID = 14
			)

		DELETE t
		FROM @temptrans t
			INNER JOIN dbo.LicenseeBATransaction_active ba WITH(NOLOCK) ON t.TransID = ba.TransID

		INSERT INTO dbo.LicenseeBATransaction_active (TransID, Transdate, custid, recommend, srecommend)
		SELECT TransId, TransDate, CustId, Recommend, SRecommend
		FROM @temptrans
	END

	UPDATE dbo.LICSettings WITH(ROWLOCK, UPDLOCK)
	SET
		vvalue = vvalue2,
		vvalue2 = CAST(@maxtransID AS VARCHAR(200))
	WHERE vname = 'BA_transid'
END
GO
