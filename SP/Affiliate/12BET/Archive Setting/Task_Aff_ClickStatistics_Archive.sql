/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Task_Aff_ClickStatistics_Archive]
	@MonthDate		SMALLDATETIME
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Affiliate 12BET - Job - Archive ClickStatistics

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
		- 20190808@Percy: Loop archive data + delete 3000 rows per batch to prevent lock tables [RedmineID: #115959]
		- 20220609@Malcolm: Sum and backup data in BannerStatistics table [RedmineID: #173433]
		- 20220929@Eddie: Add Country info [RedmineID: #176390]
		- 20230215@Eddie: New sum tables [RedmineID: #177639]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @FirstDayOfMonth SMALLDATETIME, @LastDayOfMonth SMALLDATETIME

	SELECT  @FirstDayOfMonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0)
	SELECT  @LastDayOfMonth  = DATEADD(DAY, -1, DATEADD(MONTH, 1, @FirstDayOfMonth))

	-- Check month of @MonthDate is completed
	IF @LastDayOfMonth > CURRENT_TIMESTAMP
	BEGIN
		SELECT 'This month is not completed yet!'

		RETURN
	END

	-- Check job run already
	IF EXISTS (SELECT 1 FROM dbo.ClickStatistics1Sum WITH (NOLOCK) WHERE Date = @FirstDayOfMonth)
		AND EXISTS (SELECT 1 FROM dbo.BannerStatisticsSum WITH(NOLOCK) WHERE CopyDate = @FirstDayOfMonth)
	BEGIN
		SELECT 'Data is already done for this month!'
		RETURN
	END

	-- Sum data
	BEGIN
	-- ClickStatistics1Sum
		INSERT INTO dbo.ClickStatistics1Sum
		(
			AffID
			,DomainReferrer
			,Date
			,SportCode
			,LanguageCode
			,TotalClick
			,UniqueClick
			,DeviceType
		)
		SELECT
			AffId
			,DomainReferrer
			,Date
			,SportCode
			,LanguageCode
			,COUNT(1) AS TotalClick
			,COUNT (DISTINCT IP) AS UniqueClick
			,DeviceType
		FROM dbo.ClickStatistics1 WITH (NOLOCK)
		WHERE Date BETWEEN @FirstDayOfMonth AND @LastDayOfMonth
		GROUP BY
			AffId
			,DomainReferrer
			,Date
			,SportCode
			,LanguageCode
			,DeviceType
			
	-- CSSumByCountryCode
		INSERT INTO dbo.CSSumByCountryCode
		(
			AffID
			,Date
			,TotalClick
			,UniqueClick
			,DeviceType
			,DomainReferrer
			,CountryCode
		)
		SELECT
			AffId
			,Date
			,COUNT(1) AS TotalClick
			,COUNT (DISTINCT IP) AS UniqueClick
			,DeviceType
			,DomainReferrer
			,Country
		FROM dbo.ClickStatistics1 WITH (NOLOCK)
		WHERE Date BETWEEN @FirstDayOfMonth AND @LastDayOfMonth
		GROUP BY
			AffId
			,Date
			,DeviceType
			,DomainReferrer
			,Country
			
	-- CSSumByCountryCodeandSportCode
		INSERT INTO dbo.CSSumByCountryCodeandSportCode
		(
			AffID
			,Date
			,TotalClick
			,UniqueClick
			,DeviceType
			,CountryCode
			,SportCode
		)
		SELECT
			AffId
			,Date
			,COUNT(1) AS TotalClick
			,COUNT (DISTINCT IP) AS UniqueClick
			,DeviceType
			,Country
			,SportCode
		FROM dbo.ClickStatistics1 WITH (NOLOCK)
		WHERE Date BETWEEN @FirstDayOfMonth AND @LastDayOfMonth
		GROUP BY
			AffId
			,Date
			,DeviceType
			,Country
			,SportCode
			
	-- CSSumBySportCodeandLanguageCode
		INSERT INTO dbo.CSSumBySportCodeandLanguageCode
		(
			AffID
			,Date
			,TotalClick
			,UniqueClick
			,DeviceType
			,SportCode
			,LanguageCode
		)
		SELECT
			AffId
			,Date
			,COUNT(1) AS TotalClick
			,COUNT (DISTINCT IP) AS UniqueClick
			,DeviceType
			,SportCode
			,LanguageCode
		FROM dbo.ClickStatistics1 WITH (NOLOCK)
		WHERE Date BETWEEN @FirstDayOfMonth AND @LastDayOfMonth
		GROUP BY
			AffId
			,Date
			,DeviceType
			,SportCode
			,LanguageCode

		INSERT INTO dbo.BannerStatisticsSum 
		(
			BannerId
			,CopyDate
			,TotalClick
		)
		SELECT 
			bs.BannerId
			,CONVERT(DATE, bs.CopyDate) AS CopyDate
			,COUNT(1) AS TotalClick
		FROM dbo.BannerStatistics bs WITH(NOLOCK)
		WHERE bs.CopyDate >= @FirstDayOfMonth AND bs.CopyDate < DATEADD (DAY, 1, @LastDayOfMonth)
		GROUP BY 
			bs.BannerId
			,CONVERT(DATE, bs.CopyDate) 

	END

	-- Archive data
	BEGIN
		DECLARE @winlostdate SMALLDATETIME
		SELECT  @winlostdate = @FirstDayOfMonth

		WHILE @winlostdate <= @LastDayOfMonth
		BEGIN
			WHILE 1 = 1
			BEGIN
				DELETE TOP (3000) dbo.ClickStatistics1 WITH (ROWLOCK, UPDLOCK)
				OUTPUT
					DELETED.ClickId,
					DELETED.AffId,
					DELETED.UpdatedTime,
					DELETED.IP,
					DELETED.Date,
					DELETED.Browser,
					DELETED.URLReferrer,
					DELETED.DomainReferrer,
					DELETED.OS,
					DELETED.Device,
					DELETED.BrowserVersion,
					DELETED.BrowserResolution,
					DELETED.BrowserLanguage,
					DELETED.UserAgent,
					DELETED.Country,
					DELETED.LanguageCode,
					DELETED.SportCode,
					DELETED.RedirectURL,
					DELETED.Status,
					DELETED.DeviceType
				INTO dbo.ClickStatistics1_bk
				(
					ClickId,
					AffId,
					UpdatedTime,
					IP,
					Date,
					Browser,
					URLReferrer,
					DomainReferrer,
					OS,
					Device,
					BrowserVersion,
					BrowserResolution,
					BrowserLanguage,
					UserAgent,
					Country,
					LanguageCode,
					SportCode,
					RedirectURL,
					Status,
					DeviceType
				)
				WHERE Date = @winlostdate

				IF @@ROWCOUNT < 3000
					BREAK

				WAITFOR DELAY '00:00:00.280'
			END

			WHILE 1 = 1 
			BEGIN
				DELETE TOP(3000) dbo.BannerStatistics WITH(ROWLOCK, UPDLOCK)
				OUTPUT 
					DELETED.ClickId
					,DELETED.AffId
					,DELETED.BannerId
					,DELETED.CopyDate
				INTO dbo.BannerStatistics_bk
				(
					ClickId
					,AffId
					,BannerId
					,CopyDate
				)
				WHERE CopyDate >= @winlostdate AND CopyDate < DATEADD(DAY, 1, @winlostdate)

				IF @@ROWCOUNT < 3000
					BREAK

				WAITFOR DELAY '00:00:00.280'
			END

			SELECT @winlostdate = DATEADD(DAY, 1, @winlostdate)
		END
	END
END
GO