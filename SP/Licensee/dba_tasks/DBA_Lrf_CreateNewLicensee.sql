 /*<info serverAlias="DBCUST-bodb_Licensee" executers="bodbLicenseeNet" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[DBA_Lrf_CreateNewLicensee] (
	@LicenseeName VARCHAR(50)
	, @SuperWildCard VARCHAR(100) = ''
	, @ResellerName VARCHAR(50) = ''
	, @IsSpecial BIT = 0
	, @ProductCode VARCHAR(100) = ''
	, @SystemisActive VARCHAR(100) = ''
	, @IsAllowMemberComm BIT = 0
	, @IsAllowWLbyLeague BIT = 0
	, @IsPullService BIT = 1
	, @EffectiveDate DATE = ''
	, @Description VARCHAR(100) = NULL
	, @BrandName VARCHAR(100) = ''
	, @CompanyName VARCHAR(100) = ''
)
AS
/*  
	Created: Henry  
	Date: 20120409  
	Task : Procedure to create a new Licensee  
	DB: DBCUST.bodb_Licensee  
	Original:  
  
	Revisions:  
	 +20120716@Jim: add IsActive config for new licensee   
	 +20121205@henry: add param @SuperWildCard  
	 +20130204@Jim: add param @ResellerID   
	 +20130603@Jim: grant currency permission   
	 +20130624@Jim: set default for new licensee on Accounting system is inactive   
	 +20130725@Jim: restrict permission for DW function   
	 +20140318@Jim: hard-code to grant 'Account managerment' role just for 'CSD_11101'  
	 +20140404@Jim: + hard-code to grant 'Account managerment' role for special user  
		   + hard-code to not grant Agency System Function for new licensee  
	 +20140422@Jim: re-arrange data flow         
	 +20150504@Jim: correct function permission for GD,Void Bridge,AG,Playtech,  
	 +20160224@Jim: add pull service option  
	 +20160526@Jim: add more admin users  
	 +20160909@Jim: config edit betsetting role
	 +20180926@Sophia: migrate bodb_Licensee from DB052 to DBCUST [redmine: #99855]
	 +20181109@Amanda: remove unused params and add new effective date param [redmine: #83584]
	 +20181129@Amanda: update the way to add admin users and their permissions for new licensee [redmine: #83584]
	 +20190103@Amanda: update parameters of SP DBA_Lrf_OfferProduct [redmine: #83584]
	 +20190114@Amanda: add more info for new licensee [redmine: #83584]
	 
	Param's Explanation:  
	 + @IsSpecial: if 1 then update column Description to normal, or affiliate or banner depend on:  
	  - username ending with 01: normal  
	  - username ending with 02: affiliate  
	  - username ending with 03: banner  
	  - username ending with 04: income access  
	 + @SuperWildCard example: 12BETSuper%  
	 + @ResellerID : Reseller who new Licensee must to belong   
	 + @IsAllowedDW : offer DW :1  else :0  
*/
BEGIN
SET NOCOUNT ON

----- DECLARE VARIABLE   
DECLARE @AdminUser AS TABLE (
		id			INT IDENTITY(1, 1)
	,	UserID		INT
	,	Username	VARCHAR(50)
	)
DECLARE @SpecialAdmin AS TABLE (
		id			INT IDENTITY(1, 1)
	,	UserID		INT
	,	Username	VARCHAR(50)
	)
DECLARE @LicenseeId	INT
	,	@ResellerID	INT

--- CREATE AGENT  
	IF LTRIM(RTRIM(ISNULL(@SuperWildCard, ''))) = ''
		SET @SuperWildCard = @LicenseeName + 'Super%'

	EXEC DBA_CreateLicenseeAgent @LicenseeName = @LicenseeName
		, @SuperWildCard	= @SuperWildCard
		, @IsSpecial		= @IsSpecial

--- END: CREATE AGENT

SELECT @LicenseeId = licenseeid
FROM dbo.licensees WITH (NOLOCK)
WHERE licenseename = @LicenseeName

IF ISNULL(@licenseeid, 0) = 0
	RAISERROR ('Could not insert new licensee, please check again', 16, 1)

--- ADD NEW LICENSEE CONFIG INTO SYSTEMLICENSEE   
	INSERT INTO dbo.SystemLicensee (
			SystemID
		,	LicenseeID
		,	IsActive
	)
	SELECT	s.ID
		,	@LicenseeID AS LicenseeID
		,	CASE 
				WHEN s.ID IN (1, 2) THEN 1 -- LRF, LA
				ELSE 0
			END AS IsActive
	FROM dbo.Systems s WITH (NOLOCK)
	WHERE NOT EXISTS (
			SELECT 1
			FROM dbo.SystemLicensee sl WITH (NOLOCK)
			WHERE sl.LicenseeID = @licenseeid AND sl.SystemId = s.id
	)
 
	IF ISNULL(@SystemisActive, '') <> ''
	BEGIN
		EXEC DBA_Lrf_ActiveLicenseeSystem
				@LicenseeName	= @LicenseeName
			,	@SystemisActive = @SystemisActive
	END
