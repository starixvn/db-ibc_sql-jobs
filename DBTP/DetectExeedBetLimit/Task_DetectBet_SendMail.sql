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

	CREATE TABLE #tmp_TransId (TransId BIGINT, Username NVARCHAR(100), site VARCHAR(100), Product VARCHAR(100), stake VARCHAR(50), MaxBet VARCHAR(50), game VARCHAR(100), Remark VARCHAR(100))

	DECLARE @procName NVARCHAR(50)
		, @IsTest BIT =  0
		, @IsSendTestCurrencyOnly BIT = 0
		, @serverName NVARCHAR(50)
		, @recipients VARCHAR(2000) = NULL

	SET @procName = OBJECT_NAME(@@procid)
	SET @serverName = @@SERVERNAME
	
	IF @procName LIKE '%_xtest' OR @procName LIKE '%_xpre' OR @procName LIKE '%_UAT_' OR @serverName LIKE 'DEV%' OR @serverName LIKE 'TEST%' OR @serverName LIKE 'SIT%'
	BEGIN
		SET @IsTest = 1
	END

	SET @IsSendTestCurrencyOnly = (SELECT ISNULL(c.ConfigValue,0) FROM dbo.CustMaxBetSetting_Config c WITH (NOLOCK) WHERE c.ConfigName = 'IsSendTestCurrencyOnly')
	
	INSERT INTO #tmp_TransId (Username, site, Product, game, MaxBet, stake, TransId, Remark)
	SELECT c.username
		, c.site
		, s.SportName AS Product
		, bt.typenamee AS Game
		, CASE WHEN t.MaxBet IS NULL THEN 'Not assigned' ELSE CONVERT(VARCHAR(50), t.MaxBet) END
		, CONVERT(VARCHAR(50), t.stake)
		, t.TransID AS RefNo
		, CASE WHEN t.Remark = '1' THEN 'BuyBonus' ELSE t.Remark END AS Remark
	FROM dbo.CustMaxBet_Invalid t WITH (NOLOCK)
		INNER JOIN dbo.bettype bt WITH (NOLOCK) ON bt.typeid = t.BetType
		INNER JOIN dbo.Sports s with (NOLOCK) ON s.SportType = t.SportType
		INNER JOIN dbo.Customer c WITH (NOLOCK) ON c.custid = t.CustID
	WHERE ISNULL(t.IsSendEmail, 0) = 0
		AND 1 = CASE WHEN @IsTest = 0 AND c.currency NOT IN (20, 72) THEN 1
					WHEN @IsTest = 1 AND @IsSendTestCurrencyOnly = 1 AND c.currency IN (20, 72) THEN 1
					WHEN @IsTest = 1 AND @IsSendTestCurrencyOnly = 0 THEN 1 
				ELSE 0 END

	IF EXISTS (SELECT TOP(1) 1 FROM #tmp_TransId)
	BEGIN
		DECLARE	@email_body		NVARCHAR(MAX)
			,	@subject		NVARCHAR(200)
			;
	
		-- Build html
		SELECT	@subject	= N'Violate Max Bet Limit Setting'
			,	@email_body = (
					SELECT	
						[@style]		= N'width: 100%;'
						, (
							SELECT	NULL, [p]	= N'Dear users,'
								,	NULL, [p]	= N'This is the auto-mail notification about the Violate Max Bet Limit Setting cases.'
								,	NULL, [p]	= N'Kindly check the following table for more details.'
								,	NULL, [p]	= N'Thanks & Best Regards,'
								,	NULL, [p]	= N'Starix IT'
							FOR XML PATH ('div')
							,	TYPE
						)
						,	(
								SELECT	[@border]		= 1
									,	[@cellpadding]	= 5
									,	[@width]		= N'85%'
									,	[@style]		= N'margin:0 auto;white-space:nowrap;border-collapse:collapse;'
									,	(
										SELECT	[@style] = N'background-color:#FFFF00'
											, [th/@colspan]	= N'9'
											, [th]	= N'Violate Max Bet Limit Setting - ' + CONVERT(NVARCHAR, GETDATE(), 106)
										FOR XML PATH ('tr')
										,	TYPE
										)
									,	(
										SELECT	[@style] = N'background-color:#B4EEB4'
											,	NULL, [th]	= N'#'
											,	NULL, [th]	= N'Username'
											,	NULL, [th]	= N'Site'
											,	NULL, [th]	= N'Product'
											,	NULL, [th]	= N'Game'
											,	NULL, [th]	= N'Setting value'
											,	NULL, [th]	= N'Violate Stake'
											,	NULL, [th]	= N'RefNo'
											,	NULL, [th]	= N'Remark'
										FOR XML PATH ('tr')
										,	TYPE
										)
									,	(
										SELECT	NULL, [td]	= ROW_NUMBER() OVER(ORDER BY t.Username)
											,	NULL, [td]	= t.Username
											,	NULL, [td]	= t.site
											,	NULL, [td]	= t.Product
											,	NULL, [td]	= t.game
											,	NULL, [td]	= t.MaxBet
											,	NULL, [td]	= t.stake
											,	NULL, [td]	= CONVERT(VARCHAR(50), t.TransId)
											,	NULL, [td]	= ISNULL(t.Remark, '')
										FROM	#tmp_TransId AS t 
										FOR XML PATH ('tr')
										,	TYPE
										)
								FOR XML PATH ('table')
								,	TYPE
							)
						, (
							SELECT	[@style] = N'font-style:italic;'
								,	NULL, [p]	= N'----------------------------------------------------------------------'
								,	NULL, [p]	= N'This email is confidential. '
								,	NULL, [p]	= N'If you are not the addressee you may not copy, forward, disclose or use any part of it. '
								,	NULL, [p]	= N'If you have received this message in error, please delete it from your system. '
								,	NULL, [p]	= N'This is an auto-generated email, please do not reply.'
							FOR XML PATH ('div')
							,	TYPE
						)
					FOR XML PATH ('body')
					,	ROOT ('html')
				);

		EXECUTE	msdb.dbo.sp_send_dbmail
					@profile_name			= DEFAULT
				,	@recipients				= 'max.tran@starixvn.com;benji.duong@starixvn.com;roshan.nguyen@starixvn.com;jenny.phan@starixvn.com'
				,	@copy_recipients		= ''
				,	@blind_copy_recipients	= ''
				,	@subject				= @subject
				,	@body					= @email_body
				,	@body_format			= 'HTML'
				;
	
		--Update
		UPDATE t SET t.IsSendEmailTest = 1, t.IsSendEmail = 1
		FROM dbo.CustMaxBet_Invalid t WITH (ROWLOCK, UPDLOCK)
			INNER JOIN #tmp_TransId tmp ON tmp.transid = t.TransID
	END

	DROP TABLE #tmp_TransId
	
END;
GO
