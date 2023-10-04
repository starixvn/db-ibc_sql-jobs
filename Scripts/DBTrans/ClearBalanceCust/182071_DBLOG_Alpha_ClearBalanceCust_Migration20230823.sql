/*<info serverAlias="DBLOG-bodb_CustomerLog"></info>*/
/*
	Created: 20230823@Bobby
	Task: 182071 - Alpha - AutoJob ClearBalance
	DB: DBLOG.bodb_CustomerLog
	Remark: DBLOG
*/
-- DBLOG 
-- TODO: SET ActionNameJP, ActionNameKO as ActionNameEN by default
use bodb_CustomerLog;
GO
UPDATE [LogAction] WITH(ROWLOCK, UPDLOCK)
SET ActionNameJP = ActionNameEN, ActionNameKO = ActionNameEN
WHERE ActionID = 95086;


-- DBLOG Migrate 
USE bodb_CustomerLog
GO

CREATE TABLE [dbo].[Age_ClearBalanceCust_ProcessHistory](
	[SessionDate] [smalldatetime] NOT NULL,
	[BatchNo] [int] NOT NULL,
	[SuperId] [int] NOT NULL,
	[FromCustId] [int] NOT NULL,
	[ToCustId] [int] NOT NULL,
	[RoleId] [int] NOT NULL,
	[Status] [varchar](15) NOT NULL,
	[Amount] [money] NULL,
	[Result] [nvarchar](MAX) NULL,
	[TryCount] [tinyint] NULL,
	[ModifiedTime] [datetime] NULL,
	[StartTime] [datetime] NULL,
	[EndTime] [datetime] NULL,
	[Creator] [int] NULL,
	[IsAllDayBalTransfer] [bit] NULL
) ON [DATA] 
GO

CREATE UNIQUE CLUSTERED INDEX [CIX_SessionDate] ON [dbo].[Age_ClearBalanceCust_ProcessHistory]
(
	[SessionDate] ASC,
	[FromCustId] ASC,
	[ToCustId] ASC
) ON [DATA]

GO

--TODO: Migrate data from DBARC to DBLOG
DROP TABLE IF EXISTS #tmpSessionDate;
CREATE TABLE #tmpSessionDate (rIdx INT IDENTITY(1, 1), SessionDate SMALLDATETIME);

INSERT INTO #tmpSessionDate (SessionDate)
SELECT SessionDate
FROM OPENQUERY(DBARC, 'SELECT DISTINCT SessionDate FROM bodb_Archive.dbo.Age_ClearBalanceCust_ProcessHistory WITH(NOLOCK) WHERE SessionDate <= ''2023-08-23''') AS rmt
ORDER BY SessionDate

DECLARE @rCount INT = 1, @rmtSQL NVARCHAR(MAX);

WHILE EXISTS (SELECT 1 FROM #tmpSessionDate WHERE rIdx = @rCount)
BEGIN

	SELECT @rmtSQL = N'
		INSERT INTO [dbo].[Age_ClearBalanceCust_ProcessHistory]
           ([SessionDate]
           ,[BatchNo]
           ,[SuperId]
           ,[FromCustId]
           ,[ToCustId]
           ,[RoleId]
           ,[Status]
           ,[Amount]
           ,[Result]
           ,[TryCount]
           ,[ModifiedTime]
           ,[StartTime]
           ,[EndTime]
           ,[Creator]
           ,[IsAllDayBalTransfer])
		SELECT [SessionDate]
           ,[BatchNo]
           ,[SuperId]
           ,[FromCustId]
           ,[ToCustId]
           ,[RoleId]
           ,[Status]
           ,[Amount]
           ,[Result]
           ,[TryCount]
           ,[ModifiedTime]
           ,[StartTime]
           ,[EndTime]
           ,[Creator]
           ,[IsAllDayBalTransfer]
		FROM OPENQUERY(DBARC, ''SELECT * FROM bodb_Archive.dbo.Age_ClearBalanceCust_ProcessHistory WITH(NOLOCK) WHERE SessionDate =''''' + FORMAT(SessionDate, 'yyyy-MM-dd')+ ''''''') AS rmt'
	FROM #tmpSessionDate
	WHERE rIdx = @rCount

	--SELECT @rCount, @rmtSQL AS [@rmtSQL]
	
	EXEC (@rmtSQL)

	SET @rCount += 1;
END
GO
