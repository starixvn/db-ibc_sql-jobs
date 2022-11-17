/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Task_APIProduct_CallTimeIns]
	@ProductId	INT = -1,
	@TpType		INT = -1,
	@SubItem	VARCHAR(200) = '',
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
		- 20221117@Malcolm: Add TpType, SubItem [RedmineID: #180311]
*/
BEGIN
    SET NOCOUNT ON

	SELECT @ProductId = ISNULL(@ProductId, -1), @TpType = ISNULL(@TpType, -1), @SubItem = ISNULL(@SubItem, '')

    INSERT INTO dbo.APIProduct_TimeTracker (ProductId, TpType, SubItem, Currency, CallTime)
    VALUES (@ProductId, @TpType, @SubItem, @Currency, @CallTime)

    IF @@ERROR <> 0
	BEGIN
		SELECT @ErrCode = @@ERROR, @ErrMsg = 'Insert failed'
		RETURN
	END
END
GO