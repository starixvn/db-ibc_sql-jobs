ALTER PROCEDURE [dbo].[Task_DailysettledTicket_Verify] @mode TINYINT = 1
	, @ErrMessage VARCHAR(512) = '' OUTPUT
AS
/*  
 Created by:20141015@Lukas  
 Task: to verify settled tickets   
 DB: DBTP/BODB02  
 Revision:
	- 20150619@Harris: separate single and parlay tickets
				- Single: from yesterday and before
				- Parlay: from the day before yesterday and earlier
	- 20160624@Patrick: Move SP to DBTP & Rearrange code [Redmine: #59643]
	- 20170712@Harper: Implement new Product Betradar VS [Redmine: #78241]
 */
BEGIN
	SET NOCOUNT ON

	DECLARE @winlostdate DATETIME, @rowcount INT

	SELECT @winlostdate = DATEADD(DAY, - 1, CONVERT(VARCHAR(20), GETDATE(), 110)), @ErrMessage = ''

	DECLARE @transid BIGINT

	--set @winlostdate = '2015-03-28'  
	-- ====================  
	-- DATA VERIFICATION  
	-- ====================  
	IF EXISTS (
			SELECT transid
			FROM bettrans WITH (NOLOCK)
			WHERE --[status] = 'running'   
				statusID = 0
				AND custid <> 0
				AND bettype <= 19000
				AND bettype NOT IN (9, 29, 10, 2799)
				AND winlostdate <= @winlostdate
				AND currency <> 20
			) -- check single tickets from yesterday and before
		SELECT DISTINCT matchid
		FROM bettrans(NOLOCK)
		WHERE winlostdate <= @winlostdate
			--AND [status] = 'running'  
			AND statusID = 0
			AND bettype <= 19000
			AND bettype NOT IN (9, 10, 29, 2799)

	SELECT @rowcount = @@ROWCOUNT

	IF EXISTS (
			SELECT transid
			FROM bettrans WITH (NOLOCK)
			WHERE --[status] = 'running'   
				statusID = 0
				AND custid <> 0
				AND bettype <= 19000
				AND bettype IN (9, 29, 2799)
				AND winlostdate < @winlostdate
				AND currency <> 20
			) -- Check parlay tickets of the day before yesterday and earlier
		SELECT DISTINCT 'EXEC matchname ' + CAST(bm.matchid AS VARCHAR(10)) matchid, m.eventdate, bm.matchid, ',' [Comma]
		FROM dbo.bettrans b(NOLOCK)
			INNER JOIN dbo.bettransm bm(NOLOCK)
			ON b.refno = bm.refno
			INNER JOIN dbo.match m(NOLOCK)
			ON bm.matchid = m.matchid
		WHERE b.winlostdate < @winlostdate
			AND m.eventdate < @winlostdate
			--AND b.[status] = 'running' AND bm.[status] = 'running'  
			AND b.statusID = 0
			AND bm.statusID = 0
			AND b.bettype IN (9, 29, 2799)
			--AND b.matchid = 0  
			AND b.matchID IN (9, 29, 2799)
			AND b.currency <> 20
		ORDER BY m.eventdate

	IF @@ROWCOUNT > 0
		OR @rowcount > 0
	BEGIN
		PRINT '--'
		PRINT '--SELECT * FROM bettrans (nolock) WHERE status = ''running'' AND matchid IN (9,29,2799) AND bettype IN (9,29,2799) AND winlostdate <= ''' + CONVERT(VARCHAR(10), @winlostdate, 120) + ''''
		PRINT '--UPDATE dbo.bettrans SET winlostdate = ''' + CONVERT(VARCHAR(10), DATEADD(day, 1, @winlostdate), 120) + ''' WHERE transid IN ( xxxxx )'
		PRINT '--'

		SET @ErrMessage = 'FAILED: Have running tickets'

		--RAISERROR ('FAILED: Have running tickets', 16, 1)

		RETURN
	END

	-- ====================  
	IF EXISTS (
			SELECT transid
			FROM bettrans WITH (NOLOCK)
			WHERE srecommend <= 100
				AND (
					scomm <> acomm
					OR swinlost <> 0
					)
				AND bettype <= 19000
				AND winlostdate = @winlostdate
			)
	BEGIN
		SET @ErrMessage = 'FAILED: Incorrect Company SuperAgent setting'
		--RAISERROR ('FAILED: Incorrect Company SuperAgent setting', 16, 1)

		RETURN
	END

	-- ====================  
	IF EXISTS (
			SELECT transid
			FROM bettrans WITH (NOLOCK)
			WHERE (
					scomm IS NULL
					OR acomm IS NULL
					OR comm IS NULL
					OR playercomm IS NULL
					OR swinlost IS NULL
					OR mwinlost IS NULL
					OR awinlost IS NULL
					OR winlost IS NULL
					)
				AND bettype <= 19000
				AND winlostdate = @winlostdate
			)
	BEGIN
		SET @ErrMessage = 'FAILED: Null Commission/WinLost'
		--RAISERROR ('FAILED: Null Commission/WinLost', 16, 1)

		RETURN
	END

	-- ====================  
	IF EXISTS (
			SELECT currency
			FROM bettrans(NOLOCK)
			WHERE bettype <= 19000
				AND winlostdate = @winlostdate
			GROUP BY currency
			HAVING COUNT(DISTINCT actualrate) > 1
			)
	BEGIN
		SET @ErrMessage = 'FAILED: Multiple Exchange Rate'
		--RAISERROR ('FAILED: Multiple Exchange Rate', 16, 1)

		RETURN
	END
			-- ====================  
END
