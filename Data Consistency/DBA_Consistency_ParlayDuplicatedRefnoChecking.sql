/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_Consistency_ParlayDuplicatedRefnoChecking]
	 @ErrCode		INT				= 0		OUTPUT
	,@ErrMsg		VARCHAR(MAX)	= ''	OUTPUT 
	,@SampleData	VARCHAR(MAX)	= ''	OUTPUT
AS
/*
	Created: 20190830@Helen
	Task: Data consistency
	DB: DBCONSISTENCY-bodb_Consistency

	Revisions: 
		- 20190830@Helen: Duplicated Refno checking [Redmine:#119468] 
		
	Param's Expanation:
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Refnos VARCHAR(MAX) = ''
	
	SELECT TOP 100 refno
	INTO #Duplicated_Refno
	FROM bodb02.dbo.bettrans  WITH(NOLOCK)
	WHERE matchid = 29
		AND statusID NOT IN (101,102) --('VOID','REJECT')
	GROUP BY refno
	HAVING COUNT(1) > 1

	IF EXISTS (SELECT TOP 1 1 FROM #Duplicated_Refno)
	BEGIN
		SELECT @Refnos = @Refnos + ',' + CAST(refno AS VARCHAR)
		FROM #Duplicated_Refno b WITH (NOLOCK)
		
		SELECT	@Refnos = SUBSTRING(@Refnos, 2, LEN(@Refnos) - 1)
				,@ErrCode = 100
				,@ErrMsg = 'Duplicated Refnos !!! ' 
				,@SampleData = 'bettrans' + '.Refno in (' + @Refnos + ')'
				
	END
END
GO