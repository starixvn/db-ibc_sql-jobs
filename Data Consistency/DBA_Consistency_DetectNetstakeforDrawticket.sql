/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_Consistency_DetectNetstakeforDrawticket]
	 @ProductId		INT			 = NULL	
	,@CheckMode     TINYINT		 = NULL	
	,@ErrCode		INT			 = 0	OUTPUT
	,@ErrMsg		VARCHAR(MAX) = ''	OUTPUT 
	,@SampleData	VARCHAR(MAX) = ''	OUTPUT
AS
/*
	Created: 20220614@July
	Task: Data consistency
	DB: DBCONSISTENCY-bodb_Consistency

	Revisions: 
		- 20220614@July: Detect Netstake <> 0 for Draw ticket [Redmine:#173956]

	Param's Expanation:
	@ProductId: 
		+ bettransLC: Allbet(211), AE Sexy(243), IBCBet Live Casino(242), WM(233), BG (Big Gaming)(239)
		+ bettrans: Virtual Sports 3 (Leap Gaming) (231)
	@CheckMode:
		+ 1: Detect draw tickets have bettransLC.netstake <>0
		+ 2: Detect draw tickets for bettype game DragonTiger, Roulette, Sicbo of LC products
		+ 3: Detect draw tickets have bettrans.oddsspread <>0
*/
BEGIN
	DECLARE @transId VARCHAR(MAX)
		   ,@Today	 SMALLDATETIME

	SET @transId = ''
	SET @Today = CAST(GETDATE() AS DATE)

	IF @CheckMode = 1 AND @ProductId IN (211,243,242,233,239)  
	BEGIN
		SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM	bodb02.dbo.bettransLC b WITH (NOLOCK)
		WHERE	ISNULL(b.NetStake,0) <> 0 
				AND b.statusID = 111 --Draw 
				AND b.winlostdate = @Today
				AND b.productID = @ProductId
				
		IF @transId <> ''
		BEGIN
			SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
					,@ErrCode = 100
					,@ErrMsg = 'Detect draw tickets have bettransLC.netstake <> 0 on product ' + CAST(@ProductId AS VARCHAR)
					,@SampleData = 'bettransLC.TransId in (' + @transId + ')'
		END
		RETURN
	END

	IF @CheckMode = 2
	BEGIN
		SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM	bodb02.dbo.bettransLC b WITH (NOLOCK)
		WHERE	b.statusID = 111 --Draw 
				AND b.winlostdate = @Today
				AND (
					b.gameID IN (2405, 3102, 3202, 3402, 3504) --DragonTiger
				 OR b.gameID IN (3103, 2404, 3203, 3404, 3503) --Sicbo
				 OR b.gameID IN (3104, 2403, 3204, 3403, 3502) --Roulette
				)
		IF @transId <> ''
		BEGIN
			SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
					,@ErrCode = 100
					,@ErrMsg = 'Detect draw tickets for bettype game DragonTiger, Roulette, Sicbo of LC products' 
					,@SampleData = 'bettransLC.TransId in (' + @transId + ')'
		END
		RETURN
	END

	IF @CheckMode = 3 AND @ProductId IN (231)  
	BEGIN
		SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM	bodb02.dbo.bettrans b WITH (NOLOCK)
		WHERE	ISNULL(b.oddsspread,0) <> 0 
				AND b.statusID = 111 --Draw 
				AND b.winlostdate = @Today
				AND b.matchid = @ProductId

		IF @transId <> ''
		BEGIN
			SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
					,@ErrCode = 100
					,@ErrMsg = 'Detect draw tickets have bettrans.oddsspread <> 0 on product ' + CAST(@ProductId AS VARCHAR)
					,@SampleData = 'bettrans.TransId in (' + @transId + ')'
		END
		RETURN
	END
END
GO


