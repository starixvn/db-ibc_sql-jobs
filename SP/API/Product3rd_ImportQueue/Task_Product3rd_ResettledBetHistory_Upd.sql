/*<info serverAlias="DBPTCS-bodb_PlaytechCS,DBBAL-bodb_PlaytechCS" executers="bodbLicenseeNet" viewers="" isFunction="0" isNested="1"></info>*/
USE [bodb_PlaytechCS]
GO

ALTER PROCEDURE [dbo].[Task_Product3rd_ResettledBetHistory_Upd]
	@ProductId	INT = 31,
	@Ids		VARCHAR(MAX) = '',
	@Status		VARCHAR(20) = NULL,
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		VARCHAR(2000) = '' OUTPUT
AS

/*
	Created by Percy
	Date: 2017-11-17
	DB: DBPTCS.bodb_PlaytechCS,DBBAL-bodb_PlaytechCS
	Task:

	Revisions:
		- 20171117@Percy: Initialize SP [RedmineID: #86477]
		- 20210816@Sophia: add DBBAL [Redmine: #154300]
*/

BEGIN
	SET NOCOUNT ON

	IF ISNULL(@Ids, '') = '' OR ISNULL(@Status, '') = ''
		RETURN

	IF @Status NOT IN ('running', 'Completed')
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'Invalid status'
		RETURN
	END

	DECLARE @Id_List TABLE (Id BIGINT)

	BEGIN TRY
		INSERT INTO @Id_List (Id)
		SELECT DISTINCT CONVERT(BIGINT, val) FROM bodb02.dbo.strSplit(@Ids, ',')

		IF @Status = 'running'
		BEGIN
			UPDATE h
			SET h.Status = @Status
			FROM dbo.Product3rd_ResettledBetHistory h WITH (ROWLOCK, UPDLOCK)
				INNER JOIN @Id_List l ON h.Id = l.Id
			WHERE h.FinishedTime IS NULL
				AND h.Status = 'waiting'
				AND h.ProductId = @ProductId
		END
		ELSE IF @Status = 'Completed'
		BEGIN
			UPDATE h
			SET h.Status = @Status, h.FinishedTime = GETDATE()
			FROM dbo.Product3rd_ResettledBetHistory h WITH (ROWLOCK, UPDLOCK)
				INNER JOIN @Id_List l ON h.Id = l.Id
			WHERE h.FinishedTime IS NULL
				AND h.Status = 'running'
				AND h.ProductId = @ProductId
		END
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 100, @ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH
END
GO