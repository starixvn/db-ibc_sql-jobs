/*<info serverAlias="DBAGE-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Get_Tickets_settled2]
	@batchSize int = 500
AS
/*
	20180621 @ Viet
	Task: Sync status of tickets
	DB: DBAGE.bodb02
	Revisions: 
		-20191127@Patrick: Setup sync status ticket on DB052 -> DB054 - [Redmine: #124482]
		-20210816@Helen: Apply Uncalculate Flow on DB054 for Both Single & Parlay Tickets [Redmine: #157381]
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @MaxRowId BIGINT, @LastRowId BIGINT
	
	SELECT @LastRowId = sValue
	FROM dbo.Tickets_settled_setting WITH(NOLOCK)
	WHERE sKey = 'TransitionId'
	
	SELECT @MaxRowId = MAX(RowId)
	FROM dbo.BetSettled_Transition WITH(NOLOCK)
	WHERE RowId > @LastRowId
	
	SET @LastRowId = ISNULL(@LastRowId, 0)
	SET @MaxRowId = ISNULL(@MaxRowId, @LastRowId)
		
	IF (@LastRowId = @MaxRowId) RETURN -- no row

	--wait for all trans can commit
	WAITFOR DELAY '00:00:00:280'

	CREATE TABLE #RowIds (rowID BIGINT, TransId BIGINT,statusid TINYINT,winlostdate SMALLDATETIME)
	
	CREATE TABLE #TransID_Latest_Status (RowID BIGINT , transid BIGINT PRIMARY KEY)
	
	INSERT INTO #RowIds(rowID,TransId,statusid,winlostdate)
	SELECT b.RowId,b.TransId,b.statusid,b.winlostdate
	FROM dbo.BetSettled_Transition b WITH(NOLOCK)
	WHERE RowId > @LastRowId AND RowId <= @MaxRowId
	
	INSERT INTO #TransID_Latest_Status (RowID, transid)
	SELECT MAX (rowID) AS RowID, TransId
	FROM #RowIds
	GROUP BY TransId
	HAVING COUNT(1) > 1
	
	IF @@ROWCOUNT > 0
	BEGIN
		DELETE r
		FROM #RowIds r 
			INNER JOIN #TransID_Latest_Status t ON t.transid = r.transid
		WHERE r.rowID < t.RowID
		
	END
			
	DECLARE @__TmpIds TABLE(TransId BIGINT,statusid TINYINT,winlostdate SMALLDATETIME)
	
	DECLARE @MessageData NVARCHAR(MAX), @ErrorCode BIT = 0, @Retry INT = 0, @xml XML
	WHILE 1 = 1
	BEGIN
		DELETE @__TmpIds
		SELECT @ErrorCode = 0, @Retry = 0, @xml = NULL

		DELETE TOP(@batchSize) #RowIds
		OUTPUT DELETED.TransId,DELETED.statusid,DELETED.winlostdate INTO @__TmpIds (TransId,statusid,winlostdate)

		IF @@ROWCOUNT = 0
			BREAK
		
		SET @xml = (  SELECT transid AS '@t',statusID AS '@s', winlostdate AS '@w'
				  FROM @__TmpIds 
				  FOR XML PATH('r'), ROOT('root')
				)
		Retry:
		
		EXEC sb.Settled_Ticket_SendMessage @xml = @xml, @ContractName = 'Contract_Settled_Ticket', @SB_error = @ErrorCode OUTPUT
		
		IF @ErrorCode > 0
		BEGIN

			SET @Retry = @Retry + 1
			IF @Retry > 10
				BREAK

			WAITFOR DELAY '00:00:00:280'
			GOTO Retry
			
		END
		--wait for all trans can commit
		WAITFOR DELAY '00:00:00:010'
	END

	IF @ErrorCode = 0
	BEGIN
		UPDATE dbo.Tickets_settled_setting WITH(ROWLOCK, UPDLOCK) 
		SET sValue = @MaxRowId
		WHERE sKey = 'TransitionId'
	END
	
	DROP TABLE #RowIds
	DROP TABLE #TransID_Latest_Status
	
END
GO
