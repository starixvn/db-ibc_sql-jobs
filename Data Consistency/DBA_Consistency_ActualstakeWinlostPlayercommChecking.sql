/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_ActualstakeWinlostPlayercommChecking]
	@tablename		VARCHAR(50)		= NULL	
	,@ErrCode		INT				= 0		OUTPUT
	,@ErrMsg		VARCHAR(MAX)	= ''	OUTPUT 
	,@SampleData	VARCHAR(MAX)	= ''	OUTPUT
AS
/*
	Created: 20211208@July
	Task: Data consistency
	DB: DBCONSISTENCY-bodb_Consistency

	Revisions: 
		- 20211208@July: Check Data Consistency - Check rule actual_stake, winlost, playercomm NULL - [Redmine:#165814]
	
	Param's Expanation:
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @transId VARCHAR(MAX) = ''
			,@Today DATETIME
			,@yesterday DATETIME

	SET @Today = CAST(GETDATE() AS DATE)
	SET @yesterday = DATEADD(DAY,-1,CAST(GETDATE() AS DATE))

	IF @tablename = 'bettrans'
	BEGIN
		SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM bodb02.dbo.bettrans WITH(NOLOCK) 
		WHERE (winlostdate = @Today OR winlostdate = @yesterday) 
			AND (actual_stake IS NULL OR winlost IS NULL OR playercomm IS NULL)
	END
	ELSE IF @tablename = 'bettransRNG'
	BEGIN
		SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM bodb02.dbo.bettransRNG WITH(NOLOCK) 
		WHERE (winlostdate = @Today OR winlostdate = @yesterday) 
			AND (actual_stake IS NULL OR winlost IS NULL OR playercomm IS NULL)
	END
	ELSE IF @tablename = 'bettransLC'
	BEGIN
		SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM bodb02.dbo.bettransLC WITH(NOLOCK) 
		WHERE (winlostdate = @Today OR winlostdate = @yesterday) 
			AND (actual_stake IS NULL OR winlost IS NULL OR playercomm IS NULL)
	END
	
	IF @transId <> ''
	BEGIN
		SELECT	 @transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
				,@ErrCode = 100
				,@ErrMsg = 'Check actual_stake, winlost, playercomm NULL on table ' + @tablename
				,@SampleData = @tablename + '.TransId in (' + @transId + ')'
	END
END
GO