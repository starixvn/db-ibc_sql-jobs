/*<info serverAlias="DBTP-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_CheckWinlostdate_Consistency] @ErrMessage VARCHAR(512) = '' OUTPUT
	, @DebugMode BIT = 0
AS
/*
	Created: 20150216@Lukas
	Task: check data on replicated servers
	DB: DBTP/bodb02
	Revision:
		- 20160624@Patrick: Move SP to DBTP & Rearrange code [Redmine: #59643]
		- 20170417@Patrick: Due to OPS team perform change winlostdate at beginning a day as result data inconsistency between maninDB and replicatedDB
			so, we will skip the first the schedule for the job.
		- 20170809@Patrick: Exclude bettype 2799 for BetradarVS
		- 20200110@Patrick: Add more rule check winlostdate and eventdate is missmatch [Redmine: #126759]
		- 20200117@Patrick: Print result to easy checking & retry [Redmine: #126759]
		
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @winlostdate SMALLDATETIME,
			@rowcount INT,
			@__ignoreBettypeList VARCHAR(2000),
			@__sqlCmd NVARCHAR(MAX) = '',
			@__query NVARCHAR(MAX) = '',
			@__tryCount INT = 1
	
	Retry:		
	SELECT  @winlostdate = DATEADD(DAY, -1, CONVERT(VARCHAR(20), GETDATE(), 112)),
			@rowcount = 0

	SET @__ignoreBettypeList = '10,1231,1232,1233,1237,1238,31,32,33,2799'

	SET @__query = N''
	SET @__query = N'select @@ServerName svr, matchid, ''multiple winlostdate on bettrans'' as caseName 
	from bodb02.dbo.bettrans with(nolock)
	where winlostdate >= @winlostdate
		and matchid > 1000
		and bettype not in ('+ @__ignoreBettypeList +')	
	group by matchid 
	having MIN(winlostdate) <> MAX(winlostdate)'

	DECLARE @__result TABLE(serverName varchar(200), matchid int, caseName varchar(2000))

	--//DBTP
	SET @__sqlCmd = N''
	SET @__sqlCmd = N'EXECUTE bodb02.dbo.sp_executesql @__query, N''@winlostdate smalldatetime'', @winlostdate'
	INSERT INTO @__result
	EXECUTE	sys.sp_executesql @__sqlCmd, N'@__query NVARCHAR(MAX), @winlostdate smalldatetime', @__query, @winlostdate
	SET @rowcount = @rowcount + @@ROWCOUNT
	IF @rowcount > 0
		GOTO EndFlow

	--//DB06
	SET @__sqlCmd = N''
	SET @__sqlCmd = N'EXECUTE DBACC.bodb02.dbo.sp_executesql @__query, N''@winlostdate smalldatetime'', @winlostdate'
	INSERT INTO @__result
	EXECUTE	sys.sp_executesql @__sqlCmd, N'@__query NVARCHAR(MAX), @winlostdate smalldatetime', @__query, @winlostdate
	SET @rowcount = @rowcount + @@ROWCOUNT
	IF @rowcount > 0
		GOTO EndFlow
	
	--//DB05
	SET @__sqlCmd = N''
	SET @__sqlCmd = N'EXECUTE DB05.bodb02.dbo.sp_executesql @__query, N''@winlostdate smalldatetime'', @winlostdate'
	INSERT INTO @__result
	EXECUTE	sys.sp_executesql @__sqlCmd, N'@__query NVARCHAR(MAX), @winlostdate smalldatetime', @__query, @winlostdate
	SET @rowcount = @rowcount + @@ROWCOUNT
	IF @rowcount > 0
		GOTO EndFlow
	
	--//DB052
	SET @__sqlCmd = N''
	SET @__sqlCmd = N'EXECUTE DBEXT.bodb02.dbo.sp_executesql @__query, N''@winlostdate smalldatetime'', @winlostdate'
	INSERT INTO @__result
	EXECUTE	sys.sp_executesql @__sqlCmd, N'@__query NVARCHAR(MAX), @winlostdate smalldatetime', @__query, @winlostdate
	SET @rowcount = @rowcount + @@ROWCOUNT
	IF @rowcount > 0
		GOTO EndFlow
	
	--//DB053
	SET @__sqlCmd = N''
	SET @__sqlCmd = N'EXECUTE DBAGE.bodb02.dbo.sp_executesql @__query, N''@winlostdate smalldatetime'', @winlostdate'
	INSERT INTO @__result
	EXECUTE	sys.sp_executesql @__sqlCmd, N'@__query NVARCHAR(MAX), @winlostdate smalldatetime', @__query, @winlostdate
	SET @rowcount = @rowcount + @@ROWCOUNT
	IF @rowcount > 0
		GOTO EndFlow
	
	--//check winlostdate and eventdate is diff
	SET @__query = N''
	SET @__query = N'select @@ServerName svr, b.matchid, ''multiple winlostdate on bettrans & match'' as caseName 
	from bodb02.dbo.bettrans b with(nolock)
	inner join bodb02.dbo.match m with(nolock) on b.matchid = m.matchid
	where b.winlostdate >= @winlostdate
		and b.matchid > 1000
		and b.bettype not in ('+ @__ignoreBettypeList +')	
	group by b.matchid 
	having MIN(m.eventdate) <> MAX(b.winlostdate)'

	--//DBTP
	SET @__sqlCmd = N''
	SET @__sqlCmd = N'EXECUTE bodb02.dbo.sp_executesql @__query, N''@winlostdate smalldatetime'', @winlostdate'
	INSERT INTO @__result
	EXECUTE	sys.sp_executesql @__sqlCmd, N'@__query NVARCHAR(MAX), @winlostdate smalldatetime', @__query, @winlostdate
	SET @rowcount = @rowcount + @@ROWCOUNT
	IF @rowcount > 0
		GOTO EndFlow

	--//DB06
	SET @__sqlCmd = N''
	SET @__sqlCmd = N'EXECUTE DBACC.bodb02.dbo.sp_executesql @__query, N''@winlostdate smalldatetime'', @winlostdate'
	INSERT INTO @__result
	EXECUTE	sys.sp_executesql @__sqlCmd, N'@__query NVARCHAR(MAX), @winlostdate smalldatetime', @__query, @winlostdate
	SET @rowcount = @rowcount + @@ROWCOUNT
	IF @rowcount > 0
		GOTO EndFlow
	
	--//DB05
	SET @__sqlCmd = N''
	SET @__sqlCmd = N'EXECUTE DB05.bodb02.dbo.sp_executesql @__query, N''@winlostdate smalldatetime'', @winlostdate'
	INSERT INTO @__result
	EXECUTE	sys.sp_executesql @__sqlCmd, N'@__query NVARCHAR(MAX), @winlostdate smalldatetime', @__query, @winlostdate
	SET @rowcount = @rowcount + @@ROWCOUNT
	IF @rowcount > 0
		GOTO EndFlow
	
	--//DB052
	SET @__sqlCmd = N''
	SET @__sqlCmd = N'EXECUTE DBEXT.bodb02.dbo.sp_executesql @__query, N''@winlostdate smalldatetime'', @winlostdate'
	INSERT INTO @__result
	EXECUTE	sys.sp_executesql @__sqlCmd, N'@__query NVARCHAR(MAX), @winlostdate smalldatetime', @__query, @winlostdate
	SET @rowcount = @rowcount + @@ROWCOUNT
	IF @rowcount > 0
		GOTO EndFlow
	
	--//DB053
	SET @__sqlCmd = N''
	SET @__sqlCmd = N'EXECUTE DBAGE.bodb02.dbo.sp_executesql @__query, N''@winlostdate smalldatetime'', @winlostdate'
	INSERT INTO @__result
	EXECUTE	sys.sp_executesql @__sqlCmd, N'@__query NVARCHAR(MAX), @winlostdate smalldatetime', @__query, @winlostdate
	SET @rowcount = @rowcount + @@ROWCOUNT
	IF @rowcount > 0
		GOTO EndFlow

	EndFlow:
	IF @rowcount > 0
	BEGIN
		IF @__tryCount <= 3
		BEGIN
			DELETE FROM @__result
			SET @__tryCount = @__tryCount + 1
			WAITFOR DELAY '00:00:20:000'
			GOTO Retry
		END

		IF @DebugMode = 1
		BEGIN
			SELECT serverName AS s, matchid AS m, caseName AS c FROM @__result AS r FOR XML AUTO
		END

		DECLARE @__xmlOut VARCHAR(MAX)
		SET @__xmlOut = (SELECT TOP 100 serverName AS s, matchid AS m, caseName AS c FROM @__result AS r FOR XML AUTO)
		SET @__xmlOut = 'got tickets have wrong winlostdate. ==> output: ' +  @__xmlOut
		RAISERROR(@__xmlOut, 16, 1)
	END

END

GO
