/*<info serverAlias="DBSIG-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Task_SiteDB_MoveBet_Manual_CheckMovement (
    @checkAction BIT = 0
    , @winlostdate SMALLDATETIME
)
AS
/*
 	Creator: 20220913@Bobby
	Task: DBSIG - Manual sync ticket
	DB: DBSIG/bodb02
	Revisions:
		- 20220913@Bobby: Initial [Redmine: #177760] 
 */
BEGIN

    --DECLARE @checkAction BIT = 0
    --    , @winlostdate SMALLDATETIME ='2022-09-08';

    DECLARE @tableName VARCHAR(100)
        , @actionName VARCHAR(100);

    DECLARE @siteDBGroupId SMALLINT
    SELECT @siteDBGroupId = dbo.f_Get_SiteDBGroupID();
    SELECT @siteDBGroupId AS [@siteDBGroupId], @@SERVERNAME AS [@@SERVERNAME], @winlostdate AS [@winlostdate];

    DROP TABLE IF EXISTS #tmp_cust;
    CREATE TABLE #tmp_cust(custid INT PRIMARY KEY)
    INSERT INTO #tmp_cust (custid)
    SELECT DISTINCT custid
    FROM CustDB.dbo.Customer WITH (NOLOCK)
    WHERE site IN ('Athena000','SampleSite');

    DROP TABLE IF EXISTS #tempTransIds;
    CREATE TABLE #tempTransIds(transid BIGINT PRIMARY KEY,[RepUpdateTime] DATETIME2,[RepDstUpdateTime] DATETIME2);

    DROP TABLE IF EXISTS #sourceBet;
    CREATE TABLE #sourceBet(ServerName VARCHAR(100), TableName VARCHAR(100), TransID BIGINT);

    DECLARE @sqlCMD NVARCHAR(MAX);

    SET @actionName = 'Movement';
    -- TODO-1: bettrans
    BEGIN
	    SET @tableName = 'bettrans';
        SET @sqlCMD = N'\
            WITH cte_source AS (
	            SELECT t.*
	            FROM OPENQUERY(DBCTG,
	                ''SELECT @@SERVERNAME AS ServerName, t.TransID
                    FROM bodb02.dbo.bettrans t WITH (nolock)
	                INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.custid = t.custid AND c.site IN (''''Athena000'''',''''SampleSite'''')
                    WHERE t.winlostdate = '''''+CONVERT(VARCHAR(20),@winlostdate,120)+'''''''
                ) AS t
            )
            INSERT INTO #sourceBet(ServerName, TableName, TransID)
            SELECT ServerName, @tableName, TransID
            FROM cte_source;\
        ';

        PRINT @sqlCMD;
        EXEC sp_executesql @sqlCMD, N'@tableName VARCHAR(100)',@tableName=@tableName;

        WITH cte_target AS (
            SELECT t.TransID
            FROM bodb02.dbo.bettrans t WITH (nolock)
	        INNER JOIN #tmp_cust c ON c.custid = t.custid
            WHERE t.winlostdate = @winlostdate
        )
        SELECT @actionName AS [Action], s.*, @@SERVERNAME AS ServerName, t.TransID
        FROM cte_target t
        LEFT JOIN #sourceBet s ON s.TransID = t.TransID AND s.TableName = @tableName
        WHERE s.TransID IS NULL;

        IF @checkAction = 1
        BEGIN
            TRUNCATE TABLE #tempTransIds;
            --TODO: UPDATE
            WITH cte_movement AS (
                SELECT t.TransID
                FROM bodb02.dbo.bettrans t WITH (nolock)
	            INNER JOIN #tmp_cust c ON c.custid = t.custid
                LEFT JOIN #sourceBet s ON s.TransID = t.TransID AND s.TableName = @tableName
                WHERE t.winlostdate = @winlostdate
                    AND s.TransID IS NULL
            ),
            cte_update AS (
                SELECT t.transid, TransDate,WinlostDate,Bettype,Stake,Actual_Stake,Winlost,AWinlost,MWinlost,SWinlost,PlayerComm,Comm,AComm,SComm,Status,StatusId,ActualRate,ruben
                FROM DBCTG.bodb02.dbo.bettrans t WITH(NOLOCK)
                INNER JOIN cte_movement mv ON mv.transid = t.transid
            )
            UPDATE t WITH(ROWLOCK, UPDLOCK)
            SET t.TransDate = u.TransDate
                ,t.WinlostDate = u.WinlostDate
                ,t.Bettype = u.Bettype
                ,t.Stake = u.Stake
                ,t.Actual_Stake = u.Actual_Stake
                ,t.Winlost = u.Winlost
                ,t.AWinlost = u.AWinlost
                ,t.MWinlost = u.MWinlost
                ,t.SWinlost = u.SWinlost
                ,t.PlayerComm = u.PlayerComm
                ,t.Comm = u.Comm
                ,t.AComm = u.AComm
                ,t.SComm = u.SComm
                ,t.Status = u.Status
                ,t.StatusId = u.StatusId
                ,t.ruben = u.ruben
                ,t.ActualRate = u.ActualRate
            FROM bodb02.dbo.bettrans t 
            INNER JOIN cte_update u ON u.transid = t.transid
            WHERE @siteDBGroupId = 1;
        END
    END
    -- TODO-2: bettransLC
    BEGIN
	    SET @tableName = 'bettransLC';
        SET @sqlCMD = N'\
        WITH cte_source AS (
	        SELECT t.*
	        FROM OPENQUERY(DBCTG,
	            ''SELECT @@SERVERNAME AS ServerName, t.TransID
                FROM bodb02.dbo.bettransLC t WITH (nolock)
	            INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.custid = t.custid AND c.site IN (''''Athena000'''',''''SampleSite'''')
                WHERE t.winlostdate = '''''+CONVERT(VARCHAR(20),@winlostdate,120)+'''''''
            ) AS t
        )
        INSERT INTO #sourceBet(ServerName, TableName, TransID)
        SELECT ServerName, @tableName, TransID
        FROM cte_source;\
        ';

        PRINT @sqlCMD;
        EXEC sp_executesql @sqlCMD, N'@tableName VARCHAR(100)',@tableName=@tableName;

        WITH cte_target AS (
            SELECT t.TransID
            FROM bodb02.dbo.bettransLC t WITH (nolock)
	        INNER JOIN #tmp_cust c ON c.custid = t.custid
            WHERE t.winlostdate = @winlostdate
        )
        SELECT @actionName AS [Action], s.*, @@SERVERNAME AS ServerName, t.TransID
        FROM cte_target t
        LEFT JOIN #sourceBet s ON s.TransID = t.TransID AND s.TableName = @tableName
        WHERE s.TransID IS NULL;

        IF @checkAction = 1
        BEGIN
            TRUNCATE TABLE #tempTransIds;
            --TODO: UPDATE
            WITH cte_movement AS (
                SELECT t.TransID
                FROM bodb02.dbo.bettransLC t WITH (nolock)
	            INNER JOIN #tmp_cust c ON c.custid = t.custid
                LEFT JOIN #sourceBet s ON s.TransID = t.TransID AND s.TableName = @tableName
                WHERE t.winlostdate = @winlostdate
                    AND s.TransID IS NULL
            ),
            cte_update AS (
                SELECT t.TransID,transdate,winlostdate,gameID,Stake,Actual_Stake,Winlost,AWinlost,MWinlost,SWinlost,PlayerComm,Comm,AComm,SComm,status,StatusId,TransDesc,ActualRate
                FROM DBCTG.bodb02.dbo.bettransLC t WITH (nolock)
                INNER JOIN cte_movement mv ON mv.transid = t.transid
            )
            UPDATE t WITH(ROWLOCK,UPDLOCK)
            SET t.transdate = u.transdate
                ,t.winlostdate = u.winlostdate
                ,t.gameID = u.gameID
                ,t.Stake = u.Stake
                ,t.Actual_Stake = u.Actual_Stake
                ,t.Winlost = u.Winlost
                ,t.AWinlost = u.AWinlost
                ,t.MWinlost = u.MWinlost
                ,t.SWinlost = u.SWinlost
                ,t.PlayerComm = u.PlayerComm
                ,t.Comm = u.Comm
                ,t.AComm = u.AComm
                ,t.SComm = u.SComm
                ,t.status = u.status
                ,t.StatusId = u.StatusId
                ,t.TransDesc = u.TransDesc
                ,t.ActualRate = u.ActualRate
            FROM bodb02.dbo.bettransLC t
            INNER JOIN cte_update u ON u.transid = t.transid
            WHERE @siteDBGroupId = 1;
        END
    END
    -- TODO-3: bettransRNG
    BEGIN
	    SET @tableName = 'bettransRNG';
        SET @sqlCMD = N'\
        WITH cte_source AS (
	        SELECT t.*
	        FROM OPENQUERY(DBCTG,
	            ''SELECT @@SERVERNAME AS ServerName, t.TransID
                FROM bodb02.dbo.bettransRNG t WITH (nolock)
	            INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.custid = t.custid AND c.site IN (''''Athena000'',''''SampleSite'''')
                WHERE t.winlostdate = '''''+CONVERT(VARCHAR(20),@winlostdate,120)+'''''''
            ) AS t
        )
        INSERT INTO #sourceBet(ServerName, TableName, TransID)
        SELECT ServerName, @tableName, TransID
        FROM cte_source;\
        ';

        PRINT @sqlCMD;
        EXEC sp_executesql @sqlCMD, N'@tableName VARCHAR(100)',@tableName=@tableName;

        WITH cte_target AS (
            SELECT t.TransID
            FROM bodb02.dbo.bettransRNG t WITH (nolock)
	        INNER JOIN #tmp_cust c ON c.custid = t.custid
            WHERE t.winlostdate = @winlostdate
        )
        SELECT @actionName AS [Action], s.*, @@SERVERNAME AS ServerName, t.TransID
        FROM cte_target t
        LEFT JOIN #sourceBet s ON s.TransID = t.TransID AND s.TableName = @tableName
        WHERE s.TransID IS NULL;

        IF @checkAction = 1
        BEGIN
            TRUNCATE TABLE #tempTransIds;
            --TODO: UPDATE
            WITH cte_movement AS (
                SELECT t.TransID
                FROM bodb02.dbo.bettransRNG t WITH (nolock)
	            INNER JOIN #tmp_cust c ON c.custid = t.custid
                LEFT JOIN #sourceBet s ON s.TransID = t.TransID AND s.TableName = @tableName
                WHERE t.winlostdate = @winlostdate
                    AND s.TransID IS NULL
            ),
            cte_update AS (
                SELECT t.transid,transdate,winlostdate,gameID,Stake,Actual_Stake,Winlost,AWinlost,MWinlost,SWinlost,PlayerComm,Comm,AComm,SComm,status,StatusId,TransDesc,ActualRate
                FROM DBCTG.bodb02.dbo.bettransRNG t WITH (nolock) 
                INNER JOIN cte_movement mv ON mv.transid = t.transid
            )
            UPDATE t WITH(ROWLOCK,UPDLOCK)
            SET t.transdate = u.transdate
                ,t.winlostdate = u.winlostdate
                ,t.gameID = u.gameID
                ,t.Stake = u.Stake
                ,t.Actual_Stake = u.Actual_Stake
                ,t.Winlost = u.Winlost
                ,t.AWinlost = u.AWinlost
                ,t.MWinlost = u.MWinlost
                ,t.SWinlost = u.SWinlost
                ,t.PlayerComm = u.PlayerComm
                ,t.Comm = u.Comm
                ,t.AComm = u.AComm
                ,t.SComm = u.SComm
                ,t.status = u.status
                ,t.StatusId = u.StatusId
                ,t.TransDesc = u.TransDesc
                ,t.ActualRate = u.ActualRate
            FROM bodb02.dbo.bettransRnG t
            INNER JOIN cte_update u ON u.transid = t.transid
            WHERE @siteDBGroupId = 1; 
        END
    END
    -- TODO-4: bettransG
    BEGIN
	    SET @tableName = 'bettransG';
        SET @sqlCMD = N'\
        WITH cte_source AS (
	        SELECT t.*
	        FROM OPENQUERY(DBCTG,
	            ''SELECT @@SERVERNAME AS ServerName, t.TransID
                FROM bodb02.dbo.bettransG t WITH (nolock)
	            INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.custid = t.custid AND c.site IN (''''Athena000'''',''''SampleSite'''')
                WHERE t.winlostdate = '''''+CONVERT(VARCHAR(20),@winlostdate,120)+'''''''
            ) AS t
        )
        INSERT INTO #sourceBet(ServerName, TableName, TransID)
        SELECT ServerName, @tableName, TransID
        FROM cte_source;\
        ';

        PRINT @sqlCMD;
        EXEC sp_executesql @sqlCMD, N'@tableName VARCHAR(100)',@tableName=@tableName;

        WITH cte_target AS (
            SELECT t.TransID
            FROM bodb02.dbo.bettransG t WITH (nolock)
	        INNER JOIN #tmp_cust c ON c.custid = t.custid
            WHERE t.winlostdate = @winlostdate
        )
        SELECT @actionName AS [Action], s.*, @@SERVERNAME AS ServerName, t.TransID
        FROM cte_target t
        LEFT JOIN #sourceBet s ON s.TransID = t.TransID AND s.TableName = @tableName
        WHERE s.TransID IS NULL;

        IF @checkAction = 1
        BEGIN
            TRUNCATE TABLE #tempTransIds;
            --TODO: UPDATE
            WITH cte_movement AS (
                SELECT t.TransID
                FROM bodb02.dbo.bettransG t WITH (nolock)
	            INNER JOIN #tmp_cust c ON c.custid = t.custid
                LEFT JOIN #sourceBet s ON s.TransID = t.TransID AND s.TableName = @tableName
                WHERE t.winlostdate = @winlostdate
                    AND s.TransID IS NULL
            ),
            cte_update AS (
                SELECT t.transid,transdate,winlostdate,bettype,Stake,Actual_Stake,Winlost,AWinlost,MWinlost,SWinlost,PlayerComm,Comm,AComm,SComm,status,StatusId,TransDesc,ActualRate
                FROM DBCTG.bodb02.dbo.bettransG t WITH (nolock) 
                INNER JOIN cte_movement mv ON mv.transid = t.transid
            )
            UPDATE t WITH(ROWLOCK,UPDLOCK)
            SET t.transdate = u.transdate
                ,t.winlostdate = u.winlostdate
                ,t.bettype = u.bettype
                ,t.Stake = u.Stake
                ,t.Actual_Stake = u.Actual_Stake
                ,t.Winlost = u.Winlost
                ,t.AWinlost = u.AWinlost
                ,t.MWinlost = u.MWinlost
                ,t.SWinlost = u.SWinlost
                ,t.PlayerComm = u.PlayerComm
                ,t.Comm = u.Comm
                ,t.AComm = u.AComm
                ,t.SComm = u.SComm
                ,t.status = u.status
                ,t.StatusId = u.StatusId
                ,t.TransDesc = u.TransDesc
                ,t.ActualRate = u.ActualRate
            FROM bodb02.dbo.bettransG t
            INNER JOIN cte_update u ON u.transid = t.transid
            WHERE @siteDBGroupId = 1;
        END
    END
    -- TODO-5: bettransM
    BEGIN
	    SET @tableName = 'bettransM';
        SET @sqlCMD = N'\
        WITH cte_source AS (
	        SELECT t.*
	        FROM OPENQUERY(DBCTG,
	            ''SELECT @@SERVERNAME AS ServerName, t.TransID
                FROM bodb02.dbo.bettransM t WITH (nolock)
	            INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.custid = t.custid AND c.site IN (''''Athena000'''',''''SampleSite'''')
                WHERE t.winlostdate = '''''+CONVERT(VARCHAR(20),@winlostdate,120)+'''''''
            ) AS t
        )
        INSERT INTO #sourceBet(ServerName, TableName, TransID)
        SELECT ServerName, @tableName, TransID
        FROM cte_source;\
        ';

        PRINT @sqlCMD;
        EXEC sp_executesql @sqlCMD, N'@tableName VARCHAR(100)',@tableName=@tableName;

        WITH cte_target AS (
            SELECT t.TransID
            FROM bodb02.dbo.bettransM t WITH (nolock)
	        INNER JOIN #tmp_cust c ON c.custid = t.custid
            WHERE t.winlostdate = @winlostdate
        )
        SELECT @actionName AS [Action], s.*, @@SERVERNAME AS ServerName, t.TransID
        FROM cte_target t
        LEFT JOIN #sourceBet s ON s.TransID = t.TransID AND s.TableName = @tableName
        WHERE s.TransID IS NULL;

        IF @checkAction = 1
        BEGIN
            TRUNCATE TABLE #tempTransIds;
            --TODO: UPDATE
            WITH cte_movement AS (
                SELECT t.TransID
                FROM bodb02.dbo.bettransM t WITH (nolock)
	            INNER JOIN #tmp_cust c ON c.custid = t.custid
                LEFT JOIN #sourceBet s ON s.TransID = t.TransID AND s.TableName = @tableName
                WHERE t.winlostdate = @winlostdate
                    AND s.TransID IS NULL
            ),
            cte_update AS (
                SELECT t.transid,transdate,winlostdate,bettype,Stake,Winlost,AWinlost,MWinlost,SWinlost,PlayerComm,Comm,AComm,SComm,Status,StatusId,TransDesc,ActualRate
                FROM DBCTG.bodb02.dbo.bettransM t WITH (nolock) 
                INNER JOIN cte_movement mv ON mv.transid = t.transid
            )
            UPDATE t WITH(ROWLOCK,UPDLOCK)
            SET t.transdate = u.transdate
                ,t.winlostdate = u.winlostdate
                ,t.bettype = u.bettype
                ,t.Stake = u.Stake
                ,t.Winlost = u.Winlost
                ,t.AWinlost = u.AWinlost
                ,t.MWinlost = u.MWinlost
                ,t.SWinlost = u.SWinlost
                ,t.PlayerComm = u.PlayerComm
                ,t.Comm = u.Comm
                ,t.AComm = u.AComm
                ,t.SComm = u.SComm
                ,t.Status = u.Status
                ,t.StatusId = u.StatusId
                ,t.TransDesc = u.TransDesc
                ,t.ActualRate = u.ActualRate
            FROM bodb02.dbo.bettransM t
            INNER JOIN cte_update u ON u.transid = t.transid
            WHERE @siteDBGroupId = 1;
        END
    END
    -- TODO-6: translog
    BEGIN
	    SET @tableName = 'translog';
        SET @sqlCMD = N'\
        WITH cte_source AS (
	        SELECT t.*
	        FROM OPENQUERY(DBCTG,
	            ''SELECT @@SERVERNAME AS ServerName, t.translogid AS TransID
                FROM bodb02.dbo.translog t WITH (nolock)
	            INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.custid = t.custid AND c.site IN (''''Athena000'''',''''SampleSite'''')
                WHERE t.winlostdate = '''''+CONVERT(VARCHAR(20),@winlostdate,120)+'''''''
            ) AS t
        )
        INSERT INTO #sourceBet(ServerName, TableName, TransID)
        SELECT ServerName, @tableName, TransID
        FROM cte_source;\
        ;';

        PRINT @sqlCMD;
        EXEC sp_executesql @sqlCMD, N'@tableName VARCHAR(100)',@tableName=@tableName;

        WITH cte_target AS (
            SELECT t.translogid
            FROM bodb02.dbo.translog t WITH (nolock)
	        INNER JOIN #tmp_cust c ON c.custid = t.custid
            WHERE t.winlostdate = @winlostdate
        )
        SELECT @actionName AS [Action], s.*, @@SERVERNAME AS ServerName, t.translogid
        FROM cte_target t
        LEFT JOIN #sourceBet s ON s.TransID = t.translogid AND s.TableName = @tableName
        WHERE s.TransID IS NULL;

        IF @checkAction = 1
        BEGIN
            TRUNCATE TABLE #tempTransIds;
            --TODO: UPDATE
            WITH cte_movement AS (
                SELECT t.translogid
                FROM bodb02.dbo.translog t WITH (nolock)
	            INNER JOIN #tmp_cust c ON c.custid = t.custid
                LEFT JOIN #sourceBet s ON s.TransID = t.translogid AND s.TableName = @tableName
                WHERE t.winlostdate = @winlostdate
                    AND s.TransID IS NULL
            )
            ,
            cte_update AS (
                SELECT t.translogid,transdate,winlostdate,gameID,Stake,Status,StatusId,TransDesc,ActualRate
                FROM DBCTG.bodb02.dbo.translog t WITH (nolock) 
                INNER JOIN cte_movement mv ON mv.translogid = t.translogid
            )
            UPDATE t WITH(ROWLOCK,UPDLOCK)
            SET t.transdate = u.transdate
                ,t.winlostdate = u.winlostdate
                ,t.gameID = u.gameID
                ,t.Stake = u.Stake
                ,t.Status = u.Status
                ,t.StatusId = u.StatusId
                ,t.TransDesc = u.TransDesc
                ,t.ActualRate = u.ActualRate
            FROM bodb02.dbo.translog t
            INNER JOIN cte_update u ON u.translogid = t.translogid
            WHERE @siteDBGroupId = 1;
        END
    END
END 
GO
