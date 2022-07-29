/*<info serverAlias="DBSID-bodb02" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SiteDB_Task_DEP_SeparatedWallet_GenerateData]
	@WinlostDate SMALLDATETIME
AS

/*
	Created by: Evan 
	Original: Task_DEP_SeparatedWallet_GenerateData
	DB: DBSID.bodb02
	Task: Separated Wallet Products - Generate data into bettrans on SiteDB

	Revisions:
		- 20220724@Evan: Add SP for SiteDB  [Redmine: #175297]

*/

BEGIN
	SET NOCOUNT ON

	DECLARE @ErrrMessage		VARCHAR(100)
			,@CheckProductIds	VARCHAR(4000)
			,@ReadyProductIds	VARCHAR(4000)
			,@ReadyType			TINYINT = 0
			,@LimitTime			TIME = '03:00:00'
			,@CurrentTime		TIME

	DECLARE @Products			TABLE (ProductId INT)
	DECLARE @ImportedProducts	TABLE (ProductId INT)

	-- All Separated Wallet 3rd Products
	INSERT INTO @Products (ProductId)
	VALUES (10), (11), (31)

	INSERT INTO @ImportedProducts (ProductId)
	SELECT DISTINCT
		CASE
			WHEN bettype = 1800			THEN 10 -- AG Casino
			WHEN bettype IN (1700,1706) THEN 11 -- Gold Deluxe
			WHEN bettype = 8000			THEN 31 -- Exchange
			END AS ProductId
	FROM dbo.bettrans WITH (NOLOCK)
	WHERE bettype IN (1800,1700,1706,8000)
		AND winlostdate = @WinlostDate

	DELETE @Products WHERE ProductId IN (SELECT ProductId FROM @ImportedProducts)

	IF NOT EXISTS (SELECT 1 FROM @Products)
	BEGIN
		SELECT @ErrrMessage = '* Already generate data into bettrans *'
		RAISERROR(@ErrrMessage, 16, 1) -- job failed
		RETURN
	END

	-- Check products ready from DBLIC
	SET @CheckProductIds = NULL
	SELECT @CheckProductIds = COALESCE(@CheckProductIds + ',', '') + CONVERT(VARCHAR(10), ProductId) FROM @Products
	SELECT @CurrentTime = CONVERT(VARCHAR(8), GETDATE(), 114)

	SET @ReadyType = 0
	
	WHILE @ReadyType <> 2 AND ISNULL(@CheckProductIds, '') <> ''
	BEGIN
		-- Loop untill @LimitTime --> auto run, no need check
		IF @CurrentTime > @LimitTime
		BEGIN
			SELECT @ReadyProductIds = @CheckProductIds

			EXEC dbo.SiteDB_Task_Dep_DailySumData3rdProduct
				@WinlostDate		= @WinlostDate
				,@ProductIds		= @ReadyProductIds

			EXEC dbo.SiteDB_Task_Dep_AdjustData3rdProduct
				@WinlostDate		= @WinlostDate
				,@ProductIds		= @ReadyProductIds

			BREAK
		END

		EXEC DBLIC.bodb_Licensee.dbo.Task_DEP_SeparatedWallet_Data_Check
			@WinlostDate		= @WinlostDate
			,@CheckProductIds	= @CheckProductIds
			,@ReadyProductIds	= @ReadyProductIds OUTPUT
			,@ReadyType			= @ReadyType OUTPUT

		/*
			@ReadyType:
				0: data of all products is not ready
				1: data of some products is ready
				2: data of all products is ready
		*/

		IF @ReadyType = 0
		BEGIN
			SET @ErrrMessage = '* data of all products is not ready for winlostdate: ' + CONVERT(VARCHAR(10), @WinlostDate, 112) + ' *'
			RAISERROR(@ErrrMessage, 0, 0) WITH NOWAIT
		END
		ELSE IF @ReadyType IN (1, 2)
		BEGIN
			EXEC dbo.SiteDB_Task_Dep_DailySumData3rdProduct
				@WinlostDate		= @WinlostDate
				,@ProductIds		= @ReadyProductIds

			EXEC dbo.SiteDB_Task_Dep_AdjustData3rdProduct
				@WinlostDate		= @WinlostDate
				,@ProductIds		= @ReadyProductIds

			IF @ReadyType = 2
				BREAK

			DELETE @Products WHERE ProductId IN (SELECT value FROM STRING_SPLIT(@ReadyProductIds, ','))
			
			SET @CheckProductIds = NULL
			SELECT @CheckProductIds = COALESCE(@CheckProductIds + ',', '') + CONVERT(VARCHAR(10), ProductId) FROM @Products
		END

		WAITFOR DELAY '00:10:00' -- loop 10 mins
		SELECT @CurrentTime = CONVERT(VARCHAR(8), GETDATE(), 114)
	END
END
GO