/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Aff_Settings_Archive]
	@MonthDate SMALLDATETIME
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Job - Archive Setting

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
		- 20210714@Percy: Add table StraightSettingHistory [RedmineID: #157958]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @NextMonthDate SMALLDATETIME

	SELECT  @MonthDate		= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate) + 1, 0))
	SELECT  @NextMonthDate	= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate) + 2, 0))

	IF (
		EXISTS (SELECT 1 FROM dbo.TierSettingHistory WITH (NOLOCK) WHERE MonthDate IN (@MonthDate, @NextMonthDate))
		OR EXISTS (SELECT 1 FROM dbo.AffGroupHistory WITH (NOLOCK) WHERE MonthDate IN (@MonthDate, @NextMonthDate))
		OR EXISTS (SELECT 1 FROM dbo.DeductionSettingHistory WITH (NOLOCK) WHERE MonthDate IN (@MonthDate, @NextMonthDate))
		OR EXISTS (SELECT 1 FROM dbo.StraightSettingHistory WITH (NOLOCK) WHERE MonthDate IN (@MonthDate, @NextMonthDate))
	)
	BEGIN
		DELETE dbo.TierSettingHistory WITH (ROWLOCK, UPDLOCK) WHERE MonthDate IN (@MonthDate, @NextMonthDate)
		DELETE dbo.AffGroupHistory WITH (ROWLOCK, UPDLOCK) WHERE MonthDate IN (@MonthDate, @NextMonthDate)
		DELETE dbo.DeductionSettingHistory WITH (ROWLOCK, UPDLOCK) WHERE MonthDate IN (@MonthDate, @NextMonthDate)
		DELETE dbo.StraightSettingHistory WITH (ROWLOCK, UPDLOCK) WHERE MonthDate IN (@MonthDate, @NextMonthDate)
	END

	-- Archive settings
	BEGIN
		INSERT INTO dbo.TierSettingHistory (GroupId,TierId,MonthDate,MinAmount,MaxAmount,MinAM,MaxAM,Commission)
		SELECT GroupId,TierId,@MonthDate,MinAmount,MaxAmount,MinAM,MaxAM,Commission
		FROM dbo.TierSetting t WITH (NOLOCK)

		INSERT INTO dbo.TierSettingHistory (GroupId,TierId,MonthDate,MinAmount,MaxAmount,MinAM,MaxAM,Commission)
		SELECT GroupId,TierId,@NextMonthDate,MinAmount,MaxAmount,MinAM,MaxAM,Commission
		FROM dbo.TierSetting WITH (NOLOCK)

		INSERT INTO dbo.AffGroupHistory (AffId,MonthDate,GroupId,ParentAffId,AllParentAffId)
		SELECT AffId,@MonthDate,GroupId,ParentAffId,AllParentAffId
		FROM dbo.AffInfo WITH (NOLOCK)
		WHERE ISNULL(GroupId, 0) > 0

		INSERT INTO dbo.AffGroupHistory (AffId,MonthDate,GroupId,ParentAffId,AllParentAffId)
		SELECT AffId,@NextMonthDate,GroupId,ParentAffId,AllParentAffId
		FROM dbo.AffInfo WITH (NOLOCK)
		WHERE ISNULL(GroupId, 0) > 0

		INSERT INTO dbo.DeductionSettingHistory (GroupId,MonthDate,DeductionId,ProductId,GroupProductId,DeductedPercentage,DeductedAmount,IsDeductedPercent)
		SELECT GroupId,@MonthDate,DeductionId,ProductId,GroupProductId,DeductedPercentage,DeductedAmount,IsDeductedPercent
		FROM dbo.DeductionSetting ds WITH (NOLOCK)

		INSERT INTO dbo.DeductionSettingHistory (GroupId,MonthDate,DeductionId,ProductId,GroupProductId,DeductedPercentage,DeductedAmount,IsDeductedPercent)
		SELECT GroupId,@NextMonthDate,DeductionId,ProductId,GroupProductId,DeductedPercentage,DeductedAmount,IsDeductedPercent
		FROM dbo.DeductionSetting ds WITH (NOLOCK)

		INSERT INTO dbo.StraightSettingHistory (GroupId,MonthDate,ProductId,GroupProductId,DeductedPercentage,Commission)
		SELECT GroupId,@MonthDate,ProductId,GroupProductId,DeductedPercentage,Commission
		FROM dbo.StraightSetting ss WITH (NOLOCK)

		INSERT INTO dbo.StraightSettingHistory (GroupId,MonthDate,ProductId,GroupProductId,DeductedPercentage,Commission)
		SELECT GroupId,@NextMonthDate,ProductId,GroupProductId,DeductedPercentage,Commission
		FROM dbo.StraightSetting ss WITH (NOLOCK)
	END
END
GO