SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE	dbo.Task_Archive_Event_Control
						@DebugMode			TINYINT			= 1
AS
/*
	Creator:	20190318@Helen
	Task:		Archive event controller - [Redmine: #110447]
	Database:	DBTXN.bodb02

	Revisions:
		- 20190318@Helen:	Initialize - archive event timeout issue - [Redmine: #110447]
		- 20190925@Billy:	Add [Dot_Admin_Assignment_Trader] table - [Redmine: #117014]
		- 20191107@Billy:	Fix wrong default @DebugMode - [Redmine: #123521]
		- 20190827@Billy:	Add [oddsOS] & [ResultDetailOS] tables - [Redmine: #119257]
		- 20200622@Patrick: Add more table VSRaceInfo [Redmine: #135963]
*/
BEGIN;
	SET NOCOUNT ON;

	DECLARE	@ArchiveDate TABLE (
				rid			INT				IDENTITY(1,1)
			,	winlostdate	SMALLDATETIME
			,	PRIMARY KEY CLUSTERED (rid)
			);

	DECLARE	@ArchiveTable TABLE (
				rid			INT				IDENTITY(1,1)
			,	tablename	NVARCHAR(128)
			,	PRIMARY KEY CLUSTERED (rid)
			);

	DECLARE	@WinlostDate		SMALLDATETIME
		,	@TableName			NVARCHAR(128)
		;

	DECLARE	@StartDate			INT
		,	@EndDate			INT

		,	@StartTable			INT
		,	@EndTable			INT
		;

	DECLARE @str_WinlostDate	NVARCHAR(25)
		,	@width_TableName	INT
		;


	INSERT INTO	@ArchiveDate
		(	winlostdate)
	SELECT	winlostdate
	FROM	dbo.Task_ArchiveDate WITH (NOLOCK)
	ORDER BY winlostdate;

	INSERT INTO	@ArchiveTable
			(tablename)
	VALUES	('odds_bk')
		,	('match_bk')
		,	('bingoBall_bk')
		,	('outright_bk')
		,	('VSOutright_bk')
		,	('match_remark')
		,	('MatchMaxbet_bk')
		,	('ResultDetail_bk')
		,	('ResultDetail3rd_bk')
		,	('EventInfo3rd_bk')
		,	('AutoPayoutResult_bk')
		,	('ProviderResultDetail_bk')
		,	('Odds3rd_bk')
		,	('Intg_OddsFeed_SettlementAction_bk')
		,	('Intg_OddsFeed_SettlementAction_Outright_bk')
		,	('Match3rd_bk')
		,	('oddsES_bk')
		,	('ResultDetailES_bk')
		,	('SMP_Market_bk')
		,	('SMP_MarketSelection_bk')
		,	('Dot_Admin_Assignment_Trader_bk')
		,	('oddsOS_bk')
		,	('ResultDetailOS_bk')
		,	('VSRaceInfo_bk')
		;


	SELECT	@StartDate	= MIN(rid)
		,	@EndDate	= MAX(rid)
	FROM	@ArchiveDate;

	WHILE	@StartDate <= @EndDate
	BEGIN;
		SELECT	@WinlostDate = winlostdate
		FROM	@ArchiveDate
		WHERE	rid = @StartDate;

		SELECT	@StartTable	= MIN(rid)
			,	@EndTable	= MAX(rid)
		FROM	@ArchiveTable;

		WHILE	@StartTable <= @EndTable
		BEGIN;
			SELECT @TableName = tablename FROM @ArchiveTable WHERE rid = @StartTable 

			IF	@DebugMode & 1 > 0
			-- Execution --
			BEGIN;
				EXECUTE	DBARC.bodb_Archive.dbo.Task_Archive_Event_Copy
							@winlostdate	= @WinlostDate
						,	@TableName		= @TableName
						;
			END;

			IF	@DebugMode & 2 > 0
			-- Print Message --
			BEGIN;
				SELECT	@width_TableName = MAX(LEN(tablename))
					,	@str_WinlostDate = CONVERT(NVARCHAR(25), @WinlostDate, 120)
				FROM	@ArchiveTable;

				RAISERROR(N'[%s] - Table [%-*s]', 0, 0, @str_WinlostDate, @width_TableName, @TableName) WITH NOWAIT;
			END;

			WAITFOR DELAY '00:00:00.100';

			SET	@StartTable = @StartTable + 1;
		END;

		SET	@StartDate = @StartDate + 1;
	END;
END
GO
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/