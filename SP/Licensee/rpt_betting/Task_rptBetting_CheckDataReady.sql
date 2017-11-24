/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
USE [bodb_LicenseeReport]
GO

ALTER PROCEDURE [dbo].[Task_rptBetting_CheckDataReady] 
AS
/*

	Created: @Sophia
	Task:  check data of sum rpt_betting done yet 
	Revision: 
		- 20171124@Sophia: Initial, call SP check before send mail House Net Income report [redmine: #87247]

*/

BEGIN 
	SET NOCOUNT ON 
	
	DECLARE @MaxDate DATETIME, @IsDataYesterdayReady BIT = 0 

	SELECT @MaxDate = MAX(RptDate)
	FROM   bodb_LicenseeReport.dbo.rpt_Betting WITH (NOLOCK)	 
 
	---Has data at sum table and all steps of the Job are done
	IF @MaxDate >= DATEADD (DAY, -1, CONVERT(DATE, GETDATE()))
		AND (SELECT VValue
			FROM  bodb02.dbo.SystemSettings  WITH (NOLOCK)
			WHERE VName = 'IsStagingBettrans') = '0'
	BEGIN
		SELECT @IsDataYesterdayReady = 1
	END 
	ELSE
	BEGIN 
		SELECT @IsDataYesterdayReady = 0 
	END  

	SELECT @IsDataYesterdayReady AS IsDataYesterdayReady

END 
GO 
 
 