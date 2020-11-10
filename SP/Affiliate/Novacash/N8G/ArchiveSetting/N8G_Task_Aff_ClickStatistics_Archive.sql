/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Aff_ClickStatistics_Archive]
	@MonthDate SMALLDATETIME
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: Affiliate 12BET - Job - Archive ClickStatistics

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128755]
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
	IF EXISTS (SELECT 1 FROM dbo.ClickStatisticsSum WITH (NOLOCK) WHERE Date = @FirstDayOfMonth)
	BEGIN
		SELECT 'Data is already done for this month!'
		RETURN
	END

	-- Sum data
	BEGIN
		INSERT INTO dbo.ClickStatisticsSum
		(
			AffID,
			DomainReferrer,
			Date,
			SportCode,
			LanguageCode,
			TotalClick,
			UniqueClick,
			DeviceType
		)
		SELECT
			AffId,
			DomainReferrer,
			Date,
			SportCode,
			LanguageCode,
			COUNT(1) AS TotalClick,
			COUNT (DISTINCT IP) AS UniqueClick,
			DeviceType
		FROM dbo.ClickStatistics WITH (NOLOCK)
		WHERE Date BETWEEN @FirstDayOfMonth AND @LastDayOfMonth
		GROUP BY
			AffId,
			DomainReferrer,
			Date,
			SportCode,
			LanguageCode,
			DeviceType
	END

	-- Archive data
	BEGIN
		DECLARE @winlostdate SMALLDATETIME
		SELECT  @winlostdate = @FirstDayOfMonth

		WHILE @winlostdate <= @LastDayOfMonth
		BEGIN
			WHILE 1 = 1
			BEGIN
				DELETE TOP (3000) dbo.ClickStatistics WITH (ROWLOCK, UPDLOCK)
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
				INTO dbo.ClickStatistics_bk
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

			SELECT @winlostdate = DATEADD(DAY, 1, @winlostdate)
		END
	END
END
GO