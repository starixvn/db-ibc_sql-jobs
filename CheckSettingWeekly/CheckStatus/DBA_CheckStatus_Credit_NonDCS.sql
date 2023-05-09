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
		- 20191106@Winnie: 3rd party products - Remove InActive Products Phase 2  - [Redmine: #118699]
		- 20210419@Winfred: Remove check Gold Deluxe [redmine:#153659]
		- 20210727@Tina: remove check suspend status [RedmineID: #148600]
		- 20220110@Eden: Saba Casino use DCS Setting [RedmineID: #164280]
		- 20230306@Eden: Migrate NG and Keno to DCS structure [Redmine: #179711]
	Developer's Notes:
		- @Example:			NULL		- Explaination [DEFAULT]
		
*/
BEGIN
	SET NOCOUNT ON;

	EXECUTE dbo.DBA_CheckStatus_Credit @sportType=1, @bettype = 801, @DisableTable = 'CustInfo', @DisableColumnName = 'DisableSuperLive', @HiddenTable='', @HiddenColumnName = '',@SynTable='',@SynColumnName = '';

END;
GO
