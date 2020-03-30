/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_ParlayDuplicatedSubTicketChecking]
	 @ErrCode		INT				= 0		OUTPUT
	,@ErrMsg		VARCHAR(MAX)	= ''	OUTPUT 
	,@SampleData	VARCHAR(MAX)	= ''	OUTPUT
AS
/*
	Created: 20200326@Max
	Task: Data consistency
	DB: DBCONSISTENCY-bodb_Consistency

	Revisions: 
		- 20200326@Max: New Data Consistency Rule for Abnormal Parlay Ticket [Redmine: #130644]
		
	Param's Expanation:
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @TransIds VARCHAR(MAX) = ''
	CREATE TABLE #Duplicated_SubTicket_Transid (refno BIGINT)
	
	INSERT INTO #Duplicated_SubTicket_Transid (refno)
	SELECT DISTINCT refno
	FROM bodb02.dbo.bettransm WITH (NOLOCK)
	WHERE matchid <> 204
	GROUP BY refno,matchid
	HAVING COUNT(matchid) > 1

	IF EXISTS (SELECT TOP 1 1 FROM #Duplicated_SubTicket_Transid)
	BEGIN
		SELECT TOP (100) @TransIds = @TransIds + ',' + CAST(transId AS VARCHAR)
		FROM #Duplicated_SubTicket_Transid t
			INNER LOOP JOIN bodb02.dbo.bettrans b WITH (NOLOCK) ON t.refno = b.refno
		WHERE b.matchid = 29
			AND b.bettype = 29
			AND b.statusID NOT IN (101,102)				
	END

	IF @TransIds <> ''
	BEGIN
		SELECT	@TransIds = SUBSTRING(@TransIds, 2, LEN(@TransIds) - 1)
				,@ErrCode = 100
				,@ErrMsg = 'Duplicated Sub Ticket in the same Match !!! ' 
				,@SampleData = 'bettrans' + '.transid in (' + @TransIds + ')'
	END

	DROP TABLE #Duplicated_SubTicket_Transid
END
GO