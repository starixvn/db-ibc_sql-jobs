/*<info serverAlias="DBARC-bodb_Archive"></info>*/
/*
	Created: 20230815@Bobby
	Task: 182071 - Alpha - AutoJob ClearBalanceCust
	DB: DBARC.bodb_Archive
	
*/
USE [bodb_Archive]
GO

--TODO: Remove Duplicate rows - 7 rows
--Remark: Run on DB062 only
WITH CTE AS (
	SELECT ToCustId,
		ROW_NUMBER() OVER(PARTITION BY ToCustId ORDER BY ToCustId) AS DuplicateCount
	FROM [dbo].[Age_ClearBalanceCust_ProcessHistory] WITH(NOLOCK)
	WHERE SesssionDate = '2023-08-15'
)
DELETE FROM CTE
WHERE DuplicateCount > 1;


--TODO: Re-Create [CIX_SessionDate]
--Remark: Run on both DB061 and DB062
use [bodb_Archive];
GO
CREATE UNIQUE CLUSTERED INDEX [CIX_SessionDate] ON [dbo].[Age_ClearBalanceCust_ProcessHistory]
(
	[SessionDate] ASC,
	[FromCustId] ASC,
	[ToCustId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = ON, ONLINE = ON, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]

GO


--TODO: Sync data DB061 -- 139 rows
--Remark: Run on DB061
use [bodb_Archive];
GO
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
FROM OPENQUERY(DB06, 'SELECT * FROM [bodb_Archive].dbo.[Age_ClearBalanceCust_ProcessHistory] WITH(NOLOCK) WHERE SessionDate < ''2023-08-17''') AS rmt