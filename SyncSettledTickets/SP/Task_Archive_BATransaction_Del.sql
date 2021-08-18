/*<info serverAlias="DB042-bodb_Licensee" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Archive_BATransaction_Del]
AS
/*
	Create By: 20180625@Patrick
	Task: Remove data after movebet days
	DB: DB042/bodb_Licensee
	Revisions: 
		-20191127@Patrick: Setup sync status ticket on DB052 -> DB054 - [Redmine: #124482]
	Para's explaination
*/
BEGIN
	SET NOCOUNT ON
	SELECT t.TransId
	INTO #__archiveData
	FROM dbo.LicenseeBATransaction_active t WITH(NOLOCK)
		LEFT JOIN bodb02.dbo.bettrans b WITH(NOLOCK) ON t.TransID = b.transid
	WHERE b.transid IS NULL

	DECLARE @__TransIds TABLE (transId BIGINT)
	WHILE 1 = 1
	BEGIN
		
		DELETE FROM @__TransIds
		
		DELETE TOP(2000) 
		FROM #__archiveData
		OUTPUT DELETED.TransID INTO @__TransIds
		
		IF @@ROWCOUNT = 0
			BREAK

		DELETE
		FROM dbo.LicenseeBATransaction_active WITH(ROWLOCK)
		WHERE TransID IN (SELECT t.transId FROM @__TransIds t)

	END

END