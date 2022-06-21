/*<info serverAlias="DBAGE-bodb02,DBEXT-bodb02" executers="bodbDownlineNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_WLMonitored_Service_BettypeOffered]
	@Model VARCHAR(20) = 'Credit'
AS
/*	Creator: 20220617@Kathy
	Task: get detail ticket
	DB: DBAGE/BODB02
	
	Revisions:	
		- 20220617@Kathy: get detail ticket [Redmine:#170467]

	Param's Explanation:
		@Model: Credit/Deposit
		 
*/
BEGIN
	SET NOCOUNT ON

	SELECT	DISTINCT bettype
	FROM	dbo.SportBettypeMatrix WITH(NOLOCK)
	WHERE	1 = CASE 
					WHEN @Model = 'Credit' AND ProductID = 1 THEN 1
					WHEN @Model = 'Deposit' AND ProductID IN (1,63,69) THEN 1
					ELSE 0
				END
END
GO

