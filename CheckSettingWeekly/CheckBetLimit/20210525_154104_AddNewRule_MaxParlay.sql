/*
	Created: 20210525@winfred
	Task: Add new rule - Redmine: https://nexdev.net/issues/154104
	DB: DB054/CheckResultDB
*/

USE CheckResultDB
GO

DECLARE @ModifiedDate DATETIME = GETDATE()

INSERT INTO [Rule_Credit] (RuleID,RuleName,ModifiedDate)
VALUES 
(331,'Missing Parlay Max Payout setting', @ModifiedDate),
(332,'Single Match Parlay < 0', @ModifiedDate),	
(333,'Combo 2 < 0', @ModifiedDate),	
(334,'Combo 3 - 5 < 0', @ModifiedDate),	
(335,'Combo 6+ < 0', @ModifiedDate),	
(336,'Single Match Parlay > Upline Single Match Parlay ', @ModifiedDate),	
(337,'Combo 2 > Upline Combo 2 ', @ModifiedDate),	
(338,'Combo 3 - 5  > Upline Combo 3 - 5  ', @ModifiedDate),	
(339,'Combo 6+  > Upline Combo 6+  ', @ModifiedDate)	
GO

ALTER TABLE Credit_Supers ADD MaxPayout TINYINT NULLGOALTER TABLE [dbo].[Credit_Supers] ADD  CONSTRAINT [DF_Credit_Supers_MaxPayout]  DEFAULT ((0)) FOR [MaxPayout]GOINSERT INTO	dbo.vnDBA_CheckSetting_RunningScripts (ScriptName, VarKey, Threads, Command)VALUES	(N'Max Payout Credit', N'CheckSettingThreadCount', 3, N'SET NOCOUNT ON;DECLARE @CustId INT;WHILE 0 = 0BEGIN	SELECT @CustId = NULL;	UPDATE TOP(1) dbo.Credit_Supers	SET @CustId = CustId	, MaxPayout = 2	WHERE MaxPayout = 0;	IF @CustId IS NULL BREAK;	EXECUTE dbo.DBA_CheckMaxPayout_Credit @srecommend = @CustId, @SportType = 0, @RuleId = 0;	UPDATE dbo.Credit_Supers	SET MaxPayout = 1	WHERE CustId = @CustId	AND MaxPayout = 2;END;UPDATE	dbo.vnDBA_Service_Variables WITH (ROWLOCK)SET		VarValue	= ISNULL(CAST(VarValue AS SMALLINT), 0) - 1WHERE	VarKey = N''~~~'';');