/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Aff_Settings_Archive]
	@MonthDate SMALLDATETIME
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Affiliate 12BET - Job - Archive Setting

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
		- 20201112@Percy: Add Setting for Exchange WL & Comm [RedmineID: #145297]
		- 20231005@Bobby: Implement Bonus & FDM Setting [RedmineId : #191139]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @NextMonthDate SMALLDATETIME

	SELECT  @MonthDate		= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate) + 1, 0))
	SELECT  @NextMonthDate	= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate) + 2, 0))

	-- Current month
	BEGIN
		IF (
			EXISTS (SELECT 1 FROM dbo.CommGroupHistory WITH (NOLOCK) WHERE MonthDate IN (@NextMonthDate))
			OR EXISTS (SELECT 1 FROM dbo.TierSettingHistory WITH (NOLOCK) WHERE MonthDate IN (@NextMonthDate))
			OR EXISTS (SELECT 1 FROM dbo.AffGroupHistory WITH (NOLOCK) WHERE MonthDate IN (@NextMonthDate))
			OR EXISTS (SELECT 1 FROM dbo.DeductionSettingHistory WITH (NOLOCK) WHERE MonthDate IN (@NextMonthDate))
			OR EXISTS (SELECT 1 FROM dbo.FDMTierSettingHistory WITH (NOLOCK) WHERE MonthDate IN (@NextMonthDate))
		)
		BEGIN
			DELETE dbo.CommGroupHistory WITH (ROWLOCK, UPDLOCK) WHERE MonthDate IN (@NextMonthDate)
			DELETE dbo.TierSettingHistory WITH (ROWLOCK, UPDLOCK) WHERE MonthDate IN (@NextMonthDate)
			DELETE dbo.AffGroupHistory WITH (ROWLOCK, UPDLOCK) WHERE MonthDate IN (@NextMonthDate)
			DELETE dbo.DeductionSettingHistory WITH (ROWLOCK, UPDLOCK) WHERE MonthDate IN (@NextMonthDate)
			DELETE dbo.FDMTierSettingHistory WITH (ROWLOCK, UPDLOCK) WHERE MonthDate IN (@NextMonthDate)
		END

		-- Archive settings
		BEGIN

			INSERT INTO dbo.CommGroupHistory (GroupID,MonthDate,GroupName,CreatedDate,Creator,IsDeleted,Description,QMTurnover,IsApplyBonus)
			SELECT GroupID,@NextMonthDate,GroupName,CreatedDate,Creator,IsDeleted,Description,QMTurnover,IsApplyBonus
			FROM dbo.CommGroup WITH (NOLOCK)

			INSERT INTO dbo.TierSettingHistory (GroupID,TierID,MonthDate,MinAmount,MaxAmount,MinQM,MaxQM,Commission)
			SELECT GroupID,TierID,@NextMonthDate,MinAmount,MaxAmount,MinQM,MaxQM,Commission
			FROM dbo.TierSetting WITH (NOLOCK)

			INSERT INTO dbo.AffGroupHistory (AffID,MonthDate,GroupID)
			SELECT AffID,@NextMonthDate,GroupID
			FROM dbo.AffInfo WITH (NOLOCK)
			WHERE ISNULL(GroupID, 0) > 0

			INSERT INTO dbo.DeductionSettingHistory (GroupID,MonthDate,DeductionID,DeductedPercentage,ProductId,GroupProductId)
			SELECT GroupID,@NextMonthDate,DeductionID,NextDeductedPercentage,ProductId,NextGroupProductId
			FROM dbo.DeductionSetting ds WITH (NOLOCK)

			-- FDM Bonus Setting
			INSERT INTO dbo.FDMTierSettingHistory (GroupID,TierID,MonthDate,MinAmount,MaxAmount,MinFDM,MaxFDM,Commission,LimitAmount)
			SELECT GroupID,TierID,@NextMonthDate,MinAmount,MaxAmount,MinFDM,MaxFDM,Commission,LimitAmount
			FROM dbo.FDMTierSetting WITH (NOLOCK)

			-- Apply next value
			BEGIN
				UPDATE dbo.DeductionSetting WITH(ROWLOCK, UPDLOCK)
				SET DeductedPercentage = NextDeductedPercentage, GroupProductId = NextGroupProductId
				WHERE DeductedPercentage <> NextDeductedPercentage
					OR GroupProductId <> NextGroupProductId

				UPDATE dbo.CommGroup WITH (ROWLOCK, UPDLOCK)
				SET QMTurnover = NextQMTurnover
				WHERE QMTurnover <> NextQMTurnover
			END
		END
	END
END
GO