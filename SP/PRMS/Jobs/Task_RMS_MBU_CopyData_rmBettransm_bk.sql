/*<info serverAlias="DBRMS-bodb_RMS" isFunction="0" isNested="1"></info>*/
CREATE PROCEDURE [dbo].[Task_RMS_MBU_CopyData_rmBettransm_bk]
	@winlostdate SMALLDATETIME
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		VARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20210319@Danny
	DB: DBRMS-bodb_RMS
	Task: RMS - Copy data from bettransm_bk to rmBettransm_bk

	Revisions:
		- 20210319@Danny: Initialize SP [RedmineID: #151319]
*/

BEGIN
	SET NOCOUNT ON

	IF @@ROWCOUNT = 0
		RETURN
	BEGIN TRY
		INSERT INTO dbo.rmBettransm_bk
		(
			transid,
			odds,
			stake,
			statusID,
			refno,
			winlostdate,
			matchid 
		)
		SELECT 
			transid,
			odds,
			stake,
			statusID,
			refno,
			winlostdate,
			matchid 
		FROM DBARC.bodb_archive.dbo.bettransm r WITH (NOLOCK, INDEX = IX_winlostdate)
		WHERE r.winlostdate = @winlostdate


		INSERT INTO dbo.rmMatch_bk
		(
			matchid,
			leagueid,
			eventdate,
			ParentID,
			ChildMatchType
		)
		SELECT 
			matchid,
			leagueid,
			eventdate,
			ParentID,
			ChildMatchType
		FROM DBARC.bodb_archive.dbo.match_bk r WITH (NOLOCK, INDEX = IX_eventdate)
		WHERE r.eventdate = @winlostdate 

	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 101, @ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH
END
GO