--- END: ADD NEW LICENSEE CONFIG INTO SYSTEMLICENSEE  

--- ADD RESELLER LICENSEE
	IF NOT EXISTS (
			SELECT 1
			FROM dbo.Resellers WITH (NOLOCK)
			WHERE ResellerName = @ResellerName
			)
	BEGIN
		INSERT INTO dbo.Resellers (
				ResellerName
			,	[Description]
			,	ResellerType
			)
		SELECT	@ResellerName
			,	NULL
			,	2
	END

	INSERT INTO dbo.LicenseeReseller (
			ResellerID
		,	LicenseeID
		,	TnxRate
		)
	SELECT	ResellerId
		,	@LicenseeID AS LicenseeID
		,	0.13 AS TnxRate
	FROM dbo.Resellers WITH (NOLOCK)
	WHERE ResellerName = @ResellerName
--- END: ADD RESELLER LICENSEE

SELECT @ResellerID = ResellerID
FROM dbo.Resellers WITH (NOLOCK)
WHERE ResellerName = @ResellerName

---- REGIST NEW RESELLER IN L.A  
	IF NOT EXISTS (
			SELECT 1
			FROM DBLIC.bodb_Licensee.dbo.OA_GroupLicensees WITH (NOLOCK)
			WHERE ResellerID = @ResellerID AND LicenseeID = @LicenseeID
			)
	BEGIN
		INSERT INTO DBLIC.bodb_Licensee.dbo.OA_GroupLicensees (
				GroupID
			,	ResellerID
			,	LicenseeID
			)
		SELECT	Groupid
			,	@resellerid
			,	@LicenseeID
		FROM DBLIC.bodb_Licensee.dbo.OA_GroupLicensees WITH (NOLOCK)
		WHERE licenseeid = 9 AND resellerid = 2
	END

	IF NOT EXISTS (
			SELECT 1
			FROM DBLIC.bodb_Licensee.dbo.OA_UserLicensees WITH (NOLOCK)
			WHERE ResellerID = @ResellerID AND LicenseeID = @LicenseeID
			)
	BEGIN
		INSERT INTO DBLIC.bodb_Licensee.dbo.OA_UserLicensees (
				UserID
			,	ResellerID
			,	LicenseeID
			)
		SELECT	Userid
			,	@resellerid
			,	@LicenseeID
		FROM DBLIC.bodb_Licensee.dbo.OA_UserLicensees WITH (NOLOCK)
		WHERE licenseeid = 9 AND resellerid = 2
	END
--- END: ADD RESELLER LICENSEE

--- SET BETSETTING IS ACTIVE AS DEFAULT
	IF @ResellerName IN ('Zelianta','Boping')
	BEGIN 
		UPDATE dbo.Licensees WITH (ROWLOCK,UPDLOCK)
		SET EditBetSetting =1 
		WHERE LicenseeID = @LicenseeID
	END
--- END: SET BETSETTING IS ACTIVE AS DEFAULT

--- UPDATE Licensee info
	UPDATE dbo.Licensees WITH (ROWLOCK,UPDLOCK)
	SET [Description] = @Description,
		BrandName = @BrandName,
		CompanyName = @CompanyName
	WHERE LicenseeID = @LicenseeID
--- END: UPDATE Licensee info

--- UPDATE AffectedDate
	IF ISNULL(@EffectiveDate, '') <> ''
	BEGIN 
		UPDATE dbo.Licensees WITH (ROWLOCK,UPDLOCK)
		SET AffectedDate = @EffectiveDate 
		WHERE LicenseeID = @LicenseeID
	END
--- END: UPDATE AffectedDate

--- ENABLE PLAYER COMM
	IF @IsAllowMemberComm = 1
	BEGIN
		EXEC DBA_Lrf_EnablePlayerComm @LicenseeName = @LicenseeName
	END
--- END: ENABLE PLAYER COMM

--- ADD ADMIN USER INTO NEW LICENSEE   
	INSERT INTO @AdminUser (UserID, Username)
	SELECT UserID, Username
	FROM dbo.Users WITH (NOLOCK)
	WHERE userrole = 'admin' AND [STATUS] = 'Open'

	-- Update existing licensee user
	UPDATE dbo.LicenseeUser WITH (ROWLOCK, UPDLOCK)
	SET isActive = 1, PageAccess = ''
	WHERE LicenseeID = @licenseeid	

	-- Insert admin user
	INSERT INTO dbo.LicenseeUser (LicenseeID, UserID, isActive, PageAccess)
	SELECT @licenseeid, a.UserID, 1, ''
	FROM @AdminUser a
	WHERE NOT EXISTS (SELECT 1 FROM dbo.LicenseeUser l WITH (NOLOCK) WHERE l.LicenseeID = @licenseeid AND l.UserId = a.UserId)

	INSERT INTO @SpecialAdmin (UserID, Username)
	SELECT UserID, Username
	FROM @AdminUser
	WHERE UserID IN (
				1, -- dbaThien
				3, -- pgmviet
				5, -- pgmSon
				63, -- Martin
				64, -- Justin
				68, -- pgmChuong
				74, -- pgmkiwi
				87, -- CSD_11101
				157, -- pgmAnn
				160, -- Anthony
				369, -- dbaDon
				2939, -- standbyteam
				3232, -- dbaVictor
				3652, -- pgmWilliam
				3783, -- twLesley
				3784, -- twKai
				3834, --dbaFrancis
				8436, -- StarixQC2
				8437, -- StarixQC3
				8438, -- StarixQC4
				8439, -- StarixQC5
				8440, -- starix1
				8441, -- starix2
				8442 -- starix3
			)

	-- Add admin permission		
	IF EXISTS (SELECT TOP(1) 1 FROM @SpecialAdmin)
	BEGIN
		INSERT INTO dbo.LicenseeFunctions(LicenseeId, FunctionId)
		SELECT @licenseeid, f.FunctionId
		FROM dbo.Functions f WITH (NOLOCK)
		WHERE (f.ParentId IN (6, 74) OR f.FunctionId IN (6, 74))
				AND NOT EXISTS (SELECT 1 
								FROM dbo.LicenseeFunctions l WITH (NOLOCK)
								WHERE l.LicenseeID = @licenseeid AND l.FunctionId = f.FunctionId)
				
		INSERT INTO dbo.LicenseeUserFunctions(LicenseeId, UserId, FunctionId)
		SELECT @licenseeid, a.UserID, f.FunctionId	
		FROM @SpecialAdmin a, dbo.Functions f WITH (NOLOCK)
		WHERE (f.ParentId IN (6, 74) OR f.FunctionId IN (6, 74))
				AND NOT EXISTS (SELECT 1 
								FROM dbo.LicenseeUserFunctions l WITH (NOLOCK)
								WHERE l.LicenseeID = @licenseeid AND l.UserId = a.UserId AND l.FunctionId = f.FunctionId)
	END
--- END: ADD ADMIN USER INTO NEW LICENSEE  

--- OFFER PRODUCT3rd  
IF ISNULL(@ProductCode, '') <> ''
BEGIN
	EXEC DBA_Lrf_OfferProduct
		@LicenseeNameList = @LicenseeName
		, @ProductCode = @ProductCode
		, @IsPullService = @IsPullService
		, @EffectiveDate = @EffectiveDate
END
--- END: OFFER PRODUCT3rd 

--- ENABLE WIN LOSS By LEAGUE
IF (@IsAllowWLbyLeague = 1)
BEGIN
	IF NOT EXISTS (SELECT 1 FROM dbo.LicenseeFunctions WITH (NOLOCK) WHERE LicenseeId = @LicenseeId AND FunctionID = 59)
	BEGIN
		INSERT INTO dbo.LicenseeFunctions(LicenseeId, FunctionId)
		VALUES(@LicenseeId, 59)
	END

	INSERT INTO dbo.LicenseeUserFunctions (
			UserId
		,	FunctionId
		,	LicenseeId
		)
	SELECT	u.UserId
		,	59
		,	@LicenseeID
	FROM dbo.LicenseeUser u WITH (NOLOCK)
	WHERE u.LicenseeId = @LicenseeId
		AND NOT EXISTS (SELECT 1 
						FROM dbo.LicenseeUserFunctions f WITH (NOLOCK)
						WHERE f.LicenseeID = @licenseeid AND f.UserId = u.UserId AND f.FunctionId = 59)
END
--- END: ENABLE WIN LOSS By LEAGUE

--- GRANT CURRENCY PERMISSION  
	DECLARE @Currency AS TABLE (
			LicenseeID	INT
		,	CurrencyID	INT
	)

	INSERT INTO @Currency (
			LicenseeID
		,	CurrencyID
	)
	SELECT	DISTINCT LicenseeID
		,	Currency CurrencyID
	FROM dbo.LicenseeCust WITH (NOLOCK)
	WHERE LicenseeID = @LicenseeID

	INSERT INTO dbo.CurrencyUser (
			usrID
		,	LicenseeID
		,	CurrencyID
		,	SystemID
		,	isActive
		)
	SELECT	u.UserID
		,	@LicenseeID
		,	c.CurrencyID
		,	1
		,	1 ---SystemID=1 is default for Lrf  
	FROM dbo.LicenseeUser u WITH (NOLOCK)
	INNER JOIN @Currency c ON u.LicenseeID = c.LicenseeID
	WHERE u.LicenseeID = @LicenseeID
	EXCEPT
	SELECT	usrID
		,	LicenseeID
		,	CurrencyID
		,	1
		,	1
	FROM dbo.CurrencyUser WITH (NOLOCK)
	WHERE LicenseeID = @LicenseeID
--- END: GRANT CURRENCY PERMISSION 

------------------------------------------------------  
-- Map Licencee to LicenseeBAConfig  
------------------------------------------------------  
EXEC DBA_LicenseeBAConfig_Ins @LicenseeID = @licenseeid
	, @groupa = 0.0025
	, @groupb = 0.005
	, @groupc = 0.0075
	, @groupd = 0.01
	, @1x2Comm = 0.005
	, @OtherComm = 0.005
	, @EnableBA = 0
	, @UserID = 862400 --pgmViet

END
GO
