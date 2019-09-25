SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE	[dbo].[Task_Archive_Event_Control]
AS
/*
	Creator:	20190318@Helen
	Task:		Archive event controller - [Redimine: #110447]
	Database:	DBTXN.bodb02

	Revisions:
		- 20190318@Helen: Initialize - archive event timeout issue - [Redimine: #110447]
 */
BEGIN

	DECLARE @archiveDate TABLE (rid int PRIMARY KEY IDENTITY(1,1), winlostdate smalldatetime)
	DECLARE @archiveTable TABLE (rid int IDENTITY(1,1), tablename VARCHAR(100))

	INSERT INTO @archiveDate (winlostdate)
	SELECT winlostdate FROM dbo.task_archivedate
	ORDER BY 1

	INSERT INTO @archiveTable (tablename)
	VALUES 
	('odds_bk'),
	('match_bk'),
	('bingoBall_bk'),
	('outright_bk'),
	('VSOutright_bk'),
	('match_remark'),
	('MatchMaxbet_bk'),
	('ResultDetail_bk'),
	('ResultDetail3rd_bk'),
	('EventInfo3rd_bk'),
	('AutoPayoutResult_bk'),
	('ProviderResultDetail_bk'),
	('Odds3rd_bk'),
	('Intg_OddsFeed_SettlementAction_bk'),
	('Intg_OddsFeed_SettlementAction_Outright_bk'),
	('Match3rd_bk'),
	('oddsES_bk'),
	('ResultDetailES_bk'),
	('SMP_Market_bk'),
	('SMP_MarketSelection_bk')

	DECLARE @wldate SMALLDATETIME, @tableName VARCHAR(100)
	DECLARE @startDate INT = 1, @endDate INT

	DECLARE @startTable INT = 1, @endTable INT

	SET @endDate = (SELECT MAX(rid) FROM @archiveDate)
	SET @endTable = (SELECT MAX(rid) FROM @archiveTable)

	DECLARE @winlostdate INT, @index INT = 0, @archiveDate_cnt INT

	DECLARE @msg nvarchar(200) = 'Currently at archiveDate rid: %d, Table: %s.'
	DECLARE @msg_total nvarchar(200) = 'Total of archive Date: %d.'

	WHILE @startDate <= @endDate
	BEGIN
		SELECT @wldate = winlostdate FROM @archiveDate WHERE rid = @startDate 
		
		SELECT @startTable = 1
		
		WHILE (@startTable <= @endTable)
		BEGIN
			SELECT @tableName = tablename FROM @archiveTable WHERE rid = @startTable 
			
			/*
			--for troubleshoot
			RAISERROR (@msg, 0, 1,@startDate, @tableName) WITH NOWAIT
			
			*/
			EXEC DBARC.bodb_Archive.dbo.Task_Archive_Event_Copy @winlostdate = @wldate, @TableName = @tableName
			
			WAITFOR DELAY '00:00:0.100'
			
			SET @startTable = @startTable + 1
		END
			
		SET @startDate = @startDate + 1
		
	END
END
GO
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/