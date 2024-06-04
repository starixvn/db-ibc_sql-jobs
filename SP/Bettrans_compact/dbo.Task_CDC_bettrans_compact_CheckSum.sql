/*<info serverAlias="DBAGE-bodb_AGE" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_CDC_bettrans_compact_checkSum]
AS
/*
	Created by: 20231201@Bobby
	Task: 153357 - Alpha - CDC bettrans_compact - check SUMDATA
	DB: DBAGE.bodb_AGE
	Revisions:
		- 20231201@Bobby:  Implement bettrans_compact Redmine: [#153357]
		- 20240306@Lewis: Add Virtual Ice Hockey [RedmineID: #201129]
		- 20240321@Bobby:  checkSum remove extraWinloss vs extraComm Redmine: [#200041]
		- 20240522@Bobby: Enhance checkSum process [RedmineID: #205378]
		- 20240515@Lewis: Add SABA Kabaddi [RedmineID: #203763]
		- 20240602@Bobby: Enhance check & correct process [RedmineID: #205973]
*/
BEGIN

	SET NOCOUNT ON;

	DECLARE @winlostdate SMALLDATETIME, @checkDate SMALLDATETIME, @toDay SMALLDATETIME;
	
	DROP TABLE IF EXISTS #checkSumData;
	CREATE TABLE #checkSumData(
		[custid] [int] NOT NULL,
		[winlostdate] [smalldatetime] NOT NULL,
		[productId] [tinyint] NOT NULL,
		[sporttype] [int] NOT NULL,
		[bettype] [smallint] NOT NULL,
		[leagueGroupID] [int] NOT NULL,
		[ticketType] [int] NOT NULL,
		----------------------------
		[betcount] [int] NULL,
		[turnover] [money] NULL,
		[netTurnover] [money] NULL,
		[TurnoverNoDraw] [money] NULL,
		[winlost] [money] NULL,
		[awinlost] [money] NULL,
		[mwinlost] [money] NULL,
		[swinlost] [money] NULL,
		[playercomm] [money] NULL,
		[comm] [money] NULL,
		[acomm] [money] NULL,
		[scomm] [money] NULL,
		[grosscomm] [money] NULL,
		[extraComm] [decimal](38, 6) NULL,
		[extraWinloss] [decimal](38, 6) NULL,
	);

	DECLARE @moveBetsDay SMALLDATETIME
	DECLARE @tblMoveBetBalanceUp AS TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)

	INSERT INTO @tblMoveBetBalanceUp(BalanceUpDay,MoveBetsDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay
	
	SELECT @moveBetsDay = MoveBetsDay FROM @tblMoveBetBalanceUp

	SELECT @checkDate	= DATEADD(DAY, 1, @moveBetsDay)
		,@toDay			= CAST(GETDATE() AS DATE);

	SELECT @winlostdate = ISNULL(@checkDate, CAST(GETDATE() AS DATE));

	WHILE (@winlostdate <= @toDay)
	BEGIN
		TRUNCATE TABLE #checkSumData;

		--TODO: gen all data
		INSERT INTO #checkSumData(
			custid,winlostdate,productid,sporttype,bettype,leagueGroupID,ticketType
			,betcount,winlost,turnover,netTurnover,awinlost,mwinlost,swinlost,playercomm,comm,acomm,scomm,TurnoverNoDraw,grosscomm,ExtraComm,ExtraWinloss)
		EXEC dbo.[Task_Gen_Compact_bettrans] @winlostdate= @winlostdate

		--TODO: checkSum 
		;WITH bt_checksum AS (
			SELECT cal.custid, cal.winlostdate
				, (SELECT cal.custid, cal.winlostdate, cal.productId, cal.sporttype, cal.bettype, cal.leagueGroupID, cal.ticketType FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS KeyValue_BT
				, CHECKSUM(CONCAT_WS('|', cal.productid, cal.sporttype, cal.bettype, cal.leagueGroupID, cal.ticketType)) AS checkSumKey
				, (CHECKSUM(CONCAT_WS('|',betcount,	winlost, turnover,netTurnover
					,awinlost, mwinlost,swinlost,playercomm,comm,acomm,scomm,TurnoverNoDraw,grosscomm))) AS checkSumData

			FROM #checkSumData AS cal 
		), compact_checkSum AS (
			SELECT b.custid, b.winlostdate
				, (SELECT b.custid, b.winlostdate,b.productId, b.sporttype, b.bettype, b.leagueGroupID, b.ticketType FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS KeyValue_CP
				, CHECKSUM(CONCAT_WS('|', b.productId, b.sporttype, bettype, leagueGroupID, ticketType)) AS checkSumKey
				, (CHECKSUM(CONCAT_WS('|',betcount,	winlost, turnover,netTurnover
					, awinlost, mwinlost,swinlost,playercomm,comm,acomm,scomm,TurnoverNoDraw,grosscomm))) AS checkSumData 
		
			FROM dbo.bettrans_compact b WITH(NOLOCK)
			WHERE b.winlostdate = @winlostdate 
		)
		INSERT INTO dbo.bettrans_compact_checkSum(custid, winlostdate, checkSumKey, checkSumData, CreatedTime, notifyStatus, KeyValue, roundCheck)
		SELECT ISNULL(bt.custid, ck.custid) AS custid
			, ISNULL(bt.winlostdate, ck.winlostdate) AS winlostdate
			, ISNULL(bt.checkSumKey, ck.checkSumKey) AS checkSumKey
			, ISNULL(bt.checkSumData, ck.checkSumData) AS checkSumData
			, GETDATE() AS CreatedTime
			, 0 AS notifyStatus
			, IIF(bt.checkSumKey <> 0, bt.KeyValue_BT, ck.KeyValue_CP) AS KeyValue
			, 0 AS roundCheck
		FROM  bt_checksum bt
		FULL JOIN compact_checkSum ck ON ck.custid = bt.custid
			AND ck.winlostdate = bt.winlostdate
			AND ck.checkSumKey = bt.checkSumKey
		WHERE (bt.custid IS NULL OR ck.custid IS NULL OR ck.checkSumData <> bt.checkSumData)
		;

		PRINT CONCAT('-------> winlostdate: ', FORMAT(@winlostdate, 'yyyy-MM-dd'),', diff rowcount: ', @@ROWCOUNT);
		--LOOP @winlostdate
		SET @winlostdate =  DATEADD(DAY, 1, @winlostdate)
	END

END
GO