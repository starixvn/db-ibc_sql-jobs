/*<info serverAlias="DBSIG-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Task_SiteDB_MoveBet_Manual_CheckOverridden (
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
    CREATE TABLE #sourceBet(ServerName VARCHAR(100), TableName VARCHAR(100), TransID BIGINT, chkSum BIGINT, [FlagAction] VARCHAR(50));

    DECLARE @sqlCMD NVARCHAR(MAX);
    SET @actionName = 'Overridden';
    -- TODO-1: bettrans
    BEGIN 
	    SET @tableName = 'bettrans';
        SET @sqlCMD = N'\
        WITH cte_source AS (
	        SELECT t.*
	        FROM OPENQUERY(DBCTG,
	            ''SELECT @@SERVERNAME AS ServerName, t.*
                FROM bodb02.dbo.bettrans t WITH (nolock)
	            INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.custid = t.custid AND c.site IN (''''Athena000'''',''''SampleSite'''')
                WHERE t.winlostdate = '''''+CONVERT(VARCHAR(20),@winlostdate,120)+'''''''
            ) AS t
        ),
        source_CheckSum AS (
            SELECT ServerName, transid, binary_checksum(convert(varchar(50), TransDate, 121),convert(varchar(50), WinlostDate, 121),Bettype,Stake,Actual_Stake,Winlost,AWinlost,MWinlost,SWinlost,PlayerComm,Comm,AComm,SComm,StatusId,TransDesc,Recommend,MRecommend,SRecommend,Username,Currency,CurrencyName,ActualRate) AS chkSum
            FROM cte_source
        ), 
	    cte_siteDB AS (
		    SELECT t.TransID, binary_checksum(convert(varchar(50), TransDate, 121),convert(varchar(50), WinlostDate, 121),Bettype,Stake,Actual_Stake,Winlost,AWinlost,MWinlost,SWinlost,PlayerComm,Comm,AComm,SComm,StatusId,TransDesc,Recommend,MRecommend,SRecommend,Username,Currency,CurrencyName,ActualRate) AS chkSum
		    FROM bodb02.dbo.bettrans t WITH (nolock) 
		    INNER JOIN source_CheckSum s ON s.transid = t.transid 
	    ),
        cte_Final AS (
            SELECT s.*
                , CASE 
                    WHEN t.TransID IS NULL THEN ''Missed Row''
                    WHEN s.TransID IS NULL THEN ''Delete Row''
                    WHEN ISNULL(s.chkSum,0) <> ISNULL(t.chkSum,0) THEN ''Diff Values''
                   END AS [FlagAction]
            FROM source_CheckSum s
            FULL JOIN cte_siteDB t ON t.transid = s.transid
	        WHERE (
                    t.TransID IS NULL 
                    OR s.TransID IS NULL 
                    OR ISNULL(s.chkSum,0) <> ISNULL(t.chkSum,0)
               )
        )
	    INSERT INTO #sourceBet(ServerName, TableName, TransID, chkSum, FlagAction)
        SELECT ServerName, @tableName, TransID, chkSum, FlagAction
        FROM cte_Final;\
        ';

        --PRINT @sqlCMD;
        EXEC sp_executesql @sqlCMD, N'@tableName VARCHAR(100)',@tableName=@tableName;

        -- RESULT STATUS
        SELECT @actionName AS [Action], s.* 
        FROM #sourceBet s WHERE TableName = @tableName;

        IF (@checkAction = 1
            AND EXISTS (SELECT 1 FROM #sourceBet s WHERE s.TableName = @tableName AND s.FlagAction IS NOT NULL)
        )
        BEGIN
            TRUNCATE TABLE #tempTransIds;
            --TODO: UPDATE
		    SET @sqlCMD = N'\
            WITH cte_update AS (
	            SELECT *
	            FROM OPENQUERY(DBCTG,
	                    ''SELECT t.* 
                        FROM bodb02.dbo.bettrans t WITH (nolock)
	                    INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.custid = t.custid AND c.site IN (''''Athena000'''',''''SampleSite'''')
                        WHERE t.winlostdate = '''''+CONVERT(VARCHAR(20),@winlostdate,120)+'''''''
                ) AS t
            )
            UPDATE t WITH(ROWLOCK,UPDLOCK)
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
            INNER JOIN #sourceBet chk ON chk.transid = u.transid 
            WHERE @siteDBGroupId = 1 
                AND chk.TableName = @tableName
                AND chk.[FlagAction] = ''Diff Values'';\
		    ';
		    --print @sqlCMD;
		    EXEC sp_executesql @sqlCMD, N'@tableName VARCHAR(100), @siteDBGroupId SMALLINT',@tableName=@tableName,@siteDBGroupId=@siteDBGroupId;

            --TODO: INSERT
		    SET @sqlCMD = N'\
            WITH cte_source AS (
	            SELECT *
	            FROM OPENQUERY(DBCTG,
	                    ''SELECT t.* 
                        FROM bodb02.dbo.bettrans t WITH (nolock)
	                    INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.custid = t.custid AND c.site IN (''''Athena000'''',''''SampleSite'''')
                        WHERE t.winlostdate = '''''+CONVERT(VARCHAR(20),@winlostdate,120)+'''''''
                ) AS t
            )
            INSERT INTO bodb02.dbo.bettrans([transid],[custid],[transdate],[oddsid],[hdp1],[hdp2],[odds],[stake],[status],[winlost],[awinlost],[mwinlost],[playercomm]
		        ,[comm],[acomm],[apositiontaking],[mpositiontaking],[tpositiontaking],[playerdiscount],[discount],[adiscount],[livehomescore],[liveawayscore]
		        ,[liveindicator],[betteam],[creator],[refno],[comstatus],[winlostdate],[betfrom],[betcheck],[checktime],[oddsspread],[actualrate],[matchid]
		        ,[recommend],[mrecommend],[ruben],[betid],[statuswinlost],[modds],[bettype],[betdaqid],[actual_stake],[currency],[ip],[transdesc],[sdiscount]
		        ,[scomm],[spositiontaking],[swinlost],[srecommend],[Username],[CurrencyName],[virtualrate],[oddstype],[statusID],[currency2],[balance],[SecAcceptFlag]
		        ,[transid2],[recommdate],[ExtraInfo],[WalletType],[BonusID],[RefCode],[SettlementTime],[epositiontaking],[ReasonID],[sort],[BetSiteID]
                ,[RepUpdateTime],[RepDstUpdateTime],[SiteDBGroupID],[FcUpdateTime])
	        SELECT s.[transid],[custid],[transdate],[oddsid],[hdp1],[hdp2],[odds],[stake],[status],[winlost],[awinlost],[mwinlost],[playercomm]
		        ,[comm],[acomm],[apositiontaking],[mpositiontaking],[tpositiontaking],[playerdiscount],[discount],[adiscount],[livehomescore],[liveawayscore]
		        ,[liveindicator],[betteam],[creator],[refno],[comstatus],[winlostdate],[betfrom],[betcheck],[checktime],[oddsspread],[actualrate],[matchid]
		        ,[recommend],[mrecommend],[ruben],[betid],[statuswinlost],[modds],[bettype],[betdaqid],[actual_stake],[currency],[ip],[transdesc],[sdiscount]
		        ,[scomm],[spositiontaking],[swinlost],[srecommend],[Username],[CurrencyName],[virtualrate],[oddstype],[statusID],[currency2],[balance],[SecAcceptFlag]
		        ,[transid2],[recommdate],[ExtraInfo],[WalletType],[BonusID],[RefCode],[SettlementTime],[epositiontaking],[ReasonID],[sort],[BetSiteID]
                ,[RepUpdateTime],[RepDstUpdateTime],[SiteDBGroupID],[FcUpdateTime]
            FROM cte_source s
            INNER JOIN #sourceBet chk ON chk.transid = s.transid
		    WHERE @siteDBGroupId = 1
                AND chk.TableName = @tableName
                AND chk.[FlagAction] = ''Missed Row'';\
		    ';
		    --print @sqlCMD;
		    EXEC sp_executesql @sqlCMD, N'@tableName VARCHAR(100), @siteDBGroupId SMALLINT',@tableName=@tableName,@siteDBGroupId=@siteDBGroupId;
        END
    END

    -- TODO-2: bettransLC
    BEGIN 
	    SET @tableName = 'bettransLC';
        SET @sqlCMD = N'\
        WITH cte_source AS (
	        SELECT t.*
	        FROM OPENQUERY(DBCTG,
	            ''SELECT @@SERVERNAME AS ServerName, t.*
                FROM bodb02.dbo.bettransLC t WITH (nolock)
	            INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.custid = t.custid AND c.site IN (''''Athena000'''',''''SampleSite'''')
                WHERE t.winlostdate = '''''+CONVERT(VARCHAR(20),@winlostdate,120)+'''''''
            ) AS t
        ), source_CheckSum AS (
            SELECT ServerName, transid, binary_checksum(convert(varchar(50), TransDate, 121),convert(varchar(50), WinlostDate, 121),gameID,Stake,Actual_Stake,Winlost,AWinlost,MWinlost,SWinlost,PlayerComm,Comm,AComm,SComm,StatusId,TransDesc,Recommend,MRecommend,SRecommend,Username,Currency,CurrencyName,ActualRate) AS chkSum
            FROM cte_source
        ), 
	    cte_siteDB AS (
		    SELECT t.TransID, binary_checksum(convert(varchar(50), TransDate, 121),convert(varchar(50), WinlostDate, 121),gameID,Stake,Actual_Stake,Winlost,AWinlost,MWinlost,SWinlost,PlayerComm,Comm,AComm,SComm,StatusId,TransDesc,Recommend,MRecommend,SRecommend,Username,Currency,CurrencyName,ActualRate) AS chkSum
		    FROM bodb02.dbo.bettransLC t WITH (nolock) 
		    INNER JOIN source_CheckSum s ON s.transid = t.transid 
	    ),
        cte_Final AS (
            SELECT s.*
                , CASE 
                    WHEN t.TransID IS NULL THEN ''Missed Row''
                    WHEN s.TransID IS NULL THEN ''Delete Row''
                    WHEN ISNULL(s.chkSum,0) <> ISNULL(t.chkSum,0) THEN ''Diff Values''
                   END AS [FlagAction]
            FROM source_CheckSum s
            FULL JOIN cte_siteDB t ON t.transid = s.transid
	        WHERE (
                    t.TransID IS NULL 
                    OR s.TransID IS NULL 
                    OR ISNULL(s.chkSum,0) <> ISNULL(t.chkSum,0)
               )
        )
	    INSERT INTO #sourceBet(ServerName, TableName, TransID, chkSum, FlagAction)
        SELECT ServerName, @tableName, TransID, chkSum, FlagAction
        FROM cte_Final;\
        ';

        EXEC sp_executesql @sqlCMD, N'@tableName VARCHAR(100)',@tableName=@tableName;

        -- RESULT STATUS
        SELECT @actionName AS [Action], s.* 
        FROM #sourceBet s WHERE TableName = @tableName;

         IF (@checkAction = 1
            AND EXISTS (SELECT 1 FROM #sourceBet s WHERE s.TableName = @tableName AND s.FlagAction IS NOT NULL)
        )
        BEGIN
            --TODO: UPDATE
            SET @sqlCMD = N'\
            WITH cte_source AS (
	            SELECT *
	            FROM OPENQUERY(DBCTG,
	                    ''SELECT t.* 
                        FROM bodb02.dbo.bettransLC t WITH (nolock)
	                    INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.custid = t.custid AND c.site IN (''''Athena000'''',''''SampleSite'''')
                        WHERE t.winlostdate = '''''+CONVERT(VARCHAR(20),@winlostdate,120)+'''''''
                ) AS t
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
            INNER JOIN cte_source u ON u.transid = t.transid
            INNER JOIN #sourceBet chk ON chk.TransID = u.transid
            WHERE @siteDBGroupId = 1 
                AND TableName = @tableName
                AND chk.[FlagAction] = ''Diff Values'';\
            ';

            --print @sqlCMD;
		    EXEC sp_executesql @sqlCMD, N'@tableName VARCHAR(100), @siteDBGroupId SMALLINT',@tableName=@tableName,@siteDBGroupId=@siteDBGroupId;

            --TODO: INSERT
            SET @sqlCMD = N'\
            WITH cte_source AS (
	            SELECT *
	            FROM OPENQUERY(DBCTG,
	                    ''SELECT t.* 
                        FROM bodb02.dbo.bettransLC t WITH (nolock)
	                    INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.custid = t.custid AND c.site IN (''''Athena000'''',''''SampleSite'''')
                        WHERE t.winlostdate = '''''+CONVERT(VARCHAR(20),@winlostdate,120)+'''''''
                ) AS t
            )
            INSERT INTO bodb02.dbo.bettransLC([transid], [custid], [transdate], [odds], [stake], [status], [apositiontaking], [mpositiontaking], [tpositiontaking], [spositiontaking], [playerdiscount], [discount], [adiscount], [sdiscount], [creator], [winlostdate], [betfrom], [virtualrate], [actualrate], [actual_stake], [currency], [CurrencyName], [recommend], [mrecommend], [srecommend], [ip], [statusID], [balance], [Username], [transdesc], [productID], [gameID], [vendorID], [GameId3rd], [TranId3rd], [RefNo], [IsSum], [winlost], [awinlost], [mwinlost], [swinlost], [playercomm], [comm], [acomm], [scomm], [Transdate3rd], [NetStake], [SiteID], [epositiontaking], [RepUpdateTime], [SiteDBGroupID])
	        SELECT s.[transid], [custid], [transdate], [odds], [stake], [status], [apositiontaking], [mpositiontaking], [tpositiontaking], [spositiontaking], [playerdiscount], [discount], [adiscount], [sdiscount], [creator], [winlostdate], [betfrom], [virtualrate], [actualrate], [actual_stake], [currency], [CurrencyName], [recommend], [mrecommend], [srecommend], [ip], [statusID], [balance], [Username], [transdesc], [productID], [gameID], [vendorID], [GameId3rd], [TranId3rd], [RefNo], [IsSum], [winlost], [awinlost], [mwinlost], [swinlost], [playercomm], [comm], [acomm], [scomm], [Transdate3rd], [NetStake], [SiteID], [epositiontaking], [RepUpdateTime], [SiteDBGroupID]
            FROM cte_source s
		    INNER JOIN #sourceBet chk ON chk.transid = s.transid
		    WHERE @siteDBGroupId = 1
                AND chk.TableName = @tableName
                AND chk.[FlagAction] = ''Missed Row'';\
            ';

            --print @sqlCMD;
		    EXEC sp_executesql @sqlCMD, N'@tableName VARCHAR(100), @siteDBGroupId SMALLINT',@tableName=@tableName,@siteDBGroupId=@siteDBGroupId;
        END
    END
    -- TODO-3: bettransRNG
    BEGIN 
	    SET @tableName = 'bettransRNG';
        SET @sqlCMD = N'\
        WITH cte_source AS (
	        SELECT t.*
	        FROM OPENQUERY(DBCTG,
	            ''SELECT @@SERVERNAME AS ServerName, t.*
                FROM bodb02.dbo.bettransRNG t WITH (nolock)
	            INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.custid = t.custid AND c.site IN (''''Athena000'''',''''SampleSite'''')
                WHERE t.winlostdate = '''''+CONVERT(VARCHAR(20),@winlostdate,120)+'''''''
            ) AS t
        ), source_CheckSum AS (
            SELECT ServerName, transid, binary_checksum(convert(varchar(50), TransDate, 121),convert(varchar(50), WinlostDate, 121),gameID,Stake,Actual_Stake,Winlost,AWinlost,MWinlost,SWinlost,PlayerComm,Comm,AComm,SComm,StatusId,TransDesc,Recommend,MRecommend,SRecommend,Username,Currency,CurrencyName,ActualRate) AS chkSum
            FROM cte_source
        ), 
	    cte_siteDB AS (
		    SELECT t.TransID, binary_checksum(convert(varchar(50), TransDate, 121),convert(varchar(50), WinlostDate, 121),gameID,Stake,Actual_Stake,Winlost,AWinlost,MWinlost,SWinlost,PlayerComm,Comm,AComm,SComm,StatusId,TransDesc,Recommend,MRecommend,SRecommend,Username,Currency,CurrencyName,ActualRate) AS chkSum
		    FROM bodb02.dbo.bettransRNG t WITH (nolock) 
		    INNER JOIN source_CheckSum s ON s.transid = t.transid 
	    ),
        cte_Final AS (
            SELECT s.*
                , CASE 
                    WHEN t.TransID IS NULL THEN ''Missed Row''
                    WHEN s.TransID IS NULL THEN ''Delete Row''
                    WHEN ISNULL(s.chkSum,0) <> ISNULL(t.chkSum,0) THEN ''Diff Values''
                   END AS [FlagAction]
            FROM source_CheckSum s
            FULL JOIN cte_siteDB t ON t.transid = s.transid
	        WHERE (
                    t.TransID IS NULL 
                    OR s.TransID IS NULL 
                    OR ISNULL(s.chkSum,0) <> ISNULL(t.chkSum,0)
               )
        )
	    INSERT INTO #sourceBet(ServerName, TableName, TransID, chkSum, FlagAction)
        SELECT ServerName, @tableName, TransID, chkSum, FlagAction
        FROM cte_Final;\
        ';

        EXEC sp_executesql @sqlCMD, N'@tableName VARCHAR(100)',@tableName=@tableName;

        -- RESULT STATUS
        SELECT @actionName AS [Action], s.* 
        FROM #sourceBet s WHERE TableName = @tableName;

         IF (@checkAction = 1
            AND EXISTS (SELECT 1 FROM #sourceBet s WHERE s.TableName = @tableName AND s.FlagAction IS NOT NULL)
        )
        BEGIN
            --TODO: UPDATE
            SET @sqlCMD = N'\
            WITH cte_source AS (
	            SELECT *
	            FROM OPENQUERY(DBCTG,
	                    ''SELECT t.* 
                        FROM bodb02.dbo.bettransRNG t WITH (nolock)
	                    INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.custid = t.custid AND c.site IN (''''Athena000'''',''''SampleSite'''')
                        WHERE t.winlostdate = '''''+CONVERT(VARCHAR(20),@winlostdate,120)+'''''''
                ) AS t
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
            FROM bodb02.dbo.bettransRNG t
            INNER JOIN cte_source u ON u.transid = t.transid
            INNER JOIN #sourceBet chk ON chk.TransID = u.transid
            WHERE @siteDBGroupId = 1 
                AND chk.TableName = @tableName
                AND chk.[FlagAction] = ''Diff Values'';\
            ';

            --print @sqlCMD;
		    EXEC sp_executesql @sqlCMD, N'@tableName VARCHAR(100), @siteDBGroupId SMALLINT',@tableName=@tableName,@siteDBGroupId=@siteDBGroupId;

            --TODO: INSERT
            SET @sqlCMD = N'\
            WITH cte_source AS (
	            SELECT *
	            FROM OPENQUERY(DBCTG,
	                    ''SELECT t.* 
                        FROM bodb02.dbo.bettransRNG t WITH (nolock)
	                    INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.custid = t.custid AND c.site IN (''Athena000'''',''''SampleSite'''')
                        WHERE t.winlostdate = '''''+CONVERT(VARCHAR(20),@winlostdate,120)+'''''''
                ) AS t
            )
            INSERT INTO bodb02.dbo.bettransRNG([transid], [custid], [transdate], [odds], [stake], [status], [apositiontaking], [mpositiontaking], [tpositiontaking], [spositiontaking], [playerdiscount], [discount], [adiscount], [sdiscount], [creator], [winlostdate], [betfrom], [virtualrate], [actualrate], [actual_stake], [currency], [CurrencyName], [recommend], [mrecommend], [srecommend], [ip], [statusID], [balance], [Username], [transdesc], [productID], [gameID], [vendorID], [GameId3rd], [TranId3rd], [RefNo], [IsSum], [winlost], [awinlost], [mwinlost], [swinlost], [playercomm], [comm], [acomm], [scomm], [Transdate3rd], [SiteID], [Additional], [JackpotInfo], [RefNo2], [ContributionRate], [BetStake], [ContributionStake3rd], [epositiontaking], [RepUpdateTime], [SiteDBGroupID])
	        SELECT s.[transid], [custid], [transdate], [odds], [stake], [status], [apositiontaking], [mpositiontaking], [tpositiontaking], [spositiontaking], [playerdiscount], [discount], [adiscount], [sdiscount], [creator], [winlostdate], [betfrom], [virtualrate], [actualrate], [actual_stake], [currency], [CurrencyName], [recommend], [mrecommend], [srecommend], [ip], [statusID], [balance], [Username], [transdesc], [productID], [gameID], [vendorID], [GameId3rd], [TranId3rd], [RefNo], [IsSum], [winlost], [awinlost], [mwinlost], [swinlost], [playercomm], [comm], [acomm], [scomm], [Transdate3rd], [SiteID], [Additional], [JackpotInfo], [RefNo2], [ContributionRate], [BetStake], [ContributionStake3rd], [epositiontaking], [RepUpdateTime], [SiteDBGroupID]
	        FROM cte_source s
		    INNER JOIN #sourceBet chk ON chk.transid = s.transid
		    WHERE @siteDBGroupId = 1
                AND chk.TableName = @tableName
                AND chk.[FlagAction] = ''Missed Row'';\
            ';

            --print @sqlCMD;
		    EXEC sp_executesql @sqlCMD, N'@tableName VARCHAR(100), @siteDBGroupId SMALLINT',@tableName=@tableName,@siteDBGroupId=@siteDBGroupId;
        END
    END
    -- TODO-4: bettransG
    BEGIN 
	    SET @tableName = 'bettransG';
        SET @sqlCMD = N'\
        WITH cte_source AS (
	        SELECT t.*
	        FROM OPENQUERY(DBCTG,
	            ''SELECT @@SERVERNAME AS ServerName, t.*
                FROM bodb02.dbo.bettransG t WITH (nolock)
	            INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.custid = t.custid AND c.site IN (''''Athena000'''',''''SampleSite'''')
                WHERE t.winlostdate = '''''+CONVERT(VARCHAR(20),@winlostdate,120)+'''''''
            ) AS t
        ),
        source_CheckSum AS (
            SELECT ServerName, transid, binary_checksum(convert(varchar(50), TransDate, 121),convert(varchar(50), WinlostDate, 121),bettype,Stake,Actual_Stake,Winlost,AWinlost,MWinlost,SWinlost,PlayerComm,Comm,AComm,SComm,StatusId,TransDesc,ActualRate) AS chkSum
            FROM cte_source
        ), 
	    cte_siteDB AS (
		    SELECT t.TransID, binary_checksum(convert(varchar(50), TransDate, 121),convert(varchar(50), WinlostDate, 121),bettype,Stake,Actual_Stake,Winlost,AWinlost,MWinlost,SWinlost,PlayerComm,Comm,AComm,SComm,StatusId,TransDesc,ActualRate) AS chkSum
		    FROM bodb02.dbo.bettransG t WITH (nolock) 
		    INNER JOIN source_CheckSum s ON s.transid = t.transid 
	    ),
        cte_Final AS (
            SELECT s.*
                , CASE 
                    WHEN t.TransID IS NULL THEN ''Missed Row''
                    WHEN s.TransID IS NULL THEN ''Delete Row''
                    WHEN ISNULL(s.chkSum,0) <> ISNULL(t.chkSum,0) THEN ''Diff Values''
                   END AS [FlagAction]
            FROM source_CheckSum s
            FULL JOIN cte_siteDB t ON t.transid = s.transid
	        WHERE (
                    t.TransID IS NULL 
                    OR s.TransID IS NULL 
                    OR ISNULL(s.chkSum,0) <> ISNULL(t.chkSum,0)
               )
        )
	    INSERT INTO #sourceBet(ServerName, TableName, TransID, chkSum, FlagAction)
        SELECT ServerName, @tableName, TransID, chkSum, FlagAction
        FROM cte_Final;\
        ';

        EXEC sp_executesql @sqlCMD, N'@tableName VARCHAR(100)',@tableName=@tableName;

        -- RESULT STATUS
        SELECT @actionName AS [Action], s.* 
        FROM #sourceBet s WHERE TableName = @tableName;

         IF (@checkAction = 1
            AND EXISTS (SELECT 1 FROM #sourceBet s WHERE s.TableName = @tableName AND s.FlagAction IS NOT NULL)
        )
        BEGIN
            --TODO: UPDATE
            SET @sqlCMD = N'\
            WITH cte_source AS (
	            SELECT *
	            FROM OPENQUERY(DBCTG,
	                    ''SELECT t.* 
                        FROM bodb02.dbo.bettransG t WITH (nolock)
	                    INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.custid = t.custid AND c.site IN (''''Athena000'''',''''SampleSite'''')
                        WHERE t.winlostdate = '''''+CONVERT(VARCHAR(20),@winlostdate,120)+'''''''
                ) AS t
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
            INNER JOIN cte_source u ON u.transid = t.transid
            INNER JOIN #sourceBet chk ON chk.TransID = u.transid
            WHERE @siteDBGroupId = 1 
                AND TableName = @tableName
                AND chk.[FlagAction] = ''Diff Values'';\
            ';

            --print @sqlCMD;
		    EXEC sp_executesql @sqlCMD, N'@tableName VARCHAR(100), @siteDBGroupId SMALLINT',@tableName=@tableName,@siteDBGroupId=@siteDBGroupId;

            --TODO: INSERT
            SET @sqlCMD = N'\
            WITH cte_source AS (
	            SELECT *
	            FROM OPENQUERY(DBCTG,
	                    ''SELECT t.* 
                        FROM bodb02.dbo.bettransG t WITH (nolock)
	                    INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.custid = t.custid AND c.site IN (''''Athena000'''',''''SampleSite'''')
                        WHERE t.winlostdate = '''''+CONVERT(VARCHAR(20),@winlostdate,120)+'''''''
                ) AS t
            )
            INSERT INTO bodb02.dbo.bettransG([transid], [custid], [transdate], [oddsid], [odds], [stake], [status], [winlost], [betteam], [creator], [refno], [winlostdate], [betfrom], [checktime], [apositiontaking], [mpositiontaking], [tpositiontaking], [awinlost], [mwinlost], [playerdiscount], [discount], [adiscount], [playercomm], [comm], [acomm], [actualrate], [matchid], [matchdate], [statuswinlost], [ruben], [bettype], [spositiontaking], [swinlost], [sdiscount], [scomm], [statusID], [virtualrate], [SiteID], [transdesc], [BetID3rd], [epositiontaking], [actual_stake], [netstake], [RepUpdateTime], [SiteDBGroupID])
	        SELECT s.[transid], [custid], [transdate], [oddsid], [odds], [stake], [status], [winlost], [betteam], [creator], [refno], [winlostdate], [betfrom], [checktime], [apositiontaking], [mpositiontaking], [tpositiontaking], [awinlost], [mwinlost], [playerdiscount], [discount], [adiscount], [playercomm], [comm], [acomm], [actualrate], [matchid], [matchdate], [statuswinlost], [ruben], [bettype], [spositiontaking], [swinlost], [sdiscount], [scomm], [statusID], [virtualrate], [SiteID], [transdesc], [BetID3rd], [epositiontaking], [actual_stake], [netstake], [RepUpdateTime], [SiteDBGroupID]
	        FROM cte_source s
		    INNER JOIN #sourceBet chk ON chk.transid = s.transid
		    WHERE @siteDBGroupId = 1
                AND chk.TableName = @tableName
                AND chk.[FlagAction] = ''Missed Row'';\
            ';

            --print @sqlCMD;
		    EXEC sp_executesql @sqlCMD, N'@tableName VARCHAR(100), @siteDBGroupId SMALLINT',@tableName=@tableName,@siteDBGroupId=@siteDBGroupId;
        END
    END
    -- TODO-5: bettransM
    BEGIN 
	    SET @tableName = 'bettransM';
        SET @sqlCMD = N'\
        WITH cte_source AS (
	        SELECT t.*
	        FROM OPENQUERY(DBCTG,
	            ''SELECT @@SERVERNAME AS ServerName, t.*
                FROM bodb02.dbo.bettransM t WITH (nolock)
	            INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.custid = t.custid AND c.site IN (''''Athena000'''',''''SampleSite'''')
                WHERE t.winlostdate = '''''+CONVERT(VARCHAR(20),@winlostdate,120)+'''''''
            ) AS t
        ),
	    source_CheckSum AS (
            SELECT ServerName, transid, binary_checksum(convert(varchar(50), TransDate, 121),convert(varchar(50), WinlostDate, 121),bettype,Stake,Winlost,AWinlost,MWinlost,SWinlost,PlayerComm,Comm,AComm,SComm,StatusId,TransDesc,ActualRate) AS chkSum
            FROM cte_source
        ), 
	    cte_siteDB AS (
		    SELECT t.TransID, binary_checksum(convert(varchar(50), TransDate, 121),convert(varchar(50), WinlostDate, 121),bettype,Stake,Winlost,AWinlost,MWinlost,SWinlost,PlayerComm,Comm,AComm,SComm,StatusId,TransDesc,ActualRate) AS chkSum
		    FROM bodb02.dbo.bettransM t WITH (nolock) 
		    INNER JOIN source_CheckSum s ON s.transid = t.transid 
	    ),
        cte_Final AS (
            SELECT s.*
                , CASE 
                    WHEN t.TransID IS NULL THEN ''Missed Row''
                    WHEN s.TransID IS NULL THEN ''Delete Row''
                    WHEN ISNULL(s.chkSum,0) <> ISNULL(t.chkSum,0) THEN ''Diff Values''
                   END AS [FlagAction]
            FROM source_CheckSum s
            FULL JOIN cte_siteDB t ON t.transid = s.transid
	        WHERE (
                    t.TransID IS NULL 
                    OR s.TransID IS NULL 
                    OR ISNULL(s.chkSum,0) <> ISNULL(t.chkSum,0)
               )
        )
	    INSERT INTO #sourceBet(ServerName, TableName, TransID, chkSum, FlagAction)
        SELECT ServerName, @tableName, TransID, chkSum, FlagAction
        FROM cte_Final;\
        ';

        EXEC sp_executesql @sqlCMD, N'@tableName VARCHAR(100)',@tableName=@tableName;

        -- RESULT STATUS
        SELECT @actionName AS [Action], s.* 
        FROM #sourceBet s WHERE TableName = @tableName;

         IF (@checkAction = 1
            AND EXISTS (SELECT 1 FROM #sourceBet s WHERE s.TableName = @tableName AND s.FlagAction IS NOT NULL)
        )
        BEGIN
            --TODO: UPDATE
            SET @sqlCMD = N'\
            WITH cte_source AS (
	            SELECT *
	            FROM OPENQUERY(DBCTG,
	                    ''SELECT t.* 
                        FROM bodb02.dbo.bettransM t WITH (nolock)
	                    INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.custid = t.custid AND c.site IN (''''Athena000'''',''''SampleSite'''')
                        WHERE t.winlostdate = '''''+CONVERT(VARCHAR(20),@winlostdate,120)+'''''''
                ) AS t
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
            INNER JOIN cte_source u ON u.transid = t.transid
            INNER JOIN #sourceBet chk ON chk.TransID = u.transid
            WHERE @siteDBGroupId = 1 
                AND TableName = @tableName
                AND chk.[FlagAction] = ''Diff Values'';\
            ';

            --print @sqlCMD;
		    EXEC sp_executesql @sqlCMD, N'@tableName VARCHAR(100), @siteDBGroupId SMALLINT',@tableName=@tableName,@siteDBGroupId=@siteDBGroupId;
        
            --TODO: INSERT
            SET @sqlCMD = N'\
            WITH cte_source AS (
	            SELECT *
	            FROM OPENQUERY(DBCTG,
	                    ''SELECT t.* 
                        FROM bodb02.dbo.bettransM t WITH (nolock)
	                    INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.custid = t.custid AND c.site IN (''''Athena000'''',''''SampleSite'''')
                        WHERE t.winlostdate = '''''+CONVERT(VARCHAR(20),@winlostdate,120)+'''''''
                ) AS t
            )
            INSERT INTO bodb02.dbo.bettransM([transid], [custid], [transdate], [oddsid], [hdp1], [hdp2], [odds], [stake], [status], [winlost], [livehomescore], [liveawayscore], [liveindicator], [betteam], [creator], [refno], [comstatus], [winlostdate], [betfrom], [betcheck], [checktime], [oddsspread], [apositiontaking], [mpositiontaking], [tpositiontaking], [awinlost], [mwinlost], [playerdiscount], [discount], [adiscount], [playercomm], [comm], [acomm], [actualrate], [matchid], [matchdate], [finalodds], [isfinish], [statuswinlost], [ruben], [bettype], [spositiontaking], [swinlost], [sdiscount], [scomm], [statusID], [recommdate], [transdesc], [SecAcceptFlag], [SecAcceptTime], [LiveBetAcceptTime], [ReasonIDm], [RepUpdateTime], [SiteDBGroupID])
	        SELECT s.[transid], [custid], [transdate], [oddsid], [hdp1], [hdp2], [odds], [stake], [status], [winlost], [livehomescore], [liveawayscore], [liveindicator], [betteam], [creator], [refno], [comstatus], [winlostdate], [betfrom], [betcheck], [checktime], [oddsspread], [apositiontaking], [mpositiontaking], [tpositiontaking], [awinlost], [mwinlost], [playerdiscount], [discount], [adiscount], [playercomm], [comm], [acomm], [actualrate], [matchid], [matchdate], [finalodds], [isfinish], [statuswinlost], [ruben], [bettype], [spositiontaking], [swinlost], [sdiscount], [scomm], [statusID], [recommdate], [transdesc], [SecAcceptFlag], [SecAcceptTime], [LiveBetAcceptTime], [ReasonIDm], [RepUpdateTime], [SiteDBGroupID]
	        FROM cte_source s
		    INNER JOIN #sourceBet chk ON chk.transid = s.transid
		    WHERE @siteDBGroupId = 1
                AND chk.TableName = @tableName
                AND chk.[FlagAction] = ''Missed Row'';\
            ';

            --print @sqlCMD;
		    EXEC sp_executesql @sqlCMD, N'@tableName VARCHAR(100), @siteDBGroupId SMALLINT',@tableName=@tableName,@siteDBGroupId=@siteDBGroupId;
        END
    END
    -- TODO-6: translog
    BEGIN 
	    SET @tableName = 'translog';
        SET @sqlCMD = N'\
        WITH cte_source AS (
	        SELECT t.*
	        FROM OPENQUERY(DBCTG,
	            ''SELECT @@SERVERNAME AS ServerName, t.*
                FROM bodb02.dbo.translog t WITH (nolock)
	            INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.custid = t.custid AND c.site IN (''''Athena000'''',''''SampleSite'''')
                WHERE t.winlostdate = '''''+CONVERT(VARCHAR(20),@winlostdate,120)+'''''''
            ) AS t
        ),
        source_CheckSum AS (
            SELECT ServerName, translogid, binary_checksum(convert(varchar(50), TransDate, 121),convert(varchar(50), WinlostDate, 121),gameID,Stake,StatusId,TransDesc,ActualRate) AS chkSum
            FROM cte_source
        ), 
	    cte_siteDB AS (
		    SELECT t.translogid, binary_checksum(convert(varchar(50), TransDate, 121),convert(varchar(50), WinlostDate, 121),gameID,Stake,StatusId,TransDesc,ActualRate) AS chkSum
		    FROM bodb02.dbo.translog t WITH (nolock) 
		    INNER JOIN source_CheckSum s ON s.translogid = t.translogid 
	    ),
        cte_Final AS (
            SELECT s.*
                , CASE 
                    WHEN t.translogid IS NULL THEN ''Missed Row''
                    WHEN s.translogid IS NULL THEN ''Delete Row''
                    WHEN ISNULL(s.chkSum,0) <> ISNULL(t.chkSum,0) THEN ''Diff Values''
                   END AS [FlagAction]
            FROM source_CheckSum s
            FULL JOIN cte_siteDB t ON t.translogid = s.translogid
	        WHERE (
                    t.translogid IS NULL 
                    OR s.translogid IS NULL 
                    OR ISNULL(s.chkSum,0) <> ISNULL(t.chkSum,0)
               )
        )
	    INSERT INTO #sourceBet(ServerName, TableName, TransID, chkSum, FlagAction)
        SELECT ServerName, @tableName, translogid, chkSum, FlagAction
        FROM cte_Final;\
        ';

        EXEC sp_executesql @sqlCMD, N'@tableName VARCHAR(100)',@tableName=@tableName;

        -- RESULT STATUS
        SELECT @actionName AS [Action], s.* 
        FROM #sourceBet s WHERE TableName = @tableName;

         IF (@checkAction = 1
            AND EXISTS (SELECT 1 FROM #sourceBet s WHERE s.TableName = @tableName AND s.FlagAction IS NOT NULL)
        )
        BEGIN
            --TODO: UPDATE
            SET @sqlCMD = N'\
            WITH cte_source AS (
	            SELECT *
	            FROM OPENQUERY(DBCTG,
	                    ''SELECT t.* 
                        FROM bodb02.dbo.translog t WITH (nolock)
	                    INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.custid = t.custid AND c.site IN (''''Athena000'''',''''SampleSite'''')
                        WHERE t.winlostdate = '''''+CONVERT(VARCHAR(20),@winlostdate,120)+'''''''
                ) AS t
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
            INNER JOIN cte_source u ON u.translogid = t.translogid
            INNER JOIN #sourceBet chk ON chk.TransID = u.translogid
            WHERE @siteDBGroupId = 1 
                AND TableName = @tableName
                AND chk.[FlagAction] = ''Diff Values'';\
            ';

            --print @sqlCMD;
		    EXEC sp_executesql @sqlCMD, N'@tableName VARCHAR(100), @siteDBGroupId SMALLINT',@tableName=@tableName,@siteDBGroupId=@siteDBGroupId;

            --TODO: INSERT
            SET @sqlCMD = N'\
            WITH cte_source AS (
	            SELECT *
	            FROM OPENQUERY(DBCTG,
	                    ''SELECT t.* 
                        FROM bodb02.dbo.translog t WITH (nolock)
	                    INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.custid = t.custid AND c.site IN (''''Athena000'''',''''SampleSite'''')
                        WHERE t.winlostdate = '''''+CONVERT(VARCHAR(20),@winlostdate,120)+'''''''
                ) AS t
            )
            INSERT INTO bodb02.dbo.translog([translogid], [custid], [transdate], [odds], [stake], [status], [apositiontaking], [mpositiontaking], [tpositiontaking], [spositiontaking], [playerdiscount], [discount], [adiscount], [sdiscount], [creator], [winlostdate], [betfrom], [virtualrate], [actualrate], [actual_stake], [currency], [CurrencyName], [recommend], [mrecommend], [srecommend], [ip], [statusID], [balance], [Username], [transdesc], [productID], [gameID], [eventID], [vendorID], [GameId3rd], [TranId3rd], [custom1], [custom2], [custom3], [LiveIndicator], [checkCount], [SiteId], [epositiontaking], [LicenseeTransId], [RepUpdateTime], [SiteDBGroupID])
	        SELECT s.[translogid], [custid], [transdate], [odds], [stake], [status], [apositiontaking], [mpositiontaking], [tpositiontaking], [spositiontaking], [playerdiscount], [discount], [adiscount], [sdiscount], [creator], [winlostdate], [betfrom], [virtualrate], [actualrate], [actual_stake], [currency], [CurrencyName], [recommend], [mrecommend], [srecommend], [ip], [statusID], [balance], [Username], [transdesc], [productID], [gameID], [eventID], [vendorID], [GameId3rd], [TranId3rd], [custom1], [custom2], [custom3], [LiveIndicator], [checkCount], [SiteId], [epositiontaking], [LicenseeTransId], [RepUpdateTime], [SiteDBGroupID]
	        FROM cte_source s
		    INNER JOIN #sourceBet chk ON chk.transid = s.[translogid]
		    WHERE @siteDBGroupId = 1
                AND chk.TableName = @tableName
                AND chk.[FlagAction] = ''Missed Row'';\
            ';

            --print @sqlCMD;
		    EXEC sp_executesql @sqlCMD, N'@tableName VARCHAR(100), @siteDBGroupId SMALLINT',@tableName=@tableName,@siteDBGroupId=@siteDBGroupId;
        END
    END
END
GO