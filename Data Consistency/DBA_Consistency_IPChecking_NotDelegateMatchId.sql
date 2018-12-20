/*<info serverAlias="DBTP-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_Consistency_IPChecking_NotDelegateMatchId]
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
		- 20181219@Vicky: Check IP rules for Happy5 [Redmine:#104849]
	
	Param's Expanation:
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @transId BIGINT
	DECLARE @tblMatch TABLE (matchid INT NOT NULL UNIQUE)
	
	INSERT INTO @tblMatch(matchid)
	SELECT matchid
	FROM bodb02.dbo.Match m WITH (NOLOCK)
	WHERE Sporttype = @ProductId


	SELECT TOP (1) @transId = transid
	FROM	bodb02.dbo.bettrans b WITH (NOLOCK)
		INNER JOIN @tblMatch m ON b.matchid = m.matchid
	WHERE	b.bettype < 20000
			AND 1 = CASE
						WHEN IP NOT LIKE '%:%' AND NOT EXISTS (SELECT val FROM dbo.f_SplitString(IP, '.') WHERE val > 255 ) THEN 0
						ELSE 1
					END
	OPTION (maxrecursion 0)
	
	IF @transId IS NOT NULL
	BEGIN
		SELECT	@ErrCode = 100
				,@ErrMsg = 'Wrong IP value on product ' + CAST(@ProductId AS VARCHAR)
				,@SampleData = 'bettrans.TransId = ' + CAST(@transId AS VARCHAR)
	END

END
GO