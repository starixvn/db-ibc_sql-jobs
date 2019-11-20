/*<info serverAlias="DBTXN-bodb02" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_ReadyToGo_TicketVoiding_RoutineTasks]
(
	 @stepNo		TINYINT, 
	 @AffectedList	VARCHAR(MAX) = NULL,
	 @ExecuteType	TINYINT,
	 @errmsg		VARCHAR(1000) = '' OUTPUT 
)
AS
/*
	Created: 20190906@Lukas
	Task: routine task after void/recover tickets in bet14 - prepare the inputed values 
	DB: DBTXN.bodb02

	Revisions:
		- 20190906@Lukas: Initialize SP [RedmineID: #115377]
*/
BEGIN
	DECLARE @inputList TABLE (custid INT, winlostdate DATETIME, isDone BIT)
	-- parse @affectedList to get list of winlostdate or custid
	-- in case of group execution combine the affected list & remove duplicate value
	-- loop for each custid/winlostdate
	DECLARE @XmlData XML,
			@winlostdate DATETIME,
			@custID INT,
			@custIDs VARCHAR(MAX) = ''

	IF @AffectedList IS NOT NULL --- most of case run instantly tasks
	BEGIN 
		SET @XmlData  = @AffectedList

		INSERT INTO @inputList(custid,winlostdate,isDone)
		SELECT	t.c.value('@c', 'INT')			AS CustId,
				t.c.value('@w', 'SMALLDATETIME')	AS WinlostDate,
				0 AS isDone
		FROM @XmlData.nodes('root/r') AS t(c)
		OPTION (OPTIMIZE FOR (@XmlData = NULL))
	END
	ELSE 
	BEGIN
		WITH rs
		AS (
			SELECT *
				,cast(affectedList AS XML) AS xmldata
			FROM TicketVoiding_RoutineTasks WITH(NOLOCK)
			WHERE stepno = @stepNo AND status = 1 
			)
		INSERT INTO @inputList(custid,winlostdate,isDone)
		SELECT t.c.value('@c', 'INT') AS CustId
			,t.c.value('@w', 'SMALLDATETIME') AS WinlostDate
			, 0 AS isDone 
		FROM rs
		CROSS APPLY xmldata.nodes('root/r') AS t(c)
	END 

	IF @stepNo IN (1,2,3,4)  -- those kind of execution need both input @winlostdate & @custid
	BEGIN
		WHILE EXISTS (SELECT 1 FROM @inputList WHERE isDone = 0)
		BEGIN
			--- run by winlostdate & list of custid
			SELECT TOP(1) @winlostdate=winlostdate, 
						  @custIDs=STUFF( ( SELECT ',' + CAST(custid AS VARCHAR(20))
											FROM @inputList s 
											WHERE s.winlostdate = t.winlostdate
											FOR XML PATH ('')),1,1,'')
			FROM @inputList t 
			WHERE isDone = 0
			GROUP BY winlostdate 

			EXECUTE Task_Execute_TicketVoiding_RoutineTasks @stepNo = @stepNo, @winlostdate = @winlostdate, @custIDs = @custIDs, @errmsg = @errmsg OUTPUT

			UPDATE @inputList
			SET isDone = 1
			WHERE winlostdate = @winlostdate 

		END
	END
	IF @stepNo IN (5,6,7,8)   -- those kind of execution only need input @winlostdate 
	BEGIN
		WHILE EXISTS (SELECT 1 FROM @inputList WHERE isDone = 0)
		BEGIN
			SELECT TOP 1 @winlostdate = winlostdate
			FROM @inputList
			WHERE isDone = 0
			GROUP BY winlostdate 
			ORDER BY winlostdate

			EXECUTE Task_Execute_TicketVoiding_RoutineTasks @stepNo = @stepNo, @winlostdate = @winlostdate, @errmsg = @errmsg OUTPUT

			UPDATE @inputList
			SET isDone = 1
			WHERE winlostdate = @winlostdate
		END
	END
END
GO