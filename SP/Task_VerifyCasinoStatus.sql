/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="vnteam" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[Task_VerifyCasinoStatus]
    @custid VARCHAR(20) = '%'
  , @level  TINYINT     = 0
  , @case   TINYINT     = 0
  , @mode   TINYINT     = 0
AS
/*
	Created: 20140904@Logan

	Task: Verify the status of SyncCasino and DisableCasino between IBC and Casino DB

	Revision:

        - 20140904@Logan:   Initial version.
		- 20201022@Patrick: Change email to starixvn [Redmine: #143607]
        
    Param Explanation:

        * @level:   2: search by agent (custid)
                    3: search by master (custid)
                    4: search by super (custid)
                    0: all

        * @case:    1: 'SyncCasino=1 BUT NOT EXISTS IN Casino DB'
                    2: 'SyncCasino=0 BUT EXISTS IN Casino DB'
                    3: 'Different Closed status'
                    4: 'Different Suspend status'
                    5: 'Different Disable status'
                    6: 'Different Username'
                    0: All

        * @mode     1: Job
                    0: Manual
*/
BEGIN
	SET NOCOUNT ON 

    DECLARE @Statement  VARCHAR(4000)
          , @case1      INT = 0
          , @case2      INT = 0
          , @case3      INT = 0
          , @case4      INT = 0
          , @case5      INT = 0
          , @case6      INT = 0
          
   
    CREATE TABLE #CustomerList
    (
        custid INT
      , type   TINYINT
      , roleid TINYINT
      , username NVARCHAR(50)
      , IBC      NVARCHAR(50)
      , Casino   NVARCHAR(50)
    )

    --CASE 1: SyncCasino=1 but NOT EXISTS IN CasinoAdmin.dbo.Customer
    IF @case IN (1, 0)
    BEGIN
        INSERT INTO #CustomerList
        (
            custid
          , type
          , roleid
          , username
          , IBC
          , Casino
        )
        SELECT ci.custid
             , 1 type
             , ci.roleid
             , ci.username
             , '1' IBC
             , '0' Casino
          FROM bodb02.dbo.CustInfo ci WITH(NOLOCK)			
         WHERE ci.SyncCasino = 1
           AND ci.currency <> 20
           AND ci.Enabled = 1           
           AND ci.srecommend NOT IN (SELECT custid FROM bodb02.dbo.Dep_CustSuper WITH(NOLOCK))
           AND NOT EXISTS (SELECT 1
                             FROM DBCASINO.CasinoAdmin.dbo.Customer WITH(NOLOCK)
                            WHERE IBCCustid = ci.custid
                             )
           AND ((@level = 2
                 AND ci.recommend LIKE @custid
                )
                OR (@level = 3
                    AND ci.mrecommend LIKE @custid
                   )
                OR (@level = 4
                    AND ci.srecommend LIKE @custid
                   )
                OR @level NOT IN (2, 3, 4)
               )

        SET @case1 = @@ROWCOUNT
       
    END

    --CASE 2: SyncCasino=0 but EXISTS IN CasinoAdmin.dbo.Customer
    IF @case IN (2, 0)
    BEGIN
        INSERT INTO #CustomerList
        (
            custid
          , type
          , roleid
          , username
          , IBC
          , Casino
        )
        SELECT ci.custid
             , 2
             , ci.roleid
             , ci.username
             , '0' IBC
             , '1' Casino
          FROM bodb02.dbo.CustInfo ci WITH(NOLOCK)			
         WHERE ci.SyncCasino = 0
           AND ci.currency <> 20
           AND ci.Enabled = 1                  
           AND ci.srecommend NOT IN (SELECT custid FROM bodb02.dbo.Dep_CustSuper WITH(NOLOCK))
           AND EXISTS (SELECT 1
                         FROM DBCASINO.CasinoAdmin.dbo.Customer WITH(NOLOCK)
                        WHERE IBCCustid = ci.custid
                      )
           AND ((@level = 2
                 AND ci.recommend LIKE @custid
                )
                OR (@level = 3
                    AND ci.mrecommend LIKE @custid
                   )
                OR (@level = 4
                    AND ci.srecommend LIKE @custid
                   )
                OR @level NOT IN (2, 3, 4)
               )
        
        SET @case2 = @@ROWCOUNT
       
    END

    --CREATE CLUSTERED INDEX IX_CustomerList_CustList ON #CustomerList(custid)
    
    IF @case IN (3, 4, 5, 6, 0)
    BEGIN
        --PREPARE DATA FOR SYNCED CUSTOMER
        CREATE TABLE #SyncCustomerList
        (
            custid          INT
          , closed          BIT
          , suspend         BIT
          , DisableCasino   BIT
          , username        NVARCHAR(50)
          , type            TINYINT
          , roleid          TINYINT
        )



        INSERT INTO #SyncCustomerList
        (
            custid
          , closed
          , suspend
          , DisableCasino
          , username
          , type
          , roleid
        )
        SELECT ci.custid
             , ci.closed
             , ci.reject
             , ci.DisableCasino
             , ci.username
             , CASE
                 WHEN ci.closed <> cm.IsFrozen THEN 3
                 WHEN ci.reject <> cm.IsClosed THEN 4
                 WHEN ci.DisableCasino = cm.EnableCasino THEN 5
                 WHEN ci.username <> cm.username THEN 6
               END
             , ci.roleid
          FROM bodb02.dbo.custInfo ci WITH(NOLOCK)			               
			INNER JOIN DBCASINO.CasinoAdmin.dbo.Customer cm WITH(NOLOCK) ON cm.IBCCustid = ci.custid
         WHERE ci.SyncCasino = 1
           AND ci.currency <> 20
           AND ci.enabled = 1
           AND ci.srecommend NOT IN (SELECT custid FROM bodb02.dbo.Dep_CustSuper WITH(NOLOCK))
           AND ((@level = 2
                 AND ci.recommend LIKE @custid
                )
                OR (@level = 3
                    AND ci.mrecommend LIKE @custid
                   )
                OR (@level = 4
                    AND ci.srecommend LIKE @custid
                   )
                OR @level NOT IN (2, 3, 4)
               )
           AND (ci.closed <> cm.IsFrozen
                OR ci.reject <> cm.IsClosed
                OR ci.DisableCasino = cm.EnableCasino
                OR ci.username <> cm.username
               )               

        --CASE 3: Different Closed status
        IF @case IN (3, 0)
        BEGIN
            INSERT INTO #CustomerList
            (
                custid
              , type
              , roleid
              , username
              , IBC
              , Casino
            )
            SELECT cl.custid
                 , cl.type
                 , cl.roleid
                 , cl.username
                 , cl.closed
                 , 1 - cl.closed
              FROM #SyncCustomerList cl WITH(NOLOCK)
             WHERE cl.type = 3

            SET @case3 = @@ROWCOUNT
                 
        END

        --CASE 4: Different Suspend status
        IF @case IN (4, 0)
        BEGIN
            INSERT INTO #CustomerList
            (
                custid
              , type
              , roleid
              , username
              , IBC
              , Casino
            )
            SELECT cl.custid
                 , cl.type
                 , cl.roleid
                 , cl.username
                 , cl.suspend
                 , 1 - cl.suspend
              FROM #SyncCustomerList cl WITH(NOLOCK)
             WHERE cl.type = 4

            SET @case4 = @@ROWCOUNT
      
        END

        --CASE 5: Different Disable Casino status
        IF @case IN (5, 0)
        BEGIN
            INSERT INTO #CustomerList
            (
                custid
              , type
              , roleid
              , username
              , IBC
              , Casino
            )
            SELECT cl.custid
                 , cl.type
                 , cl.roleid
                 , cl.username
                 , cl.DisableCasino
                 , 1 - cl.DisableCasino
              FROM #SyncCustomerList cl WITH(NOLOCK)
             WHERE cl.type = 5

            SET @case5 = @@ROWCOUNT
       
        END

        --CASE 6: Different Username
        IF @case IN (6, 0)
        BEGIN
            INSERT INTO #CustomerList
            (
                custid
              , type
              , roleid
              , username
              , IBC
              , Casino
            )
            SELECT cl.custid
                 , cl.type
                 , cl.roleid
                 , cl.username
                 , cl.username
                 , ''
              FROM #SyncCustomerList cl WITH(NOLOCK)
             WHERE cl.type = 6

            SET @case6 = @@ROWCOUNT
       
        END
    END

    IF @case1 <> 0
       OR @case2 <> 0
       OR @case3 <> 0
       OR @case4 <> 0
       OR @case5 <> 0
       OR @case6 <> 0
    BEGIN
		
		;WITH rs AS
			(
				SELECT t.custid 
				FROM #CustomerList t
					LEFT JOIN bodb02.dbo.custInfo c WITH(NOLOCK) ON c.custid = t.custid 
					LEFT JOIN bodb02.dbo.CustSuper sp WITH(NOLOCK) ON c.srecommend = sp.custid 
					LEFT JOIN bodb02.dbo.CustMaster mt WITH(NOLOCK) ON c.mrecommend = mt.custid 
					LEFT JOIN bodb02.dbo.CustAgent ag WITH(NOLOCK) ON c.recommend = ag.custid 
				WHERE ISNULL(sp.IsInternal,0) = 1 
					OR ISNULL(mt.IsInternal,0) = 1
					OR ISNULL(ag.IsInternal,0) = 1
					OR t.username LIKE '%ACCSuper%'
			)
			DELETE FROM #CustomerList
			WHERE custid IN (select custid FROM rs)
			
			
        IF @mode = 1
        BEGIN  
			-- record result 
			insert into RnGCasinoResult(custid, username, roleid, reason, caseid, IBC, RnGCasino, checkdate)
			SELECT cl.custid
                     , cl.username
                     , CASE cl.roleid
                         WHEN 1 THEN 'Member'
                         WHEN 2 THEN 'Agent'
                         WHEN 3 THEN 'Master'
                         WHEN 4 THEN 'Super'
                       END roleid
                     --, cl.type
                     , CASE cl.type
                         WHEN 1 THEN 'SyncCasino=1 BUT NOT EXISTS IN Casino DB'
                         WHEN 2 THEN 'SyncCasino=0 BUT EXISTS IN Casino DB'
                         WHEN 3 THEN 'Different Closed status'
                         WHEN 4 THEN 'Different Suspend status'
                         WHEN 5 THEN 'Different Disable Casino status'
                         WHEN 6 THEN 'Different Username'
                         ELSE 'No error'
                       END reason
                     , cl.type
                     , cl.IBC
                     , cl.Casino
                     , CONVERT(varchar(20),getdate(),111)
                  FROM #CustomerList cl WITH(NOLOCK)
              ORDER BY cl.type ASC, cl.roleid DESC, cl.custid ASC
              
              
            SET @Statement =
				'   There are some mismatch data between IBC and Casino DB ' + ' ( run at ' + CONVERT(varchar(20),getdate(),111) + '): 
					1. SyncCasino=1 BUT NOT EXISTS IN Casino DB: ' + CAST(@case1 AS VARCHAR(20)) + ' customer.        
					2. SyncCasino=0 BUT EXISTS IN Casino DB    : ' + CAST(@case2 AS VARCHAR(20)) + ' customer.        
					3. Different Closed status                 : ' + CAST(@case3 AS VARCHAR(20)) + ' customer.        
					4. Different Suspend status                : ' + CAST(@case4 AS VARCHAR(20)) + ' customer.        
					5. Different Disable Casino status         : ' + CAST(@case5 AS VARCHAR(20)) + ' customer.        
					6. Different Username                      : ' + CAST(@case6 AS VARCHAR(20)) + ' customer.
						Please check again and fix the wrong data.    
						- For 1. and 2., please prepare script for updating the data in IBC.
						- For others, please contact TW team for updating the data in CasinoDB.							
					( using the following table for details: SELECT TOP 100 * FROM DB054.CheckResultDB.dbo.RnGCasinoResult WITH(NOLOCK) WHERE checkdate = ''' 
						+  CONVERT(varchar(20),getdate(),111) + ''')'
        
			DECLARE @profile_name SYSNAME
								,@subject VARCHAR(100)
								,@qstatus VARCHAR(20)				
						
			SELECT TOP (1) @profile_name = name FROM MSDB.dbo.sysmail_profile
						
            EXEC msdb.dbo.sp_send_dbmail
                @profile_name= @profile_name
              , @recipients='pontus@starixvn.com'
              , @subject='Mismatch Casino Status Between IBC and CasinoDB'
              , @body=@Statement
              
        END
        ELSE IF @mode = 0
        BEGIN
			
            SELECT @case1 'SyncCasino=1 BUT NOT EXISTS IN Casino DB'
                 , @case2 'SyncCasino=0 BUT EXISTS IN Casino DB'
                 , @case3 'Different Closed status'
                 , @case4 'Different Suspend status'
                 , @case5 'Different Disable Casino status'
                 , @case6 'Different Username'
                 
                SELECT cl.custid
                     , cl.username
                     , CASE cl.roleid
                         WHEN 1 THEN 'Member'
                         WHEN 2 THEN 'Agent'
                         WHEN 3 THEN 'Master'
                         WHEN 4 THEN 'Super'
                       END roleid
                     --, cl.type
                     , CASE cl.type
                         WHEN 1 THEN 'SyncCasino=1 BUT NOT EXISTS IN Casino DB'
                         WHEN 2 THEN 'SyncCasino=0 BUT EXISTS IN Casino DB'
                         WHEN 3 THEN 'Different Closed status'
                         WHEN 4 THEN 'Different Suspend status'
                         WHEN 5 THEN 'Different Disable Casino status'
                         WHEN 6 THEN 'Different Username'
                         ELSE 'No error'
                       END reason
                     , cl.type
                     , cl.IBC
                     , cl.Casino
                     , CONVERT(varchar(20),getdate(),111)
                  FROM #CustomerList cl WITH(NOLOCK)
              ORDER BY cl.type ASC, cl.roleid DESC, cl.custid ASC
        END
    END


    DROP TABLE #SyncCustomerList
    DROP TABLE #CustomerList
END
GO


