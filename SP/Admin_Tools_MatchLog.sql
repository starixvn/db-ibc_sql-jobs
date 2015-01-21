USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Admin_Tools_MatchLog]    Script Date: 01/21/2015 02:01:35 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Admin_Tools_MatchLog]
	@matchid int,
	@SaveResult bit = 0
AS
SET NOCOUNT ON

create table #ul2 (logid int, userid int, doing  varchar(300), logdate datetime, tag varchar(20))

declare @odds TABLE (oddsid int, bettype varchar(20))
declare @evDate smalldatetime, @evDate_p1 smalldatetime
declare @minTransDate datetime

INSERT INTO @odds
SELECT oddsid, LEFT(bt.typenamee, 16) + ' :' + CAST(ROW_NUMBER() OVER (ORDER BY bettype) as nvarchar(3))
FROM dbo.odds14 o with (nolock)
	INNER JOIN dbo.bettype bt with (nolock) ON o.bettype = bt.typeid
WHERE matchid = @matchid

IF @@ROWCOUNT = 0
	INSERT INTO @odds
	SELECT oddsid, LEFT(bt.typenamee, 16) + ' :' + CAST(ROW_NUMBER() OVER (ORDER BY bettype) as nvarchar(3))
	FROM dbo.odds o with (nolock)
		INNER JOIN dbo.bettype bt with (nolock) ON o.bettype = bt.typeid
	WHERE matchid = @matchid

INSERT INTO @odds VALUES (@matchid, '..')

-- SET NOCOUNT ON

INSERT INTO #ul2
SELECT l.logid, l.userid, l.doing, l.logdate, o.bettype
FROM dbo.userlog l with (paglock)
	inner join @odds AS o ON l.extend = o.oddsid

--DROP TABLE #ul

Declare @LogData TABLE (username nvarchar(20),
logid int, userid int, doing nvarchar(300), logdate datetime,
bettype nvarchar(20), Catagory nvarchar(10))

INSERT INTO @LogData
SELECT *, case when doing like '%betting%' then 'Betting' else 'Admin' end Catagory
FROM ( 
	SELECT c.username, l.*
	FROM custinfo c with (nolock)
	INNER JOIN #ul2 l ON c.custid = l.userid 
 ) X --WHERE bettype <> '' --ORDER BY logid 

IF @SaveResult = 1
	INSERT INTO dbo.LogData SELECT *, @matchid FROM @LogData
ELSE
	SELECT * FROM @LogData ORDER BY logid

DROP TABLE #ul2

GO

GRANT VIEW DEFINITION ON [dbo].[Admin_Tools_MatchLog] TO [RDTim] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[Admin_Tools_MatchLog] TO [RDVivi] AS [dbo]
GO


