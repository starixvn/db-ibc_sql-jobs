
    SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE	dbo.Task_Archive_Control_oldData
						@DebugMode			TINYINT			= 1,
						@datebegin			SMALLDATETIME   ='2019-01-01',
						@dateend			SMALLDATETIME	='2020-10-29'
AS
/*
	Creator:	20200720@Brice
	Task:		Archive controller - [Redmine: #111093]
	Database:	DBARC.bodb_Archive

	Revisions:
		- 20200720@Brice:	Initialize - 13 tables [Redmine: #111093]
		
	call sp: exec Task_Archive_Control_oldData @datebegin='2019-01-01', @dateend='2020-10-29';
*/
BEGIN;
	SET NOCOUNT ON;



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
	DECLARE	@Query		NVARCHAR(MAX)
		;

	INSERT INTO	@ArchiveTable
			(tablename)
	VALUES	('TicketVoiding_RequestDetail_bk')
		,	('zzzbettransM_bk')
		,	('zzzbettrans_bk')
		,	('TicketVoiding_AutoVoidRequest_Queue_bk')
		,	('TicketVoiding_AutoUnmarkSetting_bk')
		,	('TicketVoiding_Request_bk')
		,	('TicketVoiding_OperatorInfo_bk')
		,	('TicketVoiding_Queue_bk')
		,	('TicketVoiding_VoidingHistory_bk')
		,	('TicketVoiding_Reason_bk')
		,	('TicketVoiding_VoidedTransaction_bk')
		,	('TicketVoiding_RequestDetailTicket_Single_bk')
		,	('TicketVoiding_RequestDetailTicket_SubParlay_bk')
		;


	SELECT	@StartDate	= 0
	SELECT	@EndDate	= datediff(day,@datebegin,@dateend)

	create table ##SportBettypeMatrix(bettype smallint, ProductID tinyint)
	insert into ##SportBettypeMatrix(bettype,ProductID) select bettype,ProductID from bodb02.dbo.SportBettypeMatrix WITH (NOLOCK) where ProductID IN (1,3,5,25,27,37)
	
	create table ##match_bk(matchid int)
	create table ##bettrans_bk(transid bigint)
	create table ##bettransM_bk(transid bigint)
	create table ##bettrans_bk2(transid bigint)
	create table ##bettrans_bk3(transid bigint,matchid int)

	WHILE	@StartDate <= @EndDate
	BEGIN;
		SELECT	@WinlostDate = DATEADD(day,@StartDate,@datebegin)

		
		insert into ##match_bk(matchid) select distinct matchid from match_bk WITH (NOLOCK) where eventdate=@WinlostDate


		insert into ##bettrans_bk(transid) select distinct b.transid from bettrans_bk b WITH (NOLOCK) join ##SportBettypeMatrix s on b.bettype=s.bettype where b.statusID=102 and b.winlostdate = @winlostdate
		
		
		insert into ##bettransM_bk(transid) select distinct b.transid from bettransM b WITH (NOLOCK) where b.statusID=102 and b.winlostdate = @winlostdate

		
		insert into ##bettrans_bk2(transid) select distinct b.refno from bettrans_bk b WITH (NOLOCK) join ##SportBettypeMatrix s on b.bettype=s.bettype where b.statusID=102 and s.bettype not in (29,9) and s.ProductID =1 and b.winlostdate = @winlostdate
		
		
		insert into ##bettrans_bk3(transid,matchid) select distinct b.transid,b.matchid from mondb.dbo.brice_bettrans_bk b WITH (NOLOCK) where b.winlostdate = @winlostdate

		SELECT	@StartTable	= MIN(rid)
			,	@EndTable	= MAX(rid)
		FROM	@ArchiveTable;

		WHILE	@StartTable <= @EndTable
		BEGIN;
			SELECT @TableName = tablename FROM @ArchiveTable WHERE rid = @StartTable 

			IF	@DebugMode & 1 > 0
			-- Execution --
			BEGIN;
				EXECUTE	dbo.Task_Archive_Copy_oldData
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

		truncate table ##match_bk
		truncate table ##bettrans_bk
		truncate table ##bettransM_bk
		truncate table ##bettrans_bk2
		truncate table ##bettrans_bk3
		
		SET	@StartDate = @StartDate + 1;
	END;

	INSERT INTO	dbo.TicketVoiding_Reason_bk
			(	ReasonId, ReasonEnglish, ReasonChineseSimplified)
		VALUES (6015,'Soccer - Abnormal bet','足球 - 非正常投注'),(6016,'Soccer - Danger Accept In Red Card','足球 - 有红牌的危险时段中误被接受')
		
	INSERT INTO	dbo.TicketVoiding_VoidedTransaction_bk
			(	TransId, MessageId, ReasonId, MatchId, CreatedDate, Id, IssueTypeID, SubIssueTypeID, CustID)
		select TransId, MessageId, ReasonId, MatchId, CreatedDate, Id, IssueTypeID, SubIssueTypeID, CustID
		FROM	dbtrans.bodb02.dbo.TicketVoiding_VoidedTransaction AS t1 WITH (NOLOCK) where createdDate <'2020-01-01'
		except
		select TransId, MessageId, ReasonId, MatchId, CreatedDate, Id, IssueTypeID, SubIssueTypeID, CustID
		FROM	bodb02.dbo.TicketVoiding_VoidedTransaction AS t1 WITH (NOLOCK) where createdDate <'2020-01-01'		
END
GO
/*<info serverAlias="DBARC-bodb_archive" executers="" viewers="" isFunction="0" isNested="1"></info>*/
    
