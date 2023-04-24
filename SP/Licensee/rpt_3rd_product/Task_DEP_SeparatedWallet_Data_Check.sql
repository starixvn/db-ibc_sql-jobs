/*<info serverAlias="DBLIC-bodb_licensee" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_DEP_SeparatedWallet_Data_Check]
	@WinlostDate		SMALLDATETIME
	,@CheckProductIds	VARCHAR(4000) = ''
	,@ReadyProductIds	VARCHAR(4000) = '' OUTPUT
	,@ReadyType			TINYINT = 0 OUTPUT
AS

/*
	Created: 20170125@Patrick
	Task: Separated Wallet Products - Check data is ready or not on @WinlostDate
	DB: DBLIC-bodb_licensee
	
	Revisions:
		-20170412@Patrick: Fix bug for hotfix #74966
		-20170104@Sophia: Integrate Exchange Products [Redmine: #86640]
		-20180130@Sophia: remove the block code of Exchange for UAT Testing, will add later when releasing Exchange [redmine: #90213]
		-20180302@Sophia: Add the code check for Exchange because of release product [Redmine: #90214]
		-20200407@Percy: Revise SP to check separately data of @ProductIds [RedmineID: #131885]
 		-20230303@Evan: Remove inactive products GD [Redmine: 181424] 

	Param's Explanation:
		- @WinlostDate: winlostdate need to check
		- @CheckProductIds: list of ProductId need to check
		- @ReadyProductIds: list of ProductId which is ready
		- @ReadyType:
			0: data of all products is not ready
			1: data of some products is ready
			2: data of all products is ready
   
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @ErrrMessage VARCHAR(100)

	DECLARE @Products			TABLE (ProductId INT)
	DECLARE @NotReadyProducts	TABLE (ProductId INT)
	DECLARE @ReadyProducts		TABLE (ProductId INT)

	-- All Separated Wallet 3rd Products
	INSERT INTO @Products (ProductId)
	SELECT val FROM dbo.strSplit(@CheckProductIds, ',')

	IF NOT EXISTS (SELECT 1 FROM @Products)
	BEGIN
		SELECT @ErrrMessage = '* not have any products to check *'
		RAISERROR(@ErrrMessage, 16, 1) -- job failed
		RETURN
	END

	-- Check products ready from DBLIC
	IF EXISTS (SELECT 1 FROM @Products WHERE ProductId = 10)
	BEGIN
		-- Products are not ready
		INSERT INTO @NotReadyProducts (ProductId)
		SELECT ProductId
		FROM bodb_PlaytechCS.dbo.Product3rd_ImportQueue WITH (NOLOCK)
		WHERE ProductId = 10
			AND (
				Winlostdate IS NULL
				OR (Winlostdate = @WinlostDate AND FinishedTime IS NULL)
			)
		GROUP BY ProductId

		-- Products are ready
		INSERT INTO @ReadyProducts (ProductId)
		SELECT ProductId
		FROM bodb_PlaytechCS.dbo.Product3rd_ImportQueue WITH (NOLOCK)
		WHERE ProductId = 10
			AND Winlostdate = @WinlostDate
		GROUP BY ProductId
	END

	IF EXISTS (SELECT 1 FROM @Products WHERE ProductId = 31)
	BEGIN
		INSERT INTO @ReadyProducts (ProductId)
		SELECT TOP 1 ProductID
		FROM bodb_3rdProduct.dbo.Product3rd_SummarizedDateHistory WITH (NOLOCK)
		WHERE ProductID = 31
			AND Winlostdate = @WinlostDate
	END

	DELETE @ReadyProducts WHERE ProductId IN (SELECT ProductId FROM @NotReadyProducts)

	SET @ReadyProductIds = NULL
	SELECT @ReadyProductIds = COALESCE(@ReadyProductIds + ',', '') + CONVERT(VARCHAR(10), rp.ProductId)
	FROM @ReadyProducts rp
		INNER JOIN @Products p ON rp.ProductId = p.ProductId

	-- data of all products is not ready
	IF ISNULL(@ReadyProductIds, '') = ''
	BEGIN
		SELECT @ReadyType = 0
		RETURN
	END

	-- data of some products is ready
	IF EXISTS (
		SELECT 1
		FROM @Products p
			LEFT JOIN @ReadyProducts rp ON p.ProductId = rp.ProductId
		WHERE rp.ProductId IS NULL
	)
	BEGIN
		SELECT @ReadyType = 1
		RETURN
	END

	-- data of all products is ready
	SELECT @ReadyType = 2

	WAITFOR DELAY '00:01:00'
END
GO