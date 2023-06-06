/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[ExecRep_07]
	@custids varchar(4000),
	@custid int,
	@roleid int,
	@winlostdate smalldatetime,
	@transIds varchar(max) = ''
AS
/*
	Created: unknow
	Task : 	Delete Data after archive - Balance Up Process
	DB: DBTXN.bodb02
	Original:

	Revisions:
		- 20211214@Kathy: Separate Transfer Tickets[Redmine:#164197]		
		- 20220315@Kathy: Change to use STRING_SPLIT [Redmine:#166457]
		- 20230106@Patrick: Balance-Up support transfer 247 [RedmineID: #173554]
		
		
	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON
	CREATE TABLE #ticketList (rn int PRIMARY KEY IDENTITY(0,1), transid bigint)   
	DECLARE @tc int -- ticket count
	DECLARE @r int

	IF OBJECT_ID('Transfer', 'U') IS NULL
		RETURN

	IF @roleid = 44
	BEGIN

		;WITH
			CTE AS (SELECT transid, srecommend FROM dbo.Transfer WITH (NOLOCK) WHERE recommend = 0 AND winlostdate < @winlostdate)
			,s AS (SELECT value AS srecommend FROM STRING_SPLIT(@custids, ','))
		INSERT INTO #ticketList (transid)
		SELECT transid
		FROM CTE
			INNER JOIN s ON CTE.srecommend = s.srecommend
			
		SET @tc = @@ROWCOUNT
	END
	ELSE IF @roleid = 22
	BEGIN
	   
		;WITH a AS (SELECT value AS recommend FROM STRING_SPLIT(@custids, ','))
		INSERT INTO #ticketList (transid)
		SELECT transid
		FROM dbo.Transfer b WITH (NOLOCK)
			INNER JOIN a ON b.recommend = a.recommend
			WHERE 
				winlostdate < @winlostdate

		SET @tc = @@ROWCOUNT
	END
	ELSE IF @roleid = 11
	BEGIN
	   
		;WITH c AS (SELECT value AS custid FROM STRING_SPLIT(@custids, ','))
		INSERT INTO #ticketList (transid)
		SELECT transid
		FROM dbo.Transfer b WITH (NOLOCK)
			INNER JOIN c ON b.recommend = @custid AND b.custid = c.custid
			WHERE 
				winlostdate < @winlostdate

		SET @tc = @@ROWCOUNT
	END
	ELSE IF @roleid = 2
	BEGIN
	  
		INSERT INTO #ticketList (transid)
		SELECT transid
		FROM dbo.Transfer WITH (NOLOCK)
			WHERE recommend = @custid
			AND winlostdate < @winlostdate

		SET @tc = @@ROWCOUNT
	END
	ELSE IF @roleid = 222 -- special handle for HAIFA
	BEGIN
	 
		INSERT INTO #ticketList (transid)
		SELECT transid
		FROM dbo.Transfer WITH (NOLOCK)
			WHERE recommend = @custid AND RIGHT(custid, 1) = @custids
			AND winlostdate < @winlostdate

		SET @tc = @@ROWCOUNT
		SET @custids = CAST(@custid as varchar(50)) + ',' + @custids
	END
	ELSE IF @roleid = 111
	BEGIN
		DECLARE @xmlData XML
		SET @xmlData = CONVERT(XML, REPLACE('<root><r t="' + @transIds + '"/></root>', '^', '"/><r t="'))

		INSERT INTO #ticketList (transid)
		SELECT T.C.value('./@t', 'BIGINT') AS transid
		FROM @xmlData.nodes('//r') AS T(C)
		OPTION (OPTIMIZE FOR (@xmlData = NULL))

		SET @tc = @@ROWCOUNT
	END

 	
	Declare @rn int, @rx int, @__errcode int, @__errmsg varchar(200), @__tryCount int = 0
	SET @rn = 0
	SET @rx = 2000

	WHILE @rn < @tc
	BEGIN
		BEGIN TRY
		  
			DELETE t WITH (ROWLOCK)
			FROM #ticketList tl
				INNER LOOP JOIN dbo.Transfer t ON t.transid = tl.transid
			WHERE tl.rn BETWEEN @rn AND @rx
			OPTION(FORCE ORDER, MAXDOP 4)

			DELETE ti WITH(ROWLOCK)
			FROM #ticketList tl
				INNER LOOP JOIN dbo.TransferInfo ti ON ti.TransId = tl.transid
			WHERE tl.rn BETWEEN @rn AND @rx
			OPTION(FORCE ORDER, MAXDOP 4)

			SET @rn = @rn + 2000
			SET @rx = @rx + 2000
		END TRY
		BEGIN CATCH
			SELECT @__errcode = ERROR_NUMBER(), @__errmsg = ERROR_MESSAGE()
			IF @__errcode = 1205 -- deadlock
			BEGIN
				SET @__tryCount = @__tryCount + 1
				WAITFOR DELAY '00:00:00.100' -- BU - remove old data got deadlock then wait for 100 ms

				IF @__tryCount < 3
					CONTINUE
			END

			RAISERROR (@__errmsg, 16, 1)

		END CATCH
	END
 
END

