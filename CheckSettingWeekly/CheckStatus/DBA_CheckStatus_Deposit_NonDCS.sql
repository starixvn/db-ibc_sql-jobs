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
		- 20191106@Winnie: 3rd party products - Remove InActive Products Phase 2  - [Redmine: #118699]
		
	Developer's Notes:
		- @Example:			NULL		- Explaination [DEFAULT]
		
*/
BEGIN
	SET NOCOUNT ON;
	
	
	
	EXECUTE dbo.DBA_CheckStatus_Deposit @sportType=204, @bettype = 18001, @DisableTable = 'CustInfo', @DisableColumnName = 'DisableColossusBet', @HiddenTable='CustInfo', @HiddenColumnName = 'HideColossusBet',@SynTable='',@SynColumnName = '';
	EXECUTE dbo.DBA_CheckStatus_Deposit @sportType=251, @bettype = 71, @DisableTable = 'CustInfo', @DisableColumnName = 'DisableCasino', @HiddenTable='', @HiddenColumnName = '',@SynTable='CustInfo',@SynColumnName = 'SyncCasino';
	
	EXECUTE dbo.DBA_CheckStatus_Deposit @sportType=1, @bettype = 801, @DisableTable = 'CustInfo', @DisableColumnName = 'DisableSuperLive', @HiddenTable='', @HiddenColumnName = '',@SynTable='',@SynColumnName = '';
	EXECUTE dbo.DBA_CheckStatus_Deposit @sportType=202, @bettype = 1501, @DisableTable = '', @DisableColumnName = '', @HiddenTable='CustInfo', @HiddenColumnName = 'HideKeno',@SynTable='',@SynColumnName = '';

	EXECUTE dbo.DBA_CheckStatus_Keno_Deposit @Sporttype = 202,@Bettype = 1, @DisableTable = 'CustGameType', @DisableColumnName = 'IsDisabled';

END;
GO
/*<info serverAlias="DBCHECK-CheckResultDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/