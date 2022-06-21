/*<info serverAlias="DBTP-bodb02" executers="bodbAdminNet" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Task_DetectBet_NotificationSelect]
AS
/*	
	Created by: Max
	Date : 20220525
	Task: Detect player exceeded the bet limit of the Agent's setting [Redmine: #170739]
	DB: DBTP/bodb02
	
	Revisions: 
		- 20220525@Max: Create SP [Redmine: #170739]
	
	Param's explanation:		
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @procName NVARCHAR(50), @IsTest BIT =  0, @IsSendTestCurrencyOnly BIT = 0,@serverName NVARCHAR(50)
	SET @procName = OBJECT_NAME(@@procid)
	SET @serverName = @@SERVERNAME
	
	IF @procName LIKE '%_xtest' OR @procName LIKE '%_xpre' OR @procName LIKE '%_UAT_' OR @serverName LIKE 'DEV%' OR @serverName LIKE 'TEST%' OR @serverName LIKE 'SIT%' 
	BEGIN
		SET @IsTest = 1
	END

	SET @IsSendTestCurrencyOnly = (SELECT ISNULL(c.ConfigValue,0) FROM dbo.CustMaxBetSetting_Config c WITH (NOLOCK) WHERE c.ConfigName = 'IsSendTestCurrencyOnly')
	
	SELECT c.username
		, c.site
		, s.SportName AS Product
		, bt.typenamee AS Game
		, t.MaxBet AS SettingValue
		, t.Stake AS ViolateStake
		, t.TransID AS RefNo
		, c.custid
		, CASE WHEN t.Remark = '1' THEN 'BuyBonus' ELSE t.Remark END AS Remark
	FROM dbo.CustMaxBet_Invalid t WITH (NOLOCK)
		INNER JOIN dbo.bettype bt WITH (NOLOCK) ON bt.typeid = t.BetType
		INNER JOIN dbo.Sports s with (NOLOCK) ON s.SportType = t.SportType
		INNER JOIN dbo.Customer c WITH (NOLOCK) ON c.custid = t.CustID
	WHERE ISNULL(t.IsSendLetstalk, 0) = 0
		AND 1 = CASE WHEN @IsTest = 0 AND c.currency NOT IN (20, 72) THEN 1
					WHEN @IsTest = 1 AND @IsSendTestCurrencyOnly = 1 AND c.currency IN (20, 72) THEN 1
					WHEN @IsTest = 1 AND @IsSendTestCurrencyOnly = 0 THEN 1 
				ELSE 0 END
END
GO

