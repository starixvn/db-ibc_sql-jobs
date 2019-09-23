SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE	[dbo].[DBA_CheckStatus_Deposit_NonDCS]
AS
/*
	Creator:	20180328@Billy
	Task:		Wraper of checking status for deposit users - [Redmine: #00000]
	Database:	DBCHECK.CheckResultDB
	
	Revisions:
		- 20180328@Billy:	Initial - [Redmine: #00000]
		
	Developer's Notes:
		- @Example:			NULL		- Explaination [DEFAULT]
		
*/
BEGIN
	SET NOCOUNT ON;
	
	EXECUTE dbo.DBA_CheckStatus_Deposit @sportType=203, @bettype = 2001, @DisableTable = 'CustInfo', @DisableColumnName = 'DisableMicrogameLC', @HiddenTable='', @HiddenColumnName = '',@SynTable='',@SynColumnName = '';
	EXECUTE dbo.DBA_CheckStatus_Deposit @sportType=205, @bettype = 2008, @DisableTable = 'CustInfo', @DisableColumnName = 'DisableMicrogameRNG', @HiddenTable='', @HiddenColumnName = '',@SynTable='',@SynColumnName = '';
	EXECUTE dbo.DBA_CheckStatus_Deposit @sportType=204, @bettype = 18001, @DisableTable = 'CustInfo', @DisableColumnName = 'DisableColossusBet', @HiddenTable='CustInfo', @HiddenColumnName = 'HideColossusBet',@SynTable='',@SynColumnName = '';
	EXECUTE dbo.DBA_CheckStatus_Deposit @sportType=251, @bettype = 71, @DisableTable = 'CustInfo', @DisableColumnName = 'DisableCasino', @HiddenTable='', @HiddenColumnName = '',@SynTable='CustInfo',@SynColumnName = 'SyncCasino';
	
	EXECUTE dbo.DBA_CheckStatus_Deposit @sportType=1, @bettype = 801, @DisableTable = 'CustInfo', @DisableColumnName = 'DisableSuperLive', @HiddenTable='', @HiddenColumnName = '',@SynTable='',@SynColumnName = '';
	EXECUTE dbo.DBA_CheckStatus_Deposit @sportType=202, @bettype = 1501, @DisableTable = '', @DisableColumnName = '', @HiddenTable='CustInfo', @HiddenColumnName = 'HideKeno',@SynTable='',@SynColumnName = '';

	EXECUTE dbo.DBA_CheckStatus_Keno_Deposit @Sporttype = 202,@Bettype = 1, @DisableTable = 'CustGameType', @DisableColumnName = 'IsDisabled';
	EXECUTE dbo.DBA_CheckStatus_Keno_Deposit @Sporttype = 202,@Bettype = 3, @DisableTable = 'CustGameType', @DisableColumnName = 'IsDisabled';
	EXECUTE dbo.DBA_CheckStatus_Keno_Deposit @Sporttype = 202,@Bettype = 4, @DisableTable = 'CustGameType', @DisableColumnName = 'IsDisabled';
	EXECUTE dbo.DBA_CheckStatus_Keno_Deposit @Sporttype = 202,@Bettype = 5, @DisableTable = 'CustGameType', @DisableColumnName = 'IsDisabled';
	EXECUTE dbo.DBA_CheckStatus_Keno_Deposit @Sporttype = 202,@Bettype = 8, @DisableTable = 'CustGameType', @DisableColumnName = 'IsDisabled';
	EXECUTE dbo.DBA_CheckStatus_Keno_Deposit @Sporttype = 202,@Bettype = 11, @DisableTable = 'CustGameType', @DisableColumnName = 'IsDisabled';
	EXECUTE dbo.DBA_CheckStatus_Keno_Deposit @Sporttype = 202,@Bettype = 13, @DisableTable = 'CustGameType', @DisableColumnName = 'IsDisabled';
	EXECUTE dbo.DBA_CheckStatus_Keno_Deposit @Sporttype = 202,@Bettype = 14, @DisableTable = 'CustGameType', @DisableColumnName = 'IsDisabled';
	EXECUTE dbo.DBA_CheckStatus_Keno_Deposit @Sporttype = 202,@Bettype = 15, @DisableTable = 'CustGameType', @DisableColumnName = 'IsDisabled';
	EXECUTE dbo.DBA_CheckStatus_Keno_Deposit @Sporttype = 202,@Bettype = 16, @DisableTable = 'CustGameType', @DisableColumnName = 'IsDisabled';

END;
GO
/*<info serverAlias="DBCHECK-CheckResultDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/