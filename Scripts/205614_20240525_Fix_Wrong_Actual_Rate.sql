/*<info serverAlias="DBTXN-bodb02"></info>*/
/*
	Created: 20240525@Sol
	Task: update actual rate - Redmine #205614
	DB: DBTXN-bodb02
*/

USE bodb02;

GO

-- ######### DBTXN #################### --

--bettrans
EXEC [dbo].[ExecRep_00] 
	@Winlostdate = '20240524'
	,@Target = 'DBTXN' -- DBTRANS/REPLICATED
	,@TableName = 'bettrans'
	,@isSiteDB = 0

GO

--bettransLC
EXEC [dbo].[ExecRep_00] 
	@Winlostdate = '20240524'
	,@Target = 'DBTXN' -- DBTRANS/REPLICATED
	,@TableName = 'bettransLC'
	,@isSiteDB = 0

GO

--bettransRnG
EXEC [dbo].[ExecRep_00] 
	@Winlostdate = '20240524'
	,@Target = 'DBTXN' -- DBTRANS/REPLICATED
	,@TableName = 'bettransRnG'
	,@isSiteDB = 0

GO

--transfer
EXEC [dbo].[ExecRep_00] 
	@Winlostdate = '20240524'
	,@Target = 'DBTXN' -- DBTRANS/REPLICATED
	,@TableName = 'transfer'
	,@isSiteDB = 0

GO


-- ######### REPLICATED #################### --

--bettrans
EXEC [dbo].[ExecRep_00] 
	@Winlostdate = '20240524'
	,@Target = 'REPLICATED' -- DBTRANS/REPLICATED
	,@TableName = 'bettrans'
	,@isSiteDB = 0

GO

--bettransLC
EXEC [dbo].[ExecRep_00] 
	@Winlostdate = '20240524'
	,@Target = 'REPLICATED' -- DBTRANS/REPLICATED
	,@TableName = 'bettransLC'
	,@isSiteDB = 0

GO

--bettransRnG
EXEC [dbo].[ExecRep_00] 
	@Winlostdate = '20240524'
	,@Target = 'REPLICATED' -- DBTRANS/REPLICATED
	,@TableName = 'bettransRnG'
	,@isSiteDB = 0

GO

--transfer
EXEC [dbo].[ExecRep_00] 
	@Winlostdate = '20240524'
	,@Target = 'REPLICATED' -- DBTRANS/REPLICATED
	,@TableName = 'transfer'
	,@isSiteDB = 0