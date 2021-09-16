/*<info serverAlias="DBBOF-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [sb].[Task_Update_SettleTickets] @TransIDs VARCHAR(MAX), @ErrorCode INT = 0 OUTPUT
AS
/*
	Create By: 20180625@Patrick
	Task: Apply Service Broker for Bet Running
	DB: DBBOF/bodb02
	
	- Revisions:
		-20191127@Patrick: Setup sync status ticket on DB052 -> DB054 - [Redmine: #124482]
		-20210816@Helen: Apply Uncalculate Flow on DB054 for Both Single & Parlay Tickets [Redmine: #157381]
		
	Para's explaination
*/
BEGIN
	--SET DEADLOCK_PRIORITY LOW
	SET NOCOUNT ON
	SET @ErrorCode = 0

	--DECLARE @xml XML = N'<root><r>' + REPLACE(@TransIDs, ',', '</r><r>') + '</r></root>'	

	DECLARE @xml XML = CAST(@TransIDs AS XML)
	DECLARE @DelayXML XML

	DECLARE @tc1 INT = 0, @tc2 INT, @DelayTransIDs NVARCHAR(MAX)

	DECLARE @__TransIds TABLE (transid BIGINT PRIMARY KEY,statusID TINYINT, winlostdate SMALLDATETIME)
	INSERT @__TransIds(transid,statusID,winlostdate)
	SELECT	T.C.value('./@t', 'bigint')
		,T.C.value('./@s', 'tinyint')
		,T.C.value('./@w', 'smalldatetime')
	FROM	@xml.nodes('/root/r') AS T(C)
	OPTION (OPTIMIZE FOR (@xml = NULL ))
	
	SET @tc2 = @@ROWCOUNT

	--==capture transids which not insert to bettrans due to replication delay
	SET @DelayTransIDs = (SELECT transid AS '@t',statusID AS '@s', winlostdate AS '@w'
							FROM @__TransIds t
							WHERE NOT EXISTS (SELECT TOP 1 1 FROM dbo.bettrans b WITH(NOLOCK) WHERE b.transid = t.transid)
							FOR XML PATH('r'), ROOT('root')
							)
	
	IF @DelayTransIDs <> ''
	BEGIN
		INSERT INTO ServiceBrokerDB.sb.SettedTicketLogs (Id, message_type, message_body, duration, message_error, try_count)
		VALUES (NEWID(), 'MessageType_Settled_Ticket', CONVERT(NVARCHAR(MAX), @DelayTransIDs), NULL, 'Missing data2', 0)
	END
	
	DECLARE @__TransIds2 TABLE (transid BIGINT PRIMARY KEY,statusID TINYINT, winlostdate SMALLDATETIME)
	
	INSERT @__TransIds2(transid,statusID, winlostdate)
	SELECT t.transid, t.statusID, t.winlostdate
	FROM dbo.bettrans b WITH(NOLOCK) 
		INNER JOIN @__TransIds t ON b.transid = t.transid
	WHERE 1 = CASE 
					WHEN t.statusID IS NULL AND b.statusID < 2 THEN 1 -- cal single or parlay -> update settle status
					WHEN t.statusID = 0 AND b.matchid = 29 THEN 1 -- undo parlay
					ELSE 0
				END	
	
		AND b.bettype NOT IN (SELECT f.bettype from [dbo].[f_age_settled_ticket_exclued_bettype]() f)

	SET @tc1 = @@ROWCOUNT
	
	UPDATE b
		SET ruben = CASE WHEN t.statusid IS NULL THEN 1 ELSE 0 END -- cal single or parlay -> update settle status
			, statusID = CASE WHEN t.statusid IS NULL THEN 88 ELSE 0 END -- -- cal single or parlay -> update settle status: no_more_running ticket
			, winlostdate = CASE WHEN b.matchid = 29 AND b.winlostdate <> t.winlostdate THEN t.winlostdate ELSE b.winlostdate END
	FROM dbo.bettrans b WITH(ROWLOCK, UPDLOCK)
		INNER JOIN @__TransIds2 t ON b.transid = t.transid

	IF @@ERROR > 0
		SET @ErrorCode = 113
	
	--SET DEADLOCK_PRIORITY NORMAL
END
