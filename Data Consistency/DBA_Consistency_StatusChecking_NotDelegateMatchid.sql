/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_Consistency_StatusChecking_NotDelegateMatchId]
	@ProductId		INT		
	,@ErrCode		INT				= 0		OUTPUT
	,@ErrMsg		VARCHAR(MAX)	= ''	OUTPUT
	,@SampleData	VARCHAR(MAX)	= ''	OUTPUT
AS
/*
	Created: 20181219@Vicky
	Task: Data consistency
	DB: DBCONSISTENCY-bodb_Consistency

	Revisions: 
		- 20181219@Vicky: Check status rules for Happy5 [Redmine:#104849]
	
	Param's Expanation:
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @transId VARCHAR(MAX)
	DECLARE @yesterday DATETIME
	DECLARE @tblMatch TABLE (matchid INT)
	
	INSERT INTO @tblMatch(matchid)
	SELECT matchid
	FROM bodb02.dbo.Match m WITH (NOLOCK)
	WHERE Sporttype = @ProductId
	
	
	SET @transId = ''
	SET @yesterday = DATEADD(DAY,-1,CAST(GETDATE() AS DATE))

	SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
	FROM	bodb02.dbo.bettrans b WITH (NOLOCK)
	WHERE	b.bettype < 20000
			AND b.winlostdate = @yesterday
			AND b.statusID = 0
			AND b.matchid IN (SELECT matchid FROM @tblMatch)
	
	IF @transId <> ''
	BEGIN
		SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
				,@ErrCode = 100
				,@ErrMsg = 'All yesterday tickets must be settled on product ' + CAST(@ProductId AS VARCHAR)
				,@SampleData = 'bettrans.TransId in (' + @transId + ')'
	END

END
GO