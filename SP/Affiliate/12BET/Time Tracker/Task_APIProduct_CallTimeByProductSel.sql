/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Task_APIProduct_CallTimeByProductSel]
	@ProductId	INT = -1,
	@TpType		INT = -1,
	@SubItem	VARCHAR(200) = '',
	@Currency	INT = NULL
AS
/*
	Created: 20190114@Walter
	DB: DBAFF12BET.Affiliate_12BET
	Task: Select The Last Time Call Service Successfully

	Revisions:
		- Created: 20190114@Walter: Initialize SP [RedmineID: #107594]
		- 20221117@Malcolm: Add TpType, SubItem [RedmineID: #180311]
*/
BEGIN
    SET NOCOUNT ON

	SELECT @ProductId = ISNULL(@ProductId, -1), @TpType = ISNULL(@TpType, -1), @SubItem = ISNULL(@SubItem, '')

    SELECT TOP 1 CallTime
    FROM dbo.APIProduct_TimeTracker WITH (NOLOCK)
    WHERE (ProductId = @ProductId OR (TpType = @TpType AND SubItem = @SubItem)) AND (Currency IS NULL OR Currency = @Currency) 
    ORDER BY Id DESC
END
GO