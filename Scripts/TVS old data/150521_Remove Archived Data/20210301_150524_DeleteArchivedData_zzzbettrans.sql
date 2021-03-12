/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/
/*
	Created:	20210301@Max
	Task:		[TVS] Remove archived data [Redmine: #150524]
	Database:	DBTXN-bodb02
*/
BEGIN

	DECLARE @ids VARCHAR(MAX), @rowcount INT = 0, @topk INT = 500
	CREATE TABLE #output (id INT)	

	SET @rowcount = 1
	WHILE @rowcount <> 0
	BEGIN
		TRUNCATE TABLE #output
		SET @ids = NULL

		DELETE TOP(@topk) t
		OUTPUT deleted.id INTO #output(id)
		FROM dbo.zzzbettrans_Archived t
		SET @rowcount = @@ROWCOUNT

		SELECT @ids = COALESCE(@ids + ',' + CAST(id AS VARCHAR(50)), CAST(id AS VARCHAR(50)))
		FROM #output  
			
		EXEC [dbo].[ExecRep_02] @Command = 'ALL_DB', @DeletedTarget = 'zzzbettrans', @transIds = @ids, @winlostdate = ''
	END
	DROP TABLE #output

END
GO

