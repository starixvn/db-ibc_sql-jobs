/*<info serverAlias="DBCUST-bodb_Licensee" executers="bodbLicenseeNet" viewers="" isFunction="0" isNested="0"></info>*/
USE bodb_licensee
GO  

CREATE PROCEDURE [dbo].[DBA_Lrf_OfferProduct]
( 
	@LicenseeNameList	VARCHAR(MAX)='',
	@ProductCode		VARCHAR(MAX)='',  
	@EffectiveDate		SMALLDATETIME ='',  
	@IsPullService		BIT  = 1
)  
AS  
/*  
	Created: 20140502@Jim  
	Task : re-structure create new licensee flow  
	DB: DBCUST.bodb_licensee  
	Original :  
   
	Revisions:  
	  - 20150320@Jim: add more funtion permission for 'Active Customer Summary' report  
	  - 20150427@Jim: support product Gold Deluxe   
	  - 20160224@Jim: add pull service option  
	  - 20170912@Harper: Clean code [RedmineID: #82673] 
	  - 20180926@Sophia: migrate bodb_Licensee from DB052 to DBCUST [redmine: #99855]
	  - 20181123@Amanda: Update effective date for LicenseePorduct3rd if call SP with multi products and use DBA_Lrf_PullServiceSetting to add pull service setting [redmine: #83584]
	  - 20181228@Amanda: Modify to allow remove multi products for multi licensees[Redmine: #83584]

	Param's Explanation:    
   
*/  
  
BEGIN   
	DECLARE @tblProductPrefix		AS TABLE(ID INT IDENTITY(1,1), ProductId INT, ProductCode VARCHAR(10))  
	DECLARE @tblProductFunctions	AS TABLE(ProductId INT, FunctionId INT, TypeId INT)  
	DECLARE @tblLicensee			AS TABLE(ID INT IDENTITY(1,1), LicenseeId INT, LicenseeName VARCHAR(50), ResellerId INT)
	DECLARE @tblAdminUserID			AS TABLE (id INT IDENTITY(1,1), UserID INT)
	DECLARE @tblNoReseller			AS TABLE (LicenseeName VARCHAR(50))

	CREATE TABLE #tblLicenseeProduct (ProductId INT, ProductCode VARCHAR(10))
	CREATE TABLE #tblLicenseeFunction (FunctionId INT, TypeId INT)
	CREATE TABLE #tblDupUserFunction (UserId INT, FunctionId INT)
	CREATE TABLE #tblOAGroupID (GroupID INT)
	CREATE TABLE #tblOAUserID (id INT IDENTITY(1,1), UserID INT)

	DECLARE  @ProductName	VARCHAR(10)  
			,@n				INT  
			,@m				INT
			,@tmpEffectiveDate	SMALLDATETIME = NULL
			,@LicenseeName	VARCHAR(50) 
			,@LicenseeId	INT
			,@ResellerId	INT
			,@Error			VARCHAR(MAX) = ''
	
	IF ISNULL(@EffectiveDate,'') <> ''
	BEGIN
		SET @tmpEffectiveDate = @EffectiveDate
	END
	
	--1-----------------------------------------* GET LICENSEE LIST *------------------------------------- 

	INSERT INTO @tblLicensee (LicenseeName)
	SELECT DISTINCT val
	FROM CUSTDB.dbo.strSplit(@LicenseeNameList,',')

	UPDATE tl  
	SET tl.LicenseeId = l.LicenseeID
	FROM @tblLicensee tl 
	INNER JOIN dbo.Licensees l WITH (NOLOCK) ON tl.LicenseeName = l.LicenseeName

	UPDATE l
	SET l.ResellerId = r.ResellerID
	FROM @tblLicensee l
	INNER JOIN dbo.LicenseeReseller r WITH (NOLOCK) ON l.LicenseeID = r.LicenseeID
	WHERE r.ResellerID <> 3

	IF EXISTS (SELECT 1 FROM @tblLicensee WHERE LicenseeId IS NULL)
	BEGIN
		SELECT @Error = 'Invalid licensee(s): ' + STUFF((
							SELECT ',' + LicenseeName
							FROM @tblLicensee
							WHERE LicenseeId IS NULL
						FOR XML PATH('')), 1, 1, '')
	END

	--2-----------------------------------------* GET PRODUCT LIST *-------------------------------------

	INSERT INTO @tblProductPrefix (ProductCode)
	SELECT DISTINCT val
	FROM CUSTDB.dbo.strSplit(@ProductCode,',')
   
	UPDATE a
	SET a.ProductId = b.ProductId
	FROM @tblProductPrefix a
	INNER JOIN dbo.Product3rd b WITH (NOLOCK) ON a.ProductCode = b.ProductPrefix

    UPDATE @tblProductPrefix
	SET ProductId = 0
	WHERE ProductCode = 'SB'

	SELECT @n = 1
		,@m = MAX(ID) FROM @tblProductPrefix
	WHILE (@n <= @m)
	BEGIN
		SELECT @ProductName = ProductCode FROM @tblProductPrefix WHERE ID = @n
    
		INSERT INTO @tblProductFunctions
		EXEC DBA_Lrf_FunctionProduct @ProductCode = @ProductName
      
		SET @n = @n +1
	END
	
	IF EXISTS (SELECT 1 FROM @tblProductPrefix WHERE ProductId IS NULL)
	BEGIN
		IF ISNULL(@Error, '') <> ''
		BEGIN
			SET @Error = @Error + ';';
		END
	
		SELECT @Error = @Error + 'Invalid product(s): ' + STUFF((
							SELECT ',' + ProductCode
							FROM @tblProductPrefix
							WHERE ProductId IS NULL
						FOR XML PATH('')), 1, 1, '')

		DELETE @tblProductPrefix
		WHERE ProductId IS NULL
	END
	
	--3--------------------------------------* OFFER PRODUCT TO LICENSEE *----------------------------------
	IF EXISTS (SELECT 1 FROM @tblProductPrefix WHERE ProductCode = 'BA')
	BEGIN 
		INSERT INTO @tblAdminUserID(UserID)
		SELECT userid FROM dbo.users WITH (NOLOCK)
		WHERE username IN ('justin','martin','anthony')
			AND UserRole = 'admin'
			AND isInternal = 0
	END

	SELECT @n = 1
		,@m = MAX(ID) FROM @tblLicensee
	WHILE (@n <= @m)
	BEGIN
		SELECT @LicenseeId = LicenseeId, @LicenseeName = LicenseeName, @ResellerId = ResellerId
		FROM @tblLicensee
		WHERE ID = @n
		
		IF @LicenseeId IS NOT NULL
		BEGIN
			;WITH LicenseeProduct_CTE AS (
				SELECT ProductId   
				FROM dbo.LicenseeProduct3rd WITH (NOLOCK)   
				WHERE LicenseeId = @LicenseeId
			)
			INSERT INTO #tblLicenseeProduct(ProductId, ProductCode)
			SELECT p.ProductId, p.ProductCode
			FROM @tblProductPrefix p
			LEFT JOIN LicenseeProduct_CTE c ON p.ProductId = c.ProductID
			WHERE c.ProductID IS NULL

			INSERT INTO dbo.LicenseeProduct3rd(LicenseeID, ProductID, Comm, Winloss, EffectiveDate)
			SELECT @LicenseeId, ProductId, 0, 1, @tmpEffectiveDate
			FROM #tblLicenseeProduct

			-- 3.1 Open report on LRF/LAP
			INSERT INTO #tblLicenseeFunction(FunctionId, TypeId)
			SELECT DISTINCT f.FunctionId, f.TypeId
			FROM @tblProductFunctions f
			INNER JOIN #tblLicenseeProduct p ON f.ProductId = p.ProductId
			WHERE f.TypeId = 1 OR f.TypeId = 2

			INSERT INTO dbo.LicenseeFunctions (FunctionId, licenseeID)  
			SELECT f.FunctionId, @LicenseeId
			FROM #tblLicenseeFunction f
			LEFT JOIN dbo.LicenseeFunctions lf WITH (NOLOCK) ON f.FunctionId = lf.FunctionId AND lf.LicenseeId = @LicenseeId
			WHERE f.TypeId = 1 AND lf.FunctionId IS NULL
			
			-- 3.2 LicenseeUserFunctions  
			INSERT INTO #tblDupUserFunction(UserId, FunctionId)  
			SELECT luf.UserId, luf.FunctionId
			FROM dbo.LicenseeUserFunctions luf WITH (NOLOCK)
			INNER JOIN #tblLicenseeFunction f ON luf.FunctionId = f.FunctionId
			WHERE luf.LicenseeID = @LicenseeID AND f.TypeId = 1

			;WITH LicenseeUser_CTE AS (
				SELECT u.UserID
				FROM dbo.Users u WITH (NOLOCK)
				INNER JOIN dbo.LicenseeUser lu WITH (NOLOCK) ON u.UserID = lu.UserID
				WHERE lu.LicenseeID = @LicenseeId AND u.[Status] = 'Open'
			)
			INSERT INTO dbo.LicenseeUserFunctions(UserId, FunctionId, LicenseeId)
			SELECT c.UserID, lf.FunctionId, @LicenseeId
			FROM LicenseeUser_CTE c
			CROSS JOIN #tblLicenseeFunction lf
			LEFT JOIN #tblDupUserFunction df ON lf.FunctionId = df.FunctionId AND c.UserID = df.UserId
			WHERE lf.TypeId = 1 AND df.UserId IS NULL
			
			-- 3.4 Insert OA_Function
			IF ISNULL(@ResellerID, 0) > 0
			BEGIN
				INSERT INTO DBLIC.bodb_licensee.dbo.OA_FunctionResellers (FunctionID, ResellerId)
				SELECT oaf.FunctionID, @ResellerID
				FROM DBLIC.bodb_licensee.dbo.OA_Functions oaf WITH (NOLOCK)
				INNER JOIN #tblLicenseeFunction pf ON oaf.FunctionID = pf.FunctionId
				WHERE pf.TypeId = 2 AND NOT EXISTS (
					SELECT 1
					FROM DBLIC.bodb_licensee.dbo.OA_FunctionResellers fs WITH (NOLOCK)
					WHERE fs.ResellerID = @ResellerID AND fs.FunctionId = pf.FunctionId
				)

				INSERT INTO DBLIC.bodb_licensee.dbo.OA_FunctionLicensees (FunctionID, ResellerID, LicenseeID)  
				SELECT oaf.FunctionID, @ResellerID, @LicenseeId  
				FROM DBLIC.bodb_licensee.dbo.OA_Functions oaf WITH (NOLOCK)    
				INNER JOIN #tblLicenseeFunction pf ON oaf.FunctionID = pf.FunctionId  
				WHERE pf.TypeId = 2 AND NOT EXISTS (
					SELECT 1  
					FROM DBLIC.bodb_licensee.dbo.OA_FunctionLicensees fl WITH (NOLOCK)  
					WHERE fl.LicenseeID   = @LicenseeId   
						AND fl.ResellerID = @ResellerID
						AND fl.FunctionId = pf.FunctionId
				)
			END
			ELSE
			BEGIN
				INSERT INTO @tblNoReseller(LicenseeName)
				VALUES (@LicenseeName)
			END

			-- 3.5 PULL DATA INTO SERVICE
			IF EXISTS (SELECT 1 FROM #tblLicenseeProduct WHERE ProductCode = 'AGC') AND @IsPullService =1
			BEGIN   
				EXEC DBPTCS.bodb_PlaytechCS.[dbo].[DBA_Lrf_PullServiceSetting] @LicenseeID = @LicenseeId, @LicenseeName = @LicenseeName, @SettingName ='AGCasino_VersionKey'
			END  

			IF EXISTS (SELECT 1 FROM #tblLicenseeProduct WHERE ProductCode = 'GD') AND @IsPullService =1  
			BEGIN   
				EXEC DBPTCS.bodb_PlaytechCS.[dbo].[DBA_Lrf_PullServiceSetting] @LicenseeID = @LicenseeId, @LicenseeName = @LicenseeName, @SettingName ='GoldDeluxe_VersionKey'
			END

			-- 3.6 Config BA
			IF EXISTS (SELECT 1 FROM #tblLicenseeProduct WHERE ProductCode = 'BA')  
			BEGIN  
				IF NOT EXISTS(SELECT 1 FROM dbo.LicenseeReseller WITH (NOLOCK) WHERE LicenseeID = @LicenseeID AND ResellerID = 3)
				BEGIN
					-- Add Licensee to BA reseller  
					INSERT INTO dbo.LicenseeReseller (ResellerID,LicenseeID,TnxRate)
					VALUES (3, @LicenseeID,0.13)

					-- Insert OA group for BA reseller (OA_GroupLicensees)
					INSERT INTO #tblOAGroupID(GroupID)
					SELECT DISTINCT GroupID FROM DBLIC.bodb_licensee.dbo.OA_GroupLicensees WITH (NOLOCK) WHERE LicenseeID = @LicenseeID AND ResellerID <> 3
					
					DELETE g
					FROM #tblOAGroupID g
					INNER JOIN DBLIC.bodb_licensee.dbo.OA_GroupLicensees o WITH (NOLOCK) ON o.GroupID = g.GroupID
					WHERE o.ResellerID = 3 AND o.LicenseeID = @LicenseeID
					
					INSERT INTO DBLIC.bodb_licensee.dbo.OA_GroupLicensees (GroupID,ResellerID,LicenseeID) 
					SELECT GroupID, 3, @LicenseeId
					FROM #tblOAGroupID

					-- Insert OA Users for BA reseller (OA_UserLicensees)  
					INSERT INTO #tblOAUserId(UserID)  
					SELECT DISTINCT UserID FROM DBLIC.bodb_licensee.dbo.OA_UserLicensees WITH (NOLOCK) WHERE LicenseeID = @LicenseeID AND ResellerID <> 3
					
					DELETE u
					FROM #tblOAUserId u
					INNER JOIN DBLIC.bodb_licensee.dbo.OA_UserLicensees o WITH (NOLOCK) ON u.UserID = o.UserID
					WHERE o.ResellerID = 3 AND o.LicenseeID = @LicenseeID
					
					INSERT INTO DBLIC.bodb_licensee.dbo.OA_UserLicensees (UserID,ResellerID,LicenseeID)
					SELECT UserID, 3, @LicenseeId
					FROM #tblOAUserId
				END
			
				-- Insert SpecialBA for justin,martin,anthony
				DECLARE @j		INT, 
						@k		INT,
						@UserId	INT

				SET @j = 1
				SELECT @k = MAX(id) FROM @tblAdminUserID

				WHILE @j <= @k
				BEGIN			
					SELECT @UserID = UserID FROM @tblAdminUserID WHERE id = @j

					IF NOT EXISTS (SELECT 1 FROM dbo.LicenseeUserFunctions WITH (NOLOCK) WHERE licenseeid=@LicenseeId AND Userid=@UserId AND Functionid = 54)
					BEGIN  
						INSERT INTO dbo.LicenseeUserFunctions(LicenseeId, UserId, FunctionId)
						SELECT @LicenseeId, @UserId, 54
					END
					
					SET @j = @j + 1
				END

				TRUNCATE TABLE #tblOAGroupID
				TRUNCATE TABLE #tblOAUserId
			END

			TRUNCATE TABLE #tblLicenseeProduct
			TRUNCATE TABLE #tblDupUserFunction
			TRUNCATE TABLE #tblLicenseeFunction
		END
		
		SET @n = @n +1
	END

	IF EXISTS (SELECT 1 FROM @tblNoReseller)
	BEGIN
		IF ISNULL(@Error, '') <> ''
		BEGIN
			SET @Error = @Error + ';';
		END
	
		SELECT @Error = @Error + 'Licensee(s) do(es) not have reseller: ' + STUFF((
							SELECT ',' + LicenseeName
							FROM @tblNoReseller
						FOR XML PATH('')), 1, 1, '')
	END

	SELECT @Error AS Error
	
	DROP TABLE #tblLicenseeProduct
	DROP TABLE #tblDupUserFunction
	DROP TABLE #tblLicenseeFunction
	DROP TABLE #tblOAGroupID
	DROP TABLE #tblOAUserId
END
GO