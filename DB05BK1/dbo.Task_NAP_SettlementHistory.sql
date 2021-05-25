/*<info serverAlias="DBBAH-bodb02" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Task_NAP_SettlementHistory] 
	@Date DATE
AS
/*
	Created by: 20210520@Kathy
	Task: Delete history  [Redmine:#154732]
	DB: DBBAH/bodb02
	
	Revisions:
		- 20210520@Kathy: Delete history  [Redmine:#154732]

*/
BEGIN
    SET NOCOUNT ON
	
	DECLARE @batchNo INT
	SET @batchNo = 5000

	WHILE(1=1)
	BEGIN
		DELETE	TOP (@batchNo)
		FROM	dbo.SettlementHistory WITH(ROWLOCK, UPDLOCK)
		WHERE	CreatedDate < @Date

		IF @@ROWCOUNT < @batchNo
			BREAK
	END
END
GO
