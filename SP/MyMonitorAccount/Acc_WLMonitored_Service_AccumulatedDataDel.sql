/*<info serverAlias="DBAGE-bodb02,DBEXT-bodb02" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_WLMonitored_Service_AccumulatedDataDel]
AS
/*	Creator: 20220617@Kathy
	Task: Accumulate data
	DB: DBAGE/BODB02
	
	Revisions:	
		- 20220617@Kathy: delete data [Redmine:#170467]

	Param's Explanation:
		
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @deletedDate	DATETIME
			,@BatchCount	INT

	SET @BatchCount = 2000
	SET @deletedDate = DATEADD (MONTH, -4, GETDATE())

	
	WHILE (1=1)
	BEGIN
		DELETE	TOP (@BatchCount) p
		FROM	dbo.WLMonitored_AccumulatedWL p WITH(ROWLOCK,UPDLOCK)
		WHERE	UpdatedTime < @deletedDate

		IF @@ROWCOUNT < @BatchCount
			BREAK
	END

	WHILE (1=1)
	BEGIN
		DELETE	TOP (@BatchCount) p
		FROM	dbo.Dep_WLMonitored_AccumulatedWL p WITH(ROWLOCK,UPDLOCK)
		WHERE	UpdatedTime < @deletedDate

		IF @@ROWCOUNT < @BatchCount
			BREAK
	END
END
GO
