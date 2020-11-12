/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20201112@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Manually update data for Exchange WL & Comm
*/

USE Affiliate_12BET
GO

UPDATE dbo.DeductionSetting WITH (ROWLOCK)
SET DeductedPercentage = NextDeductedPercentage, GroupProductId = NextGroupProductId
WHERE DeductionId IN (13, 14)

UPDATE h WITH (ROWLOCK)
SET h.DeductedPercentage = s.NextDeductedPercentage, h.GroupProductId = s.NextGroupProductId
FROM dbo.DeductionSettingHistory h
	INNER JOIN DeductionSetting s WITH (NOLOCK)
		ON h.GroupId = s.GroupId AND h.DeductionId = s.DeductionId AND h.ProductId = s.ProductId
WHERE s.DeductionId IN (13, 14)
	AND h.MonthDate = '2020-11-30'