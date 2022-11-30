/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Task_NewAPIProduct_ImportQueue]
	@JsonData	NVARCHAR(MAX),
	@JobType	TINYINT = 0,
	@TpType 	INT,
	@SubItem	VARCHAR(200),
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20221118@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Import Data Job - Import Json data

	Revisions:
		- 20221118@Malcolm: Initialize SP [RedmineID: #180311]

	Param's Explanation:
		- JobType:
			0: Data for import
			1: Data for check sum
*/

BEGIN
	SET NOCOUNT ON
	
	BEGIN TRY

		INSERT INTO dbo.APIProduct_ImportQueue (ProductId, JsonData, JobType, TpType, SubItem, CheckInTime)
		VALUES (-1, @JsonData, @JobType, @TpType, @SubItem, GETDATE())

		SELECT @ErrCode = 0, @ErrMsg = ''
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 101, @ErrMsg = ERROR_MESSAGE()

		RETURN
	END CATCH
END
GO