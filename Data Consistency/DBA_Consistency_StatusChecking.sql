/*<info serverAlias="DBTP-bodb_Consistency" executers="" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_Consistency_StatusChecking]
	@ProductId		INT		
	,@ErrCode		INT				= 0		OUTPUT
	,@ErrMsg		VARCHAR(MAX)	= ''	OUTPUT 
	,@SampleData	VARCHAR(MAX)	= ''	OUTPUT
AS
/*
	Created: 20180808@Kathy
	Task: Data consistency
	DB: DBTP/bodb_Consistency

	Revisions: 
		- 20180808@Kathy: Check status rules for poker game [Redmine:#98064]
	
	Param's Expanation:
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @transId BIGINT
	DECLARE @yesterday DATETIME

	SET @yesterday = DATEADD(DAY,-1,CAST(GETDATE() AS DATE))

	SELECT TOP (1) @transId = transid
	FROM	bodb02.dbo.bettrans b WITH (NOLOCK)
	WHERE	b.bettype < 20000
			AND b.winlostdate = @yesterday
			AND b.statusID = 0
			AND b.matchid = @ProductId
	
	IF @transId IS NOT NULL
	BEGIN
		SELECT	@ErrCode = 100
				,@ErrMsg = 'All yesterday tickets must be settled on product ' + CAST(@ProductId AS VARCHAR)
				,@SampleData = 'bettrans.TransId = ' + CAST(@transId AS VARCHAR)
	END

END
GO