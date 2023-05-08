/*<info serverAlias="DBN88-bodb_N88" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Customer_Upd]
AS

/*
	Created: 20220110@Malcolm
	DB: DBN88-bodb_N88
	Task: Update data of Customer table

	Revisions:
		- 20220110@Malcolm: Initialize SP [RedmineID: #182738]
		- 20230505@Evan: Fix get correct CustId with new format [RedmineID: #187829]
		
	Param's Explanation:
	
*/
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #Result (Id INT IDENTITY(1, 1) PRIMARY KEY, TpSystemUsername VARCHAR(50), CustId INT)

	CREATE NONCLUSTERED INDEX IX_CustId ON #Result(CustId)

	DECLARE @UpdatedDate DATETIME, @CurrentDate SMALLDATETIME = GETDATE()

	SELECT @UpdatedDate = CONVERT(DATETIME, SValue) FROM dbo.SystemSettings WITH(NOLOCK) WHERE SName = 'UpdatedCustomer_Date'

	IF DATEDIFF(HOUR, @UpdatedDate, @CurrentDate) < 6
	BEGIN
		RETURN
	END

	DECLARE @SiteName VARCHAR(50), @LicenseeName VARCHAR(50), @SiteId INT, @Id INT = 0, @MaxId INT = -1

	SELECT @SiteId = MIN(SiteId) FROM ServerInfo WITH(NOLOCK) 

	WHILE 1 = 1
	BEGIN
		SELECT TOP(1) @SiteId = SiteId, @SiteName = SiteName, @LicenseeName = LicenseeName
		FROM ServerInfo WITH(NOLOCK) 
		WHERE SiteId >= @SiteId 
		ORDER BY SiteId ASC

		IF @@ROWCOUNT = 0
			BREAK

		INSERT INTO #Result (TpSystemUsername, CustId)
		SELECT Username, CONVERT(INT, REPLACE(username2,LEFT(username2,LEN(username2) - CHARINDEX('_',REVERSE(username2)) + 1),''))
		FROM bodb02.dbo.Customer WITH(NOLOCK, INDEX = IX_username2) 
		WHERE username2 LIKE @LicenseeName + '$' + @SiteName + '[_]%' AND creatdate >= DATEADD(DAY, -2, @CurrentDate)

		SET @SiteId += 1
	END

	SELECT @Id = 0, @MaxId = MAX(Id) FROM #Result 
	
	WHILE @Id <= @MaxId
	BEGIN
		UPDATE c WITH(ROWLOCK, UPDLOCK)
			SET c.TpSystemUserName = r.TpSystemUsername
		FROM dbo.Customer c
			INNER JOIN #Result r ON r.CustId = c.CustId
		WHERE r.Id >= @Id AND r.Id < @Id + 2000 AND ISNULL(c.TpSystemUserName, '') = ''

		SET @Id += 2000
	END

	UPDATE dbo.SystemSettings WITH(ROWLOCK, UPDLOCK) 
		SET SValue = CONVERT(VARCHAR(200), @CurrentDate, 120)
	WHERE SName = 'UpdatedCustomer_Date'

	DROP TABLE #Result
END
GO
