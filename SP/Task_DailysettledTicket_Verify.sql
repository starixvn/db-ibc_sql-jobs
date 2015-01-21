USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Task_DailysettledTicket_Verify]    Script Date: 01/21/2015 00:04:26 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

create PROCEDURE [dbo].[Task_DailysettledTicket_Verify]	
	@mode tinyint = 1
AS

/*
	Created by:20141015@Lukas
	Task: to verify settled tickets 
	DB: DB054/BODB02

 */
BEGIN

	SET NOCOUNT ON
	
	DECLARE @winlostdate DATETIME 
	SET @winlostdate = DATEADD(DAY,-1,CONVERT(VARCHAR(20),GETDATE(),110))
	DECLARE @transid bigint
	-- ====================
	-- DATA VERIFICATION
	-- ====================
	IF EXISTS (
		SELECT transid FROM bettrans with (nolock)
		WHERE	--[status] = 'running' 
				statusID = 0
				AND custid <> 0
				AND bettype <=19000 AND bettype <> 10 AND winlostdate <= @winlostdate
				AND currency <> 20
	)
	BEGIN
		SELECT DISTINCT matchid FROM bettrans (nolock)
		WHERE	winlostdate <= @winlostdate 
				--AND [status] = 'running'
				AND statusID = 0 
				AND bettype <=19000 and bettype NOT IN (9, 10, 29)

		SELECT DISTINCT 'EXEC matchname ' + CAST(bm.matchid as varchar(10)) matchid, m.eventdate, bm.matchid, ',' [Comma]
		FROM dbo.bettrans b (nolock)
			INNER JOIN dbo.bettransm bm (nolock) ON b.refno = bm.refno
			INNER JOIN dbo.match m (nolock) ON bm.matchid = m.matchid
		WHERE	b.winlostdate <= @winlostdate 
				--AND b.[status] = 'running' AND bm.[status] = 'running'
				AND b.statusID = 0 AND bm.statusID = 0 
				AND b.bettype in (9,29)
				--AND b.matchid = 0
				AND b.matchID in (9,29)
				AND b.currency <> 20
		ORDER BY m.eventdate

		IF @@ROWCOUNT > 0
		BEGIN
			PRINT '--'
			PRINT '--SELECT * FROM bettrans (nolock) WHERE status = ''running'' AND matchid IN (9,29) AND bettype IN (9,29) AND winlostdate <= ''' + CONVERT(varchar(10), @winlostdate, 120) + ''''
			PRINT '--UPDATE dbo.bettrans SET winlostdate = ''' + CONVERT(varchar(10), DATEADD(day,1,@winlostdate), 120) + ''' WHERE transid IN ( xxxxx )'
			PRINT '--'
		END

		RAISERROR ('FAILED: Have running tickets', 16, 1)
		RETURN
	END
	-- ====================
	IF EXISTS (
		SELECT transid FROM bettrans with (nolock)
		WHERE srecommend <= 100 AND (scomm <> acomm OR swinlost <> 0)
		AND bettype <=19000 AND winlostdate = @winlostdate
	)
	BEGIN
		RAISERROR ('FAILED: Incorrect Company SuperAgent setting', 16, 1)
		RETURN
	END
	-- ====================
	IF EXISTS (
		SELECT transid FROM bettrans with (nolock)
		WHERE (scomm IS NULL OR acomm IS NULL OR comm IS NULL OR playercomm IS NULL
		OR swinlost IS NULL OR mwinlost IS NULL OR awinlost IS NULL OR winlost IS NULL)
		AND bettype <=19000 AND winlostdate = @winlostdate
	)
	BEGIN
		RAISERROR ('FAILED: Null Commission/WinLost', 16, 1)
		RETURN
	END
	-- ====================
	IF EXISTS (
		SELECT currency
		FROM bettrans (nolock)
		WHERE bettype <=19000 AND winlostdate = @winlostdate
		GROUP BY currency
		HAVING COUNT(DISTINCT actualrate) > 1
	)
	BEGIN
		RAISERROR ('FAILED: Multiple Exchange Rate', 16, 1)
		RETURN
	END
	-- ====================
END


GO


