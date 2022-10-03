SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE	dbo.Task_Archive_Bet_Control
						@DebugMode			TINYINT			= 1
AS
/*
	Creator:	20200729@Brice
	Task:		Archive bet controller - [Redmine: #111093]
	Database:	DBTXN.bodb02

	Revisions:
		- 20200729@Brice:	Initialize [Redmine: #111093]
		- 20210225@Max: [TVS] Remove archived data [Redmine: #150524]
		- 20220121@Max: MBU - Clean up Cash Out Selling [Redmine: #167802]
		- 20221003@Max: [TVS] Enhance archive process of TVS data regarding the Scale Out DB project - [Redmine: #178234]
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

	DECLARE	@ArchiveTable_oneDay TABLE (
				rid			INT				IDENTITY(1,1)
			,	tablename	NVARCHAR(128)
			,	PRIMARY KEY CLUSTERED (rid)
			);

	DECLARE	@WinlostDate		SMALLDATETIME
		,	@TableName			NVARCHAR(128)
		;

	DECLARE	@StartDate			SMALLDATETIME
		,	@EndDate			SMALLDATETIME

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

	INSERT INTO	@ArchiveTable_oneDay
			(tablename)
	VALUES	('zzzbettrans')
		,	('zzzbettransM')
		,	('TicketVoiding_VoidedTransaction')
		,	('CashOutSelling')
		;

	INSERT INTO	@ArchiveTable
			(tablename)
	VALUES	('TicketVoiding_Request')
		,	('TicketVoiding_AutoUnmarkSetting')	
		,	('TicketVoiding_RequestDetail')
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
		FROM	@ArchiveTable_oneDay;

		WHILE	@StartTable <= @EndTable
		BEGIN;
			SELECT @TableName = tablename FROM @ArchiveTable_oneDay WHERE rid = @StartTable 

			IF	@DebugMode & 1 > 0
			-- Execution --
			BEGIN;
				EXECUTE dbo.Task_Archive_Bet
							@StartDate		= @WinlostDate
						,	@DeletedTarget	= @TableName
						,	@Action			= 'delete'
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

	/*----------------------*/
	SELECT	@StartDate	= MIN(winlostdate)
		,	@EndDate	= MAX(winlostdate)
	FROM	@ArchiveDate;

	SELECT	@StartTable	= MIN(rid)
		,	@EndTable	= MAX(rid)
	FROM	@ArchiveTable;

	WHILE	@StartTable <= @EndTable
	BEGIN;
		SELECT @TableName = tablename FROM @ArchiveTable WHERE rid = @StartTable 

		IF	@DebugMode & 1 > 0
		-- Execution --
		BEGIN;
			EXECUTE dbo.Task_Archive_Bet
							@StartDate		= @StartDate
						,	@EndDate		= @EndDate
						,	@DeletedTarget	= @TableName
						,	@Action			= 'delete'
						;
		END;

		IF	@DebugMode & 2 > 0
		-- Print Message --
		BEGIN;
			SELECT	@width_TableName = MAX(LEN(tablename))
				,	@str_WinlostDate = CONVERT(NVARCHAR(25), @StartDate, 120) + ' - ' + CONVERT(NVARCHAR(25), @EndDate, 120)
			FROM	@ArchiveTable;

			RAISERROR(N'[%s] - Table [%-*s]', 0, 0, @str_WinlostDate, @width_TableName, @TableName) WITH NOWAIT;
		END;

		WAITFOR DELAY '00:00:00.100';

		SET	@StartTable = @StartTable + 1;
	END;

END
GO
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
