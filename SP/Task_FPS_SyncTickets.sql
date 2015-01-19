USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Task_FPS_SyncTickets]    Script Date: 01/19/2015 06:30:40 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_FPS_SyncTickets]	
AS
/*   
 Task : sycn bettrans from bodb to fps_bodb_trans
 DB: DBRMS/bodb02
 Revisions:   
  - 20140507@bobby: create SP   
  - 20140508@bobby: add username2
  - 20140514@bobby: add output params
  - 20140529@bobby: implement delete output
  - 20140606@Viet: arrange testing for bobby
  
*/
BEGIN
	SET NOCOUNT ON
	SET DEADLOCK_PRIORITY LOW

	DECLARE @tstamp_min BINARY (8)
		,@tstamp_max BINARY (8)
		,@row_per_batch INT = 5000
		
	DECLARE @site AS TABLE (sitename varchar(10))
	INSERT INTO @site(sitename)
	SELECT SubscriberName 
	FROM DBFPSTICKET.FPS_BODB_TRANS.dbo.Subscribers WITH (NOLOCK)
	WHERE IsActive = 1
		AND IsTest = 0
		AND SyncTicket = 1
	 
	IF @@ROWCOUNT = 0 RETURN
	
	SELECT TOP(1) @tstamp_min = CAST(CAST(ISNULL(VValue, 0) AS BIGINT) + 1 AS BINARY (8))
	FROM dbo.[SystemSettings] WITH (ROWLOCK)
	WHERE VName = '_FPS_LastTimestamp'

	SELECT @tstamp_max = isnull(max(tstamp), @tstamp_min)
	FROM [dbo].[bettrans] WITH (NOLOCK)

	CREATE TABLE #transSync (
		[transid] [bigint] NOT NULL
	);
	
	DECLARE @batchSync AS TABLE(transid bigint)	
	
	IF @tstamp_min = 0x0000000000000001 
	BEGIN
		DECLARE @syncDate SMALLDATETIME
		SET @syncDate = CONVERT (DATE, GETDATE() )
		INSERT INTO #transSync
           ([transid])
		SELECT [transid]
		FROM [dbo].[bettrans] WITH (NOLOCK)
		WHERE winlostdate = @syncDate --AND matchid > 0 
				AND bettype < 19999 
				AND srecommend IN (
						SELECT custid
						FROM Dep_CustSuper WITH (NOLOCK)
						WHERE site IN (SELECT sitename FROM @site)
						)
	END
	ELSE
	BEGIN
		INSERT INTO #transSync
           ([transid] )
		SELECT [transid]
		FROM [dbo].[bettrans] WITH (NOLOCK)
		WHERE tstamp BETWEEN @tstamp_min AND @tstamp_max --AND matchid > 0 
				AND bettype < 19999 
				AND srecommend IN (
						SELECT custid
						FROM Dep_CustSuper WITH (NOLOCK)
						WHERE site IN (SELECT sitename FROM @site)
						)
	END

	WHILE (EXISTS(SELECT TOP 1 1 FROM #transSync))
	BEGIN
		DELETE TOP (@row_per_batch)
		FROM #transSync
		OUTPUT deleted.transid 
		INTO @batchSync(transid)

		---------------------------------
		INSERT INTO DBFPSTICKET.FPS_BODB_TRANS.dbo.Bettrans_Staging ([transid]
			  ,[custid]
			  ,[transdate]
			  ,[oddsid]
			  ,[odds]
			  ,[stake]
			  ,[status]
			  ,[winlost]
			  ,[awinlost]
			  ,[mwinlost]
			  ,[playercomm]
			  ,[tpositiontaking]
			  ,[playerdiscount]
			  ,[liveindicator]
			  ,[betteam]
			  ,[winlostdate]
			  ,[actualrate]
			  ,[matchid]
			  ,[recommend]
			  ,[mrecommend]
			  ,[ruben]
			  ,[statuswinlost]
			  ,[bettype]
			  ,[actual_stake]
			  ,[currency]
			  ,[ip]
			  ,[transdesc]
			  ,[srecommend]
			  ,[swinlost]
			  ,[Username]
			  ,[Username2]
			  ,[CurrencyName]
			  ,[oddstype]
			)
		SELECT TOP(@row_per_batch) 
			t.[transid]
			,bt.[custid]
			,[transdate]
			,[oddsid]
			,[odds]
			,[stake]
			,[status]
			,[winlost]
			,[awinlost]
			,[mwinlost]
			,[playercomm]
			,[tpositiontaking]
			,[playerdiscount]
			,[liveindicator]
			,[betteam]
			,[winlostdate]
			,[actualrate]
			,[matchid]
			,bt.[recommend]
			,bt.[mrecommend]
			,[ruben]
			,[statuswinlost]
			,[bettype]
			,[actual_stake]
			,bt.[currency]
			,[ip]
			,[transdesc]
			,bt.[srecommend]
			,[swinlost]
			,bt.[Username]
			,c.[Username2]
			,[CurrencyName]
			,[oddstype]
		FROM @batchSync t
			INNER JOIN [dbo].[bettrans] bt WITH (NOLOCK)
			ON t.transid = bt.transid
			LEFT JOIN dbo.Customer c WITH(NOLOCK) 
			ON bt.custid = c.custid
		---------------------------------

		DELETE FROM @batchSync

		WAITFOR DELAY '00:00:01'
		
	END


	DROP TABLE #transSync

	UPDATE dbo.[SystemSettings] WITH (ROWLOCK, UPDLOCK)
	SET VValue = CAST(CAST(@tstamp_max AS BIGINT) AS VARCHAR(200))
	WHERE VName = '_FPS_LastTimestamp'

	SET NOCOUNT OFF
END

GO


