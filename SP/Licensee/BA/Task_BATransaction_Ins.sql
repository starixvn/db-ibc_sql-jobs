/*<info serverAlias="DBEXT-BODB02,DBACC-BODB02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb02]
GO    

ALTER PROCEDURE [dbo].[Task_BATransaction_Ins]
AS  
/*  
	Created by:[Henry]  
	Date: 2011-06-20  
	Task: Insert BA Bets to LicenseeBATransaction  
	DB: DB052.BODB02  
	Revisions:   
		20110824@Henry: Change the range of the bettype (not between 31 and 120)  
		20110909@Viet: revise SP  
		20111208@Jim: Change bettype condition  
		20100315@kIWI: Remove @TempBACustID table   
		20121030@Viet: change the way to get data, reduce load for server.  
		20150127@Don: Expand bet type ranges for Sportbook when processing BA
		20150903@Patrick: #42910: Exclude ticket 901 for BetTrade
		20160301@Don: Add hard-code of [transid < 100000000000]
		20160416@Francis: Revert hard-code of [transid < 100000000000]
		20170410@Paul: Implement Cash Out [RedmineID :#71727]
		20180806@Patrick: Sync BA ticket to DB042 [Redmine #98631]
		20181002@Sophia: Sync BA ticket to DB053 (UAT) [Redmine #99855]
		20181025@Sophia: Revert SPs not to sync BA ticket to DB053, due to DB053 has the job Gen BA ticket by itself (PRO) [Redmine #99855]	
		20181107@Patrick: DB052 Indexes Revolution [Redmine: #103572]
		20181120@Sophia: Change 'DB052' To 'DB053' for steap switch to DB053 [Redmine: #103653]
		20180412@Percy: Expand Sportsbook bettype range - ESports [RedmineID: #100721]
 */  
BEGIN
	SET NOCOUNT ON   
  
	DECLARE @temptrans AS TABLE (transid BIGINT, transdate DATETIME, custid INT, recommend INT, srecommend INT)  
    
	DECLARE @smallID BIGINT, @maxtransID BIGINT, @currentDate DATETIME    
	-- scan each transid twice to prevent missing by locking  
	SELECT @smallID = cast(isnull(vvalue,0) AS BIGINT)  
	FROM bodb_licensee.dbo.LICSettings WITH(ROWLOCK)   
	WHERE vname = 'BA_transid'   
  
	SELECT @maxtransID = max(transid) FROM dbo.bettrans WITH(NOLOCK) --WHERE transid < 100000000000
       
	UPDATE bodb_licensee.dbo.LICSettings WITH(ROWLOCK, UPDLOCK)  
	SET vvalue = vvalue2  
	,vvalue2 = cast(@maxtransID AS VARCHAR(200))  
	WHERE vname = 'BA_transid'  
  
	INSERT INTO @temptrans (transid, transdate, custid, recommend, srecommend)  
	SELECT transid, transdate, custid, recommend, srecommend
	FROM dbo.bettrans WITH(NOLOCK, index=PK_bettrans) --IXU_transid/PK_bettrans
	WHERE TransID BETWEEN @smallID AND @maxtransID  
		AND (Bettype < 31 OR (Bettype BETWEEN 121 AND 999) OR (Bettype BETWEEN 1301 AND 1399) OR (Bettype BETWEEN 9001 AND 9399))  
		AND StatusID <> 121 --DONE  
		AND tpositiontaking = 0
		AND (bettype < 901 OR bettype > 904)
		AND (bettype < 911 OR bettype > 914)
  
	IF @@ROWCOUNT = 0 RETURN  
   
	DELETE @temptrans  
	WHERE custid NOT IN (  
			SELECT CustID   
			FROM bodb_Licensee.dbo.LicenseeBAHistory WITH (NOLOCK)   
			WHERE Status = 'Running'  
				OR (Status = 'Done'  
					AND DATEDIFF(MINUTE,OffDate,CURRENT_TIMESTAMP)<=2)  

			UNION ALL --Cash Out

			SELECT custid
			FROM dbo.TradeCust WITH(NOLOCK)
			WHERE VendorID = 14
		) 

   
	DELETE t   
	FROM @temptrans t  
		INNER JOIN bodb_Licensee.dbo.LicenseeBATransaction ba WITH(NOLOCK) ON t.TransID = ba.TransID  
   
	INSERT INTO Bodb_Licensee.dbo.LicenseeBATransaction (TransID, Transdate)  
	SELECT TransID, Transdate   
	FROM @temptrans  
  
	INSERT INTO Bodb_Licensee.dbo.LicenseeBATransaction_active (TransID, Transdate, custid, recommend, srecommend)  
	SELECT TransID, Transdate, custid, recommend, srecommend  
	FROM @temptrans

	--Add more code to sync data to DB042 --> temporary solution
	DECLARE @XmlData NVARCHAR(MAX) 
	SET @XmlData = (
		SELECT TransId AS t, Transdate AS td, custid AS c, recommend AS r, srecommend AS s
		FROM @temptrans
		FOR XML RAW('r'), root
	)	
	
	IF @XmlData IS NOT NULL AND @@SERVERNAME = 'DB053' 
		EXEC DB042.bodb_Licensee.dbo.Task_BATransaction_Copy_Ticket @XmlData = @XmlData
		
END
GO