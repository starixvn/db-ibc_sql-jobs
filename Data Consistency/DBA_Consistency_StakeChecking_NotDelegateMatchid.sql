/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_Consistency_StakeChecking_NotDelegateMatchId]
	@ProductId		INT		
	,@ErrCode		INT				= 0		OUTPUT
	,@ErrMsg		VARCHAR(MAX)	= ''	OUTPUT
	,@SampleData	VARCHAR(MAX)	= ''	OUTPUT
AS
/*
	CCreated: 20181219@Vicky
	Task: Data consistency
	DB: DBCONSISTENCY-bodb_Consistency

	Revisions: 
		- 20181219@Vicky: Check Stake for Happy5 [Redmine:#104849]
	
	Param's Expanation:
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @transId VARCHAR(MAX)
	DECLARE @tblMatch TABLE (matchid INT)
	
	SET @transId = ''
	
	INSERT INTO @tblMatch(matchid)
	SELECT matchid
	FROM bodb02.dbo.Match m WITH (NOLOCK)
	WHERE Sporttype = @ProductId
	
	
	SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
	FROM	bodb02.dbo.bettrans b WITH (NOLOCK)
	WHERE	b.bettype < 20000
			AND b.stake <= 0
			AND b.matchid IN (SELECT matchid FROM @tblMatch)
			
	
	IF @transId <> ''
	BEGIN
		SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
				,@ErrCode = 100
				,@ErrMsg = 'Stake must be larger than 0 on product ' + CAST(@ProductId AS VARCHAR)
				,@SampleData = 'bettrans.TransId in (' + @transId + ')'
	END

END
GO