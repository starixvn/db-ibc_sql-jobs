/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_DetectNetstakeforRNGChecking]
	 @tablename		VARCHAR(50)	 = NULL	
	,@ErrCode		INT			 = 0	OUTPUT
	,@ErrMsg		VARCHAR(MAX) = ''	OUTPUT 
	,@SampleData	VARCHAR(MAX) = ''	OUTPUT
AS
/*
	Created: 20210712@July
	Task: Data consistency
	DB: DBCONSISTENCY-bodb_Consistency

	Revisions: 
		- 20210712@July: Detect Netstake <> 0 for RNG products [Redmine:#158179]
	    - 20220221@July: Spadegaming - Exclue bettype 4599 (contribution bettype) - [Redmine:#168750]

	Param's Expanation:
*/
BEGIN
	DECLARE @transId VARCHAR(MAX)
			,@yesterday DATETIME 

	SET @transId = ''
	SET @yesterday = DATEADD(DAY,-1,CAST(GETDATE() AS DATE))

	IF @tablename = 'bettransRNG'
	BEGIN
		SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM	bodb02.dbo.bettransRNG b WITH (NOLOCK)
		WHERE	b.BetStake <> 0 
				AND b.statusID IN (101,102,103) --Reject/Void/Refund 
				AND b.GameID NOT IN (2198, 2398, 2998, 4297, 1698, 3898, 4599)
				AND b.winlostdate = @yesterday
	END

	IF @transId <> ''
	BEGIN
		SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
				,@ErrCode = 100
				,@ErrMsg = 'Detect Netstake <> 0 for RNG products'
				,@SampleData = @tablename + '.TransId in (' + @transId + ')'
	END
	
END
GO
