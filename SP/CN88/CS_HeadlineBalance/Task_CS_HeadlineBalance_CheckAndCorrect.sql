/*<info serverAlias="DBACC-bodb02" executers="" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_CS_HeadlineBalance_CheckAndCorrect]
	@WinlostDate 		SMALLDATETIME, 
	@IsCheckDataOnly	BIT = 0,
	@ErrCode  			INT = 0 OUTPUT,
    @ErrMsg   			VARCHAR(100) = '' OUTPUT
AS
/*
	Creator: 20190826@Sophia 
	Remark: Daily Auto add transfer ticket for CN88 Headline balance - bettrans14 range (like reset winning Extra PT for CN88) 
	DB: DBACC-bodb02

	Revisions:
		- 20190826@Sophia: initial SP [Redmine: #117863]
		- 20191212@Percy: Get UplineId (HeadlineId) from ExtraPT Setting table [RedmineID: #118962]

	Param's explain:
		@IsCheckDataOnly:  1 _ view report
						   0 _ reset balance
	          
	    @ErrCode: 0 _ Success
	              1 _ Error
	            

	 
*/
BEGIN
	SET NOCOUNT ON
 
	CREATE TABLE #Headline(UplineID INT )		 
	CREATE TABLE #Transfer (Custid INT, Reset MONEY,  Winlostdate SMALLDATETIME )	
	CREATE TABLE #Reset (seq INT IDENTITY (1,1), Winlostdate SMALLDATETIME, CustId INT, ExtraPTWinlost MONEY, Reset MONEY, Variance MONEY)

	
	----Begin: Get Sport Bettype Matrix------
	-- Check SP Version
	DECLARE @isTest BIT = 0
	SELECT  @isTest = dbo.f_CheckSPVersion(@@PROCID)
	
	DECLARE @SportBettype TABLE(ProductID INT, Bettype INT,SubProduct VARCHAR(500))
	INSERT INTO @SportBettype
	SELECT ProductID, Bettype, SubProduct FROM bodb02.dbo.f_SportBettypeMatrix_Sel (0, 0, 0, 2, '', '', @isTest)

	
	DECLARE @ExtraPTProducts AS TABLE (ProductID INT)	
	INSERT INTO @ExtraPTProducts (ProductID) 
	SELECT DISTINCT ProductID FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK) 	
	
	
	DELETE @SportBettype WHERE ProductId NOT IN (SELECT ProductID FROM @ExtraPTProducts)

	-----End: Get Sport Bettype Matrix------
		 
	
	----Begin: Get Headline List ----
	
	INSERT INTO #Headline (UplineId) 
	SELECT DISTINCT e.UplineId
	FROM CS_CustSuper cs WITH (NOLOCK)
		CROSS APPLY (
			SELECT TOP 1 ag.UplineId
			FROM dbo.Acc_GroupExtraPTSetting ag WITH (NOLOCK)
			WHERE cs.CustId = ag.SuperId
				AND @WinlostDate BETWEEN ag.FromDate AND ag.ToDate
		) e
 	
	----End: Get Headline List ----
	
	
	--- Begin: Last reset	
	
	INSERT INTO #Transfer (Custid, Reset, Winlostdate)
	SELECT	b.custid, 			
			ROUND((b.winlost - b.actual_stake), 2) AS Reset, 
			b.winlostdate 
	FROM dbo.bettrans b WITH(NOLOCK) 	
	WHERE b.bettype = 21007
		AND b.winlostdate = @Winlostdate
		AND EXISTS (SELECT 1 FROM #Headline h WHERE h.UplineId = b.CustID) 
	
	--- End: Last reset


	
	-----Begin : Get Winlost on ticket ----------------
	 
	--------------------------------------------Extra PT ---------------------------------------------------
	CREATE TABLE #wl 
	(	winlostdate 	SMALLDATETIME, 
		srecommend 		INT, 		
		Sporttype  		SMALLINT, 
		ProductId		INT,  
		SubProduct		VARCHAR(250), 		
		WinlostForExtraPT MONEY
	)
	
	CREATE TABLE #WLByProduct
	(
	    winlostdate			SMALLDATETIME, 
		ProductId			INT,
		SubProduct			VARCHAR(250),
		UplineId			INT,		
		ExtraPTWinlost		MONEY
	) 
	 
	INSERT INTO #wl (winlostdate, srecommend, Sporttype, ProductId, SubProduct, WinlostForExtraPT)
	SELECT  b.winlostdate,
			b.srecommend,					
			CASE WHEN ISNULL(m.Sporttype, 0) <> 0 THEN m.Sporttype ELSE 0 END AS Sporttype,
			s.ProductId,			 
			CASE WHEN s.SubProduct IN ('MG-SuperLive', 'Bet Builder') THEN s.SubProduct ELSE '' END AS SubProduct,		
			-SUM(
					(CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE b.winlost - b.actual_stake + b.scomm / (1 - b.tpositiontaking) END) * ISNULL(b.epositiontaking, 0)
				) AS WinlostForExtraPT					
				
		FROM dbo.bettrans14 b WITH (NOLOCK)			
		INNER JOIN @SportBettype s ON s.BetType = b.bettype
		LEFT JOIN dbo.Match14 m WITH (NOLOCK) ON m.MatchId = b.MatchId  AND m.Sporttype = 44		
		WHERE   b.Winlostdate = @Winlostdate
			AND b.ruben = 1
			AND b.statusid NOT IN (101, 102, 103, 121)					
			AND EXISTS (SELECT 1 FROM dbo.CS_CustSuper cs WITH (NOLOCK) WHERE cs.CusTID = b.srecommend) 
		GROUP BY b.Winlostdate,				
				b.srecommend,	
				b.Currency,
				CASE WHEN ISNULL(m.Sporttype, 0) <> 0 THEN m.Sporttype ELSE 0 END,
				s.ProductId,				
				CASE WHEN s.SubProduct IN ('MG-SuperLive', 'Bet Builder') THEN s.SubProduct ELSE '' END
				 

	INSERT INTO #WLByProduct (Winlostdate, ProductId, UplineID, ExtraPTWinlost ) 
	SELECT Winlostdate, ProductId, UplineID, SUM(ExtraPTWinlost) 
	FROM (		
			--- extraPT
			SELECT  w.Winlostdate, w.ProductId, 			
					s.UplineID,
				   SUM(w.WinlostForExtraPT) as ExtraPTWinlost 
			FROM	#wl w
			INNER JOIN dbo.Acc_GroupExtraPTSetting s WITH(NOLOCK)
					ON w.srecommend = s.SuperId
					AND w.ProductId = s.ProductId
					AND w.SubProduct = s.SubProduct
					AND w.Sporttype = s.Sporttype 
					AND w.Winlostdate BETWEEN s.FromDate AND s.ToDate	
			GROUP BY w.Winlostdate, w.ProductId,  s.UplineID	 
	
		) w
	GROUP BY w.Winlostdate, w.ProductId, w.UplineID	
	
	
	----view report
    IF (@IsCheckDataOnly = 1)
    BEGIN 
	    ----- calculate reset 
		SELECT  @Winlostdate as Winlostdate,  ISNULL(e.UplineID, rs.Custid) as UplineID ,
				ROUND(SUM(ISNULL(e.ExtraPTWinlost, 0)), 2) AS ExtraPTWinlost, 
				ROUND(SUM(ISNULL(rs.Reset, 0)), 2) AS Reset 
		FROM  (
				SELECT Winlostdate, UplineID, SUM(ExtraPTWinlost) AS ExtraPTWinlost 
				FROM  #WLByProduct 
				GROUP BY Winlostdate, UplineID
				) e 
			FULL JOIN #Transfer rs 
				ON e.UplineID = rs.Custid
		GROUP BY ISNULL(e.UplineID, rs.Custid)
		HAVING (ROUND(SUM(ISNULL(e.ExtraPTWinlost, 0)), 2) - ROUND(SUM(ISNULL(rs.Reset, 0)), 2) ) <> 0
	END	
	ELSE
    BEGIN 
	    ----- calculate reset 
		INSERT INTO #Reset (Winlostdate, CustId, ExtraPTWinlost, Reset, Variance)
		SELECT  @Winlostdate, ISNULL(e.UplineID, rs.Custid) as UplineID ,
				ROUND(SUM(ISNULL(e.ExtraPTWinlost, 0)), 2) AS ExtraPTWinlost,
				ROUND(SUM(ISNULL(rs.Reset, 0)), 2) AS Reset,
				ROUND(SUM(ISNULL(e.ExtraPTWinlost, 0)), 2) - ROUND(SUM(ISNULL(rs.Reset, 0)), 2)  AS Variance
		FROM (
				SELECT Winlostdate, UplineID, SUM(ExtraPTWinlost) AS ExtraPTWinlost
				FROM  #WLByProduct 
				GROUP BY Winlostdate, UplineID
				) e 				
			FULL JOIN #Transfer rs 
				ON e.UplineID = rs.Custid
		GROUP BY ISNULL(e.UplineID, rs.Custid)
		HAVING (ROUND(SUM(ISNULL(e.ExtraPTWinlost, 0)), 2) - ROUND(SUM(ISNULL(rs.Reset, 0)), 2) ) <> 0
		
		
		---------------------
 
		DECLARE 
				@seq		  	TINYINT = 1,
				@maxseq		  	TINYINT = 0,				
				@ExtraPTWinlost MONEY = 0, 
                @custid       	INT,  
				@Variance	    MONEY = 0, 
                @transDesc    	NVARCHAR(1000)= 'ExtraPT',		
				@Creator  		INT = 10278938,   -- starixIT
				@IP       		VARCHAR(20) = '',
				@LogData  		NVARCHAR(200) = ''		

		Declare @RefNum bigint = 0, @bettype int, @Curr int, @CurrName nvarchar(10),
				@actualrate float, @Recommend int, @MRecommend int, @SRecommend int,
				@username nvarchar(50), @creditamt money, @debitamt money, @roleID tinyint		
				

		SELECT @maxseq = MAX(r.seq)
        FROM   #reset r
		
		IF (@maxseq = 0)
        BEGIN            
            RETURN
        END
			
		
        WHILE (@seq <= @maxseq)
        BEGIN
        
            SELECT @CustId = CustId,
				   @ExtraPTWinlost = ExtraPTWinlost,
				   @Variance = Variance
            FROM #Reset
            WHERE seq = @seq 		
			
			----- Insert transaction
			EXEC DBTXN.bodb02.dbo.Task_CS_HeadlineBalance_Add  
					@Winlostdate = @Winlostdate,
	                @custid = @custid,
	                @amount = @ExtraPTWinlost,
	                @transdesc = @transDesc,
	                @creator = @creator,
	                @ip = @ip,
	                @ErrCode = @ErrCode OUTPUT,
                    @ErrMsg = @ErrMsg OUTPUT

			IF (@ErrCode <> 0) BREAK
			
			----Adjust statement
			EXEC bodb_report.dbo.[Acc_StatementUpdateTransfer]
				@custid = @custid
				,@Amount = @variance
				,@winlostdate = @winlostdate
				,@ErrCode = @ErrCode OUTPUT
				,@ErrMsg = @ErrMsg OUTPUT							

			IF (@ErrCode <> 0) BREAK			
											
			--- write log 
			BEGIN TRY
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Transfer
					@UserID = @creator,
					@FromCustID = 0,
					@ToCustID = @custid,
					@ip = @ip,
					@Doing = @transDesc
			END TRY	
			BEGIN CATCH						
				SELECT @LogData = @LogData + ' ErrMsg=' + error_message()
				EXEC DBTXN.bodb_customerlog.dbo.WriteLog_UserLog_Transfer 
					@UserID = @creator, 
					@FromCustID = 0, 
					@ToCustID = @CustID, 
					@IP = @IP, 
					@Doing = @LogData						
			END CATCH
         

            SET @seq = @seq + 1

            SELECT @ErrMsg = 'The process has been successful!'
			
        END
  
    END
	
	
	DROP TABLE #Headline
	DROP TABLE #Reset
	DROP TABLE #Transfer
	DROP TABLE #wl
	DROP TABLE #WLByProduct
	
END
GO