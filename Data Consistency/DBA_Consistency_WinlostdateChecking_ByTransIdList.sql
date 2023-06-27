/*<info serverAlias="DBTP-bodb02" executers="" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_WinlostdateChecking_ByTransIdList]
	@TransIdList	VARCHAR(MAX) = NULL
AS
/*
	Created: 20230616@July
	Task: Check ticket data consistency - detect abnormal winlost date vs settlement time (Rule #59) 
	DB: DBTP-bodb02

	Revisions: 
		- 20230616@July: Create new SP - [Redmine:#189723]
	
*/
BEGIN
	SET NOCOUNT ON
	
	CREATE TABLE #tmp_TransIdList (TransId BIGINT)

	INSERT INTO #tmp_TransIdList (TransId)
	SELECT value AS TransId
	FROM STRING_SPLIT(@TransIdList, ',')
	WHERE value <> ''

	--Remove ticket Cashout & currency (20, 72)
	DELETE t
	FROM #tmp_TransIdList t
		INNER JOIN dbo.bettrans b WITH (NOLOCK) ON t.TransId = b.TransId
	WHERE 1 = CASE WHEN b.statusID IN (111, 112, 113) AND b.betdaqid = -2 THEN 1
			       WHEN b.currency IN (20,72) THEN 1 
				   ELSE 0 END

	--Return table
	SELECT TOP (100) TransId
	FROM #tmp_TransIdList
	
	DROP TABLE #tmp_TransIdList
END