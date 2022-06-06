/*<info serverAlias="DBTP-bodb02" executers="bodbAdminNet" isFunction="0"></info>*/
ALTER PROCEDURE	[dbo].[Task_DetectBet_SendMail]
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
BEGIN;
	SET NOCOUNT ON;

	CREATE TABLE #tmp_TransId (TransId BIGINT, Username NVARCHAR(100), site VARCHAR(100), Product VARCHAR(100), stake MONEY, MaxBet Money, game VARCHAR(100))

	DECLARE @procName NVARCHAR(50), @IsTest BIT =  0, @IsSendTestCurrencyOnly BIT = 0
	SET @procName = OBJECT_NAME(@@procid)
	
	IF @procName LIKE '%_xtest' OR @procName LIKE '%_xpre' OR @procName LIKE '%_UAT_'
	BEGIN
		SET @IsTest = 1
	END

	SET @IsSendTestCurrencyOnly = (SELECT ISNULL(c.ConfigValue,0) FROM dbo.CustMaxBetSetting_Config c WITH (NOLOCK) WHERE c.ConfigName = 'IsSendTestCurrencyOnly')
	
	INSERT INTO #tmp_TransId (Username, site, Product, game, MaxBet, stake, TransId)
	SELECT c.username, c.site, s.SportName AS Product, bt.typenamee AS Game, t.MaxBet AS SettingValue, t.Stake AS ViolateStake, t.TransID AS RefNo
	FROM dbo.CustMaxBet_Invalid t WITH (NOLOCK)
		INNER JOIN dbo.bettype bt WITH (NOLOCK) ON bt.typeid = t.BetType
		INNER JOIN dbo.Sports s with (NOLOCK) ON s.SportType = t.SportType
		INNER JOIN dbo.Customer c WITH (NOLOCK) ON c.custid = t.CustID
	WHERE ISNULL(t.IsSendEmail, 0) = 0
		AND 1 = CASE WHEN @IsTest = 0 AND c.currency NOT IN (20, 72) THEN 1
					WHEN @IsTest = 1 AND @IsSendTestCurrencyOnly = 1 AND c.currency IN (20, 72) THEN 1
					WHEN @IsTest = 1 AND @IsSendTestCurrencyOnly = 0 THEN 1 
				ELSE 0 END

	DECLARE	@email_body		NVARCHAR(MAX)
		,	@subject		NVARCHAR(200)
		;
	
	-- Build html
	SELECT	@subject	= N'Violate Max Bet Limit Setting'
		,	@email_body = (
				SELECT	
						[@style]		= N'width: 100%;'
					,	[h1/@align]		= N'center'
					,	[h1]			= N'Violate Max Bet Limit Setting - ' + CONVERT(NVARCHAR, GETDATE(), 120)
					,	[div/@align]	= N'center'
					,	[div/@style]	= N'\
background-color:' + s.color + N';\
width:80%;color:white;text-align:center;margin:0 auto;padding:20px;font-size:30px;\
'
					,	[br]			= N''
					,	(
						SELECT	[@border]		= 1
							,	[@cellpadding]	= 5
							,	[@width]		= N'95%'
							,	[@style]		= N'margin:0 auto;white-space:nowrap;border-collapse:collapse;'
							,	(
								SELECT	NULL, [th]	= N'#'
									,	NULL, [th]	= N'Username'
									,	NULL, [th]	= N'Site'
									,	NULL, [th]	= N'Product'
									,	NULL, [th]	= N'Game'
									,	NULL, [th]	= N'Setting value'
									,	NULL, [th]	= N'Violate Stake'
									,	NULL, [th]	= N'RefNo'
								FOR XML PATH ('tr')
								,	TYPE
								)
							,	(
								SELECT	NULL, [td]	= '1'
									,	NULL, [td]	= t.Username
									,	NULL, [td]	= t.site
									,	NULL, [td]	= t.Product
									,	NULL, [td]	= t.game
									,	NULL, [td]	= CONVERT(VARCHAR(50), t.MaxBet)
									,	NULL, [td]	= CONVERT(VARCHAR(50), t.stake)
									,	NULL, [td]	= CONVERT(VARCHAR(50), t.TransId)
								FROM			#tmp_TransId AS t 
								FOR XML PATH ('tr')
								,	TYPE
								)
						FOR XML PATH ('table')
						,	TYPE
						)
				FROM	(
					SELECT	[color]		= N'red'
				) AS s
				FOR XML PATH ('body')
				,	ROOT ('html')
			);

	EXECUTE	msdb.dbo.sp_send_dbmail
				@profile_name			= DEFAULT
			,	@recipients				= 'max.tran@starixvn.com;benji.duong@starixvn.com'
			,	@copy_recipients		= ''
			,	@blind_copy_recipients	= ''
			,	@subject				= @subject
			,	@body					= @email_body
			,	@body_format			= 'HTML'
			;
	
	--Update
	UPDATE t SET t.IsSendLettalk = 1, t.IsSendLettalkTest = 1
	FROM dbo.CustMaxBet_Invalid t WITH (ROWLOCK, UPDLOCK)
		INNER JOIN #tmp_TransId tmp ON tmp.transid = t.TransID

	DROP TABLE #tmp_TransId
	
END;
GO
