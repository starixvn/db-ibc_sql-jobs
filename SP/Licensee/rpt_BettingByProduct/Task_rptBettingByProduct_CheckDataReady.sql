/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_rptBettingByProduct_CheckDataReady] 
AS
/*

	Created: @Danny
	Task:  check data of sum rptBettingByProduct done yet 
	
	Revisions: 
		- 20210827@Danny: Initial, call SP check before send mail House Net Income report [redmine: #151993]
		
*/

BEGIN 
	SET NOCOUNT ON 
	
	DECLARE @checkDate SMALLDATETIME, @IsDataYesterdayReady BIT = 0 
	DECLARE @yesterday SMALLDATETIME = DATEADD(DAY,-1,CAST(GETDATE() AS DATE))

	SELECT @checkDate = CAST(VValue AS DATE)
	FROM  bodb02.dbo.SystemSettings  WITH (NOLOCK)
	WHERE VName = 'MaxRptBettingByProduct'
 
	---Has data at sum table and all steps of the Job are done
	IF @checkDate = @yesterday
	BEGIN
		SELECT @IsDataYesterdayReady = 1
	END 
	ELSE
	BEGIN 
		SELECT @IsDataYesterdayReady = 0 
	END  
	
	----- Get info	
	SELECT @IsDataYesterdayReady AS IsDataYesterdayReady
END
GO
