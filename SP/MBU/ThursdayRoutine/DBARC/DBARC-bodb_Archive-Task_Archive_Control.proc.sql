SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
ALTER PROCEDURE	dbo.Task_Archive_Control
						@DebugMode			TINYINT			= 1
AS
/*
	Creator:	20200720@Brice
	Task:		Archive controller - [Redmine: #111093]
	Database:	DBARC.bodb_Archive

	Revisions:
		- 20200720@Brice:	Initialize - 13 tables [Redmine: #111093]
		- 20201210@Max: TVS - New issue type Abnormal Accounts [Redmine: #143666]
		- 20200209@Helen: TVS - New issue type Abnormal Accounts - archive zzzbettrans  [Redmine: #143666]

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

		,	@FromDate			INT
		,	@ToDate				INT

		;

	DECLARE @str_WinlostDate	NVARCHAR(100)
		,	@width_TableName	INT
		;


	INSERT INTO	@ArchiveDate
		(	winlostdate)
	SELECT	winlostdate
	FROM	DBTXN.bodb02.dbo.Task_ArchiveDate WITH (NOLOCK)
	ORDER BY winlostdate;

	INSERT INTO	@ArchiveTable
			(tablename)
	VALUES	('TicketVoiding_RequestDetail_bk')
		,	('TicketVoiding_Request_bk')
		,	('TicketVoiding_AutoVoidRequest_Queue_bk')
		,	('TicketVoiding_AutoUnmarkSetting_bk')	
		;

	INSERT INTO	@ArchiveTable_oneDay
			(tablename)
	VALUES	('zzzbettransM_bk')
		,	('zzzbettrans_bk')
		,	('TicketVoiding_VoidedTransaction_bk')
		;
		
	SELECT	@StartDate	= MIN(winlostdate)
		,	@EndDate	= MAX(winlostdate)
		,	@FromDate	= MIN(rid)
		,	@ToDate		= MAX(rid)

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
			EXECUTE	dbo.Task_Archive_Copy
						@StartDate		= @StartDate
					,	@EndDate		= @EndDate
					,	@TableName		= @TableName
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
				EXECUTE	dbo.Task_Archive_Copy
							@StartDate	= @WinlostDate
						,	@TableName	= @TableName
						;
			END;

			IF	@DebugMode & 2 > 0
			-- Print Message --
			BEGIN;
				SELECT	@width_TableName = MAX(LEN(tablename))
					,	@str_WinlostDate = CONVERT(NVARCHAR(25), @WinlostDate, 120)
				FROM	@ArchiveTable_oneDay;

				RAISERROR(N'[%s] - Table [%-*s]', 0, 0, @str_WinlostDate, @width_TableName, @TableName) WITH NOWAIT;
			END;

			WAITFOR DELAY '00:00:00.100';

			SET	@StartTable = @StartTable + 1;
		END;

		SET	@StartDate = @StartDate + 1;
	END;
END
GO
/*<info serverAlias="DBARC-bodb_Archive" executers="" viewers="" isFunction="0" isNested="0"></info>*/