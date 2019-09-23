/*<info serverAlias="DBCHECK-CheckResultDB" executers="" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE	[dbo].[DBA_CheckStatus_Credit_NonDCS]
AS
/*
	Creator:	20180328@Billy
	Task:		Wraper of checking status for credit users - [Redmine: #00000]
	Database:	DBCHECK.CheckResultDB
	
	Revisions:
		- 20180328@Billy:	Initial - [Redmine: #00000]
		- 20190610@Johnson: add step check suspend status [redmine:#105587]
	Developer's Notes:
		- @Example:			NULL		- Explaination [DEFAULT]
		
*/
BEGIN
	SET NOCOUNT ON;
	
	EXECUTE dbo.DBA_CheckStatus_Credit @sportType=255, @bettype = 1700, @DisableTable = 'CustInfo', @DisableColumnName = 'DisableGoldDeluxe', @HiddenTable='CustInfo', @HiddenColumnName = 'HideGoldDeluxe',@SynTable='',@SynColumnName = '';
	EXECUTE dbo.DBA_CheckStatus_Credit @sportType=203, @bettype = 2001, @DisableTable = 'CustInfo', @DisableColumnName = 'DisableMicrogameLC', @HiddenTable='', @HiddenColumnName = '',@SynTable='',@SynColumnName = '';
	EXECUTE dbo.DBA_CheckStatus_Credit @sportType=205, @bettype = 2008, @DisableTable = 'CustInfo', @DisableColumnName = 'DisableMicrogameRNG', @HiddenTable='', @HiddenColumnName = '',@SynTable='',@SynColumnName = '';
	EXECUTE dbo.DBA_CheckStatus_Credit @sportType=204, @bettype = 18001, @DisableTable = 'CustInfo', @DisableColumnName = 'DisableColossusBet', @HiddenTable='CustInfo', @HiddenColumnName = 'HideColossusBet',@SynTable='',@SynColumnName = '';
	EXECUTE dbo.DBA_CheckStatus_Credit @sportType=251, @bettype = 71, @DisableTable = 'CustInfo', @DisableColumnName = 'DisableCasino', @HiddenTable='', @HiddenColumnName = '',@SynTable='CustInfo',@SynColumnName = 'SyncCasino';

	EXECUTE dbo.DBA_CheckStatus_Credit @sportType=1, @bettype = 801, @DisableTable = 'CustInfo', @DisableColumnName = 'DisableSuperLive', @HiddenTable='', @HiddenColumnName = '',@SynTable='',@SynColumnName = '';
	
	EXECUTE dbo.DBA_CheckStatus_Keno_Credit @Sporttype = 202,@Bettype = 1, @DisableTable = 'CustGameType', @DisableColumnName = 'IsDisabled';
	EXECUTE dbo.DBA_CheckStatus_Keno_Credit @Sporttype = 202,@Bettype = 3, @DisableTable = 'CustGameType', @DisableColumnName = 'IsDisabled';
	EXECUTE dbo.DBA_CheckStatus_Keno_Credit @Sporttype = 202,@Bettype = 4, @DisableTable = 'CustGameType', @DisableColumnName = 'IsDisabled';
	EXECUTE dbo.DBA_CheckStatus_Keno_Credit @Sporttype = 202,@Bettype = 5, @DisableTable = 'CustGameType', @DisableColumnName = 'IsDisabled';
	EXECUTE dbo.DBA_CheckStatus_Keno_Credit @Sporttype = 202,@Bettype = 8, @DisableTable = 'CustGameType', @DisableColumnName = 'IsDisabled';
	EXECUTE dbo.DBA_CheckStatus_Keno_Credit @Sporttype = 202,@Bettype = 11, @DisableTable = 'CustGameType', @DisableColumnName = 'IsDisabled';
	EXECUTE dbo.DBA_CheckStatus_Keno_Credit @Sporttype = 202,@Bettype = 13, @DisableTable = 'CustGameType', @DisableColumnName = 'IsDisabled';
	EXECUTE dbo.DBA_CheckStatus_Keno_Credit @Sporttype = 202,@Bettype = 14, @DisableTable = 'CustGameType', @DisableColumnName = 'IsDisabled';
	EXECUTE dbo.DBA_CheckStatus_Keno_Credit @Sporttype = 202,@Bettype = 15, @DisableTable = 'CustGameType', @DisableColumnName = 'IsDisabled';
	EXECUTE dbo.DBA_CheckStatus_Keno_Credit @Sporttype = 202,@Bettype = 16, @DisableTable = 'CustGameType', @DisableColumnName = 'IsDisabled';

	EXECUTE dbo.DBA_CheckStatus_Credit @sportType=202, @bettype = 1501, @DisableTable = '', @DisableColumnName = '', @HiddenTable='CustInfo', @HiddenColumnName = 'HideKeno',@SynTable='',@SynColumnName = '';
	
	EXECUTE dbo.DBA_CheckSuspendInfoStatus_Credit
END;
GO
