/*<info serverAlias="DBTP-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_Consistency_PTChecking_NotDelegateMatchId]
	@ProductId		INT		
	,@ErrCode		INT				= 0		OUTPUT
	,@ErrMsg		VARCHAR(MAX)	= ''	OUTPUT
	,@SampleData	VARCHAR(MAX)	= ''	OUTPUT
AS
/*
	Created: 20181219@Vicky
	Task: Data consistency
	DB: DBTP/bodb_Consistency

	Revisions: 
		- 20181219@Vicky: Check PT rules for Happy5 [Redmine:#104849]
	
	Param's Expanation:
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @transId BIGINT
	DECLARE @tblMatch TABLE (matchid INT)
	
	INSERT INTO @tblMatch(matchid)
	SELECT matchid
	FROM bodb02.dbo.Match m WITH (NOLOCK) 
	WHERE Sporttype = @ProductId
	
	SELECT TOP (1) @transId = transid
	FROM	bodb02.dbo.bettrans b WITH (NOLOCK)
	WHERE	b.bettype < 20000
			AND b.matchid IN (SELECT matchid FROM @tblMatch)
			AND (b.tpositiontaking < 0
				OR b.spositiontaking < 0
				OR b.mpositiontaking < 0
				OR b.apositiontaking < 0
				OR tpositiontaking <> spositiontaking + mpositiontaking + apositiontaking
			)
	
	IF @transId IS NOT NULL
	BEGIN
		SELECT	@ErrCode = 100
				,@ErrMsg = 'Wrong PT value on product ' + CAST(@ProductId AS VARCHAR)
				,@SampleData = 'bettrans.TransId = ' + CAST(@transId AS VARCHAR)
	END

END
GO