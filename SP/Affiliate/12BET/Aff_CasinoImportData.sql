/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_CasinoImportData]
	@AdminID		INT,
	@ImportDate		SMALLDATETIME,
	@XmlData		XML,
	@IsReplaceData	BIT = 0,
	@IsForceUpdate	BIT = 0,
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(500) = '' OUTPUT
AS

/*
	Task: Import Playtech Casino transactions
	Author: Johnny@20110801
	DB: DBAFF12BET.Affiliate_12BET
	
	Revisions:
		- 20120409@Johnny:
			+ link: http://ccs.nexcel.vn/viewtopic.php?f=4&t=6320
			+ Desc: import monthly Casino data in excel file to Affiliate_12BET DB when a month is completed to calculate Casino Commission
		- 20121211@Johnny: only import casino data for affiliate has been approved Casino before the date import data
		- 20150907@Bobby.Nguyen:  Hotfix#42274 - Add/check data constraINT of removal members
		- 20171010@Percy: Upgrade service job [RedmineID: #84602]
		- 20171129@Percy: Add PShare, PWin [RedmineID: #87342]
		- 20180529@Percy: Remove temporarily monthy checking to support re-import data [RedmineID: #94792]
		- 20180601@Percy: Add flag for manually force update data [RedmineID: #94792]
		- 20180801@Percy: Add new table rptMemberDaily [RedmineID: #87923]
		- 20191130@Percy: Import XML Data into Queue [RedmineID: #124784]
*/

BEGIN
	SET NOCOUNT ON

	SELECT @ErrCode = 0, @ErrMsg = ''

	BEGIN TRY
		INSERT INTO dbo.APIProduct_ImportQueue (ProductId,XmlData,CheckInTime,JobType)
		VALUES (3, @XmlData, GETDATE(), 0)
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 10000, @ErrMsg = 'Import xml failed!'
		RETURN
	END CATCH
END
GO