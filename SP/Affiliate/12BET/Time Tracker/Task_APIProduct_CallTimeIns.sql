/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Task_APIProduct_CallTimeIns]
	@ProductId	INT,
	@Currency	INT = NULL,
    @CallTime   DATETIME,
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS
/*
	Created: 20190114@Walter
	DB: DBAFF12BET.Affiliate_12BET
	Task: Insert The Last Time Call Service Successfully

	Revisions:
		- Created: 20190114@Walter: Initialize SP [RedmineID: #107594]
*/
BEGIN
    SET NOCOUNT ON

    INSERT INTO dbo.APIProduct_TimeTracker (ProductId, Currency, CallTime)
    VALUES (@ProductId, @Currency, @CallTime)

    IF @@ERROR <> 0
	BEGIN
		SELECT @ErrCode = @@ERROR, @ErrMsg = 'Insert failed'
		RETURN
	END
END
GO