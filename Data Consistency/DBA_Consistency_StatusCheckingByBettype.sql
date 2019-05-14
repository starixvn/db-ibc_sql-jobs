/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_Consistency_StatusCheckingByBettype]
	@Bettype		SMALLINT
	,@ProductName	VARCHAR(50)		= ''
	,@ErrCode		INT				= 0		OUTPUT
	,@ErrMsg		VARCHAR(MAX)	= ''	OUTPUT 
	,@SampleData	VARCHAR(MAX)	= ''	OUTPUT
AS
/*
	Created: 20190514@Kathy
	Task: Data consistency
	DB: DBCONSISTENCY/bodb_Consistency

	Revisions: 
		- 20190514@Kathy: Check status rules for BetBuilder [Redmine:#106903]
	
	Param's Expanation:
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @transId VARCHAR(MAX)
			,@yesterday DATETIME

	SET @transId = ''
	SET @yesterday = DATEADD(DAY,-1,CAST(GETDATE() AS DATE))

	SELECT	TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
	FROM	bodb02.dbo.bettrans b WITH(NOLOCK)
	WHERE	b.bettype = @Bettype
			AND b.statusID = 0
			AND b.winlostdate = @yesterday

	IF @transId <> ''
	BEGIN
		SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
				,@ErrCode = 100
				,@ErrMsg = 'All yesterday tickets must be settled on product ' + @ProductName
				,@SampleData = 'bettrans.TransId = ' + @transId
	END

END
GO