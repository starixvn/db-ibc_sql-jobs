SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE	dbo.Task_Archive_Control
						@DebugMode			TINYINT			= 1
AS
/*
	Creator:	20200720@Brice
	Task:		Archive controller - [Redmine: #111093]
	Database:	DBARC.bodb_Archive

	Revisions:
		- 20200720@Brice:	Initialize - 13 tables [Redmine: #111093]
		- 20201210@Max: TVS - New issue type Abnormal Accounts [Redmine: #143666]

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
		,	('zzzbettransM_bk')
		,	('zzzbettrans_bk')
		,	('TicketVoiding_VoidedTransaction_bk')
		,	('TicketVoiding_AutoVoidRequest_Queue_bk')
		,	('TicketVoiding_AutoUnmarkSetting_bk')	
		;


	SELECT	@StartDate	= MIN(rid)
		,	@EndDate	= MAX(rid)
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
						@StartDate	= @StartDate
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
END
GO
/*<info serverAlias="DBARC-bodb_Archive" executers="" viewers="" isFunction="0" isNested="0"></info>*/