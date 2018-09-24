/*<info serverAlias="DB042-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb02]
GO
CREATE PROCEDURE [sb].[Task_Update_SettleTickets] @TransIDs VARCHAR(MAX), @ErrorCode INT = 0 OUTPUT
AS
/*
	Create By: 20180625@Patrick
	Task: Apply Service Broker for Bet Running
	DB: DB042/bodb02
	
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

	DECLARE @__TransIds TABLE (transid BIGINT PRIMARY KEY)
	INSERT @__TransIds(transid)
	SELECT r.value('.','bigint')
	FROM @xml.nodes('//root/r') AS RECORDS(r)
	OPTION (OPTIMIZE FOR (@xml = NULL ))
	SET @tc2 = @@ROWCOUNT

	--==capture transids which not insert to bettrans due to replication delay
	SELECT @DelayTransIDs = COALESCE(@DelayTransIDs + ',' + CAST(TransId AS VARCHAR(50)), CAST(TransId AS VARCHAR(50)))
	FROM @__TransIds t
	WHERE NOT EXISTS (SELECT TOP 1 1 FROM dbo.bettrans b WITH(NOLOCK) WHERE b.transid = t.transid)
	IF @@ROWCOUNT > 0
	BEGIN
		SET @DelayXML = N'<root><r>' + REPLACE(@DelayTransIDs, ',', '</r><r>') + '</r></root>'
		INSERT INTO ServiceBrokerDB.sb.SettedTicketLogs (Id, message_type, message_body, duration, message_error, try_count)
		VALUES (NEWID(), 'MessageType_Settled_Ticket', CONVERT(NVARCHAR(MAX), @DelayXML), NULL, 'Missing data2', 0)
	END
	
	DECLARE @__TransIds2 TABLE (transid BIGINT PRIMARY KEY)
	INSERT @__TransIds2(transid)
	SELECT TransId 
	FROM dbo.bettrans WITH(NOLOCK) 
	WHERE transid IN (
		SELECT t.transid
		FROM @__TransIds t
	) AND statusID < 2 AND bettype NOT IN (SELECT f.bettype from [dbo].[f_age_settled_ticket_exclued_bettype]() f)

	SET @tc1 = @@ROWCOUNT
	
	UPDATE dbo.bettrans WITH(ROWLOCK, UPDLOCK)
	SET ruben = 1, statusID = 88 -- no_more_running ticket
	WHERE transid IN (
		SELECT transid
		FROM @__TransIds2
	) 

	IF @@ERROR > 0
		SET @ErrorCode = 113
	
	--SET DEADLOCK_PRIORITY NORMAL
END

GO


