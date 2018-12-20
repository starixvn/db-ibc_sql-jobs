/*<info serverAlias="DBTP-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_StatusChecking_NotDelegateMatchId]
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
		- 20181219@Vicky: Check status rules for Happy5 [Redmine:#104849]
	
	Param's Expanation:
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @transId BIGINT
	DECLARE @yesterday DATETIME
	DECLARE @tblMatch TABLE (matchid INT NOT NULL UNIQUE)
	
	INSERT INTO @tblMatch(matchid)
	SELECT matchid
	FROM bodb02.dbo.Match m WITH (NOLOCK)
	WHERE Sporttype = @ProductId
	
	
	SET @yesterday = DATEADD(DAY,-1,CAST(GETDATE() AS DATE))

	SELECT TOP (1) @transId = transid
	FROM	bodb02.dbo.bettrans b WITH (NOLOCK)
		INNER JOIN @tblMatch m ON b.matchid = m.matchid
	WHERE	b.bettype < 20000
			AND b.winlostdate = @yesterday
			AND b.statusID = 0
	
	IF @transId IS NOT NULL
	BEGIN
		SELECT	@ErrCode = 100
				,@ErrMsg = 'All yesterday tickets must be settled on product ' + CAST(@ProductId AS VARCHAR)
				,@SampleData = 'bettrans.TransId = ' + CAST(@transId AS VARCHAR)
	END

END
GO