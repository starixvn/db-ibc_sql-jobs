/*<info serverAlias="DBBAH-bodb02" executers="" viewers="" isFunction="0"></info>*/
ALTER PROC [dbo].[NAP_Admin_Delete_Transfer_SITEDB_Job]
AS
/*
    Created: 20221108@Max
	DB: DBBAH.bodb02
	Task: Scale out DBTrans - Enhancement to prevent high latency on Balance Record [Redmine: #180225]
	Revision:
		- 20221108@Max: Create trigger [Redmine:#180225]
		
*/
BEGIN

	SET NOCOUNT ON

	DECLARE @Archive_Date DATETIME
	SELECT @Archive_Date = DATEADD(DAY, -1, GETDATE())

	DECLARE @tmp_TransId AS TABLE (ID INT IDENTITY (1,1) PRIMARY KEY, TransId BIGINT)

	INSERT INTO @tmp_TransId (TransId)
	SELECT t.TransId
	FROM dbo.Transfer t WITH (NOLOCK)
		INNER JOIN dbo.Customer c WITH (NOLOCK) ON c.custid = t.CustId
		INNER JOIN dbo.site s WITH (NOLOCK) ON s.site = c.site
	WHERE t.TransDate <= @Archive_Date
		AND s.SiteDBGroupID <> 0
		AND c.custid <> 3

	DECLARE @StartRow INT = 1
			, @StopRow INT 
			, @MaxRow INT = 1 -- Keep the total row of your data
			, @Threshold INT = 2000 -- the number of each batch

	SET @MaxRow = (SELECT MAX(ID) FROM @tmp_TransId t)

	IF @Threshold >= @MaxRow
	BEGIN
		SET @Threshold = @MaxRow
	END

	-- SET for first batch
	SET @StopRow = @Threshold
	WHILE (1=1)
	BEGIN
		DELETE m
		FROM dbo.Transfer m WITH (NOLOCK)
			INNER JOIN @tmp_TransId t ON t.TransId = m.TransId
		WHERE t.Id BETWEEN @StartRow AND @StopRow
	
		IF @StopRow = @MaxRow BREAK

		WAITFOR DELAY '00:00:00.020'

		SET @StartRow = @StopRow + 1
		SET @StopRow = @StopRow + @Threshold
		IF @StopRow >= @MaxRow
		BEGIN
			SET @StopRow = @MaxRow
		END
	END
END
GO


