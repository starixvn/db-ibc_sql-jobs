SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE	[dbo].[Task_RNGCasinoMovement]
AS
/*
	Created by: Victor
	Date: 20140418
	Task: daily RNG Casino movement
	DB: DBTRANS.BODB02

	Revisions:
		- 20140418@Victor:	Initialize - [Redmine: #000000]
*/
BEGIN;
	SET NOCOUNT ON

	DECLARE @winlostdate DATETIME
	SELECT @winlostdate = DATEADD(dd, DATEDIFF(dd, 0, CURRENT_TIMESTAMP), 0)

	IF DATEPART(HOUR, CURRENT_TIMESTAMP) < 4 RETURN
		
	DECLARE @pendingticket TABLE (transid BIGINT)
	
	INSERT INTO @pendingticket (transid)
	SELECT transid
	FROM dbo.bettrans b WITH(NOLOCK)
			INNER JOIN CustDB.dbo.Dep_CustSuper s WITH(NOLOCK) ON b.srecommend = s.custid
	WHERE bettype = 23002 
		AND statusID = 0 
		AND winlostdate < @winlostdate
	
	IF @@ROWCOUNT = 0 RETURN
	
	UPDATE b
	SET winlostdate = @winlostdate
	FROM dbo.bettrans b WITH(UPDLOCK, ROWLOCK)
	WHERE bettype = 23002 
		AND statusID = 0
		AND transid IN (SELECT transid FROM @pendingticket)
	
	-- Write log
	DECLARE @Doing varchar(4000)
	SET @Doing = '[Task_RNGCasinoMovement] - updating winlostdate for RNG Casino pending tickets: ' + 
	STUFF((
		SELECT ',' + cast(transid as varchar(12)) 
		FROM @pendingticket 
		FOR XML PATH('')
	), 1,1,'')
	
	EXEC dbo.WriteLog_UserLog @UserID = 862400, @Doing = @Doing
END;
GO
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/