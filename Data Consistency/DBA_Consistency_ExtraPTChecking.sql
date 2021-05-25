/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" isFunction="0"></info>*/
USE [bodb_Consistency]
GO

ALTER PROCEDURE [dbo].[DBA_Consistency_ExtraPTChecking]	
	 @Duration 		VARCHAR(50) 	
	,@CheckMode		TINYINT
	,@ErrCode		INT				= 0		OUTPUT
	,@ErrMsg		VARCHAR(MAX)	= ''	OUTPUT
	,@SampleData	VARCHAR(MAX)	= ''	OUTPUT
AS
/*
	Created: 20200120@Sophia
	Task: Data consistency - Check ExtraPT vs Epositiontaking
	DB: DBTP/bodb_Consistency

	Revisions: 
		- 20200110@Sophia: initial SP [Redmine: #122071]
		- 20210120@Danny: Add rule to check consistency of extraPT [Redmine: #125883]
		- 20210423@Danny: exclude ticket Void/Reject/Refund [Redmine: #153907]
		- 20210518@Danny: Exclude Jackpot ticket [Redmine: #153924]
	
	Param's Expanation:
		@Duration = 'hour', 'lastday'
		@CheckMode  1: Wrong Epositiontaking vs ExtraPT
					2: Epositiontaking IS NULL
					3: Epostiontaking + Tpositiontaking > 1
			
				
*/
SET NOCOUNT ON
BEGIN 
	
	DECLARE @transId VARCHAR(MAX) = '' 
	DECLARE @message VARCHAR(MAX) = '' 
	SELECT @SampleData  = '', @ErrMsg = ''
	DECLARE @WinlostDate SMALLDATETIME
	
	IF @Duration = 'hour'
	BEGIN
		SELECT @Winlostdate = CONVERT (DATE, GETDATE())  
	END

	IF @Duration = 'lastday'
	BEGIN
		SELECT @Winlostdate = CONVERT (DATE, DATEADD(DAY, -1,GETDATE()))  
	END
	
	
	CREATE TABLE  #SportBettype (ProductID INT, Bettype INT,SubProduct VARCHAR(500), RefTable SMALLINT)
	INSERT INTO #SportBettype
	SELECT DISTINCT ProductID, Bettype, SubProduct, RefTable  FROM bodb02.dbo.f_SportBettypeMatrix_Sel (0, 0, 0, 2, '', '', 1)

	DELETE #SportBettype WHERE ProductId NOT IN (SELECT DISTINCT ProductID FROM bodb02.dbo.Acc_GroupExtraPTSetting WITH(NOLOCK))	
	
 	CREATE TABLE #T (epositiontaking smallmoney , ExtraPT [decimal](9, 8), transID BIGINT, Reftable Smallint, RuleID Smallint)
 
	---------------------------------Select data -------------------------
	IF @CheckMode = 1 
	----I. Check Wrong Epositiontaking vs ExtraPT
	BEGIN 
			DECLARE @ExcludeBettype TABLE (Bettype SMALLINT, Reftable TINYINT)
			INSERT INTO @ExcludeBettype (Bettype, Reftable)
			SELECT DISTINCT Bettype, Reftable
			FROM bodb02.dbo.SportBettypeMatrix WITH(NOLOCK)
			WHERE BetType IN (2199, 2399, 2999, 4298, 17004, 3150)

			--- I.I: Wrong Epositiontaking vs ExtraPT
			------I.I.a. Bettrans
			INSERT INTO #T (epositiontaking, ExtraPT, TransID, Reftable, RuleID)				
			SELECT	TOP (10) epositiontaking,  ISNULL(pt.ExtraPT,0) as ExtraPT, TransID, 0 as Reftable, 1 AS RuleID 
			FROM bodb02.dbo.bettrans b WITH (NOLOCK)
			INNER JOIN #SportBettype s
				ON  s.BetType = b.bettype
						AND s.Reftable NOT IN (1,2)							
			LEFT JOIN bodb02.dbo.match m WITH(NOLOCK)
				ON m.matchid = b.matchid AND m.eventdate = b.winlostdate AND m.sporttype = 44 -- MuayThai
			LEFT JOIN  (
						SELECT s.SuperId, s.Fromdate, s.Todate, s.ProductId, s.SubProduct, s.Sporttype, SUM (s.ExtraPT) AS ExtraPT
						FROM bodb02.dbo.Acc_GroupExtraPTSetting s WITH (NOLOCK)			
						GROUP BY s.SuperId, s.ProductId, s.SubProduct, s.Sporttype, s.Fromdate, s.Todate
						) pt
				ON	CAST(b.TransDate AS DATE) BETWEEN pt.FromDate AND pt.ToDate	
					AND b.srecommend = pt.SuperId
					AND s.ProductId = pt.ProductId
					AND CASE WHEN s.SubProduct IN ('MG-SuperLive', 'BT-Sold','BT-Bought','BT-Comm','BT-Winloss','Bet Builder') THEN s.SubProduct ELSE '' END = pt.SubProduct
					AND CASE WHEN ISNULL(m.matchid, 0) <> 0 THEN m.Sporttype ELSE 0 END = pt.Sporttype 
			WHERE  b.winlostdate = @Winlostdate			
				AND b.bettype < 19001 AND b.bettype NOT IN (SELECT u.bettype FROM @ExcludeBettype u WHERE u.Reftable = 0)	 	
				AND b.Epositiontaking <> ISNULL(pt.ExtraPT,0)	
				AND b.custid <> 0
				AND b.statusID NOT IN (101, 102, 103) 

			------I.I.b. translog 
			INSERT INTO #T (epositiontaking, ExtraPT, TransID, Reftable, RuleID)		
			SELECT	TOP (10) epositiontaking,  ISNULL(pt.ExtraPT,0) as ExtraPT, translogid, 3 as Reftable, 1 AS RuleID 
					FROM bodb02.dbo.translog b WITH(NOLOCK)
					INNER JOIN  #SportBettype s
						ON	s.BetType = b.gameID		
							AND s.RefTable = 3				
				    LEFT JOIN  (
								SELECT s.SuperId, s.Fromdate, s.Todate, s.ProductId, s.SubProduct, s.Sporttype, SUM (s.ExtraPT) AS ExtraPT
								FROM bodb02.dbo.Acc_GroupExtraPTSetting s WITH (NOLOCK)								  
								GROUP BY s.SuperId, s.ProductId, s.SubProduct, s.Sporttype, s.Fromdate, s.Todate
								) pt
					ON	CAST(b.TransDate AS DATE) BETWEEN pt.FromDate AND pt.ToDate	
							AND b.srecommend = pt.SuperId
							AND s.ProductId = pt.ProductId
							AND s.SubProduct = pt.SubProduct
							AND pt.Sporttype = 0
					WHERE  b.statusID = 0
						AND b.winlostdate = @Winlostdate	 
						AND b.Epositiontaking <> ISNULL(pt.ExtraPT,0)	
						AND b.custid <> 0
						AND b.statusID NOT IN (101, 102, 103)
						AND b.gameID NOT IN (SELECT u.bettype FROM @ExcludeBettype u WHERE u.Reftable = 3)	
						
			
			------I.I.c. bettransRNG 
			INSERT INTO #T (epositiontaking, ExtraPT, TransID, Reftable, RuleID)
			SELECT TOP (10) epositiontaking, ISNULL(pt.ExtraPT,0) as ExtraPT, TransID, 1 as RefTable, 1 as RuleID
			FROM bodb02.dbo.BettransRNG b WITH(NOLOCK)
			INNER JOIN  #SportBettype s
						ON  b.gameID = s.bettype
						AND s.RefTable = 1	
			LEFT JOIN (SELECT s.SuperId, s.Fromdate, s.Todate, s.ProductId, s.SubProduct, s.Sporttype, SUM (s.ExtraPT) AS ExtraPT
						FROM bodb02.dbo.Acc_GroupExtraPTSetting s WITH (NOLOCK)
						WHERE s.ProductID <> 1
						GROUP BY s.SuperId, s.ProductId, s.SubProduct, s.Sporttype, s.Fromdate, s.Todate 
					  ) pt
					ON CAST(b.TransDate AS DATE) BETWEEN pt.FromDate AND pt.ToDate	
							AND b.srecommend = pt.SuperId
							AND s.ProductId = pt.ProductId
			WHERE	b.winlostdate = @Winlostdate
					AND s.ProductID <> 1  					
					AND b.Epositiontaking <> ISNULL(pt.ExtraPT,0)	
					AND b.custid <> 0
					AND b.statusID NOT IN (101, 102, 103)
					AND b.gameID NOT IN (SELECT u.bettype FROM @ExcludeBettype u WHERE u.Reftable = 1)	
			
			------I.I.d.  bettransLC			
			INSERT INTO #T (epositiontaking, ExtraPT, TransID, Reftable, RuleID)
			SELECT TOP (10) epositiontaking, ISNULL(pt.ExtraPT,0) as ExtraPT, TransID, 2 as RefTable, 1 as RuleID
			FROM bodb02.dbo.BettransLC b WITH(NOLOCK)
			INNER JOIN  #SportBettype s
						ON  b.gameID = s.bettype
						AND s.RefTable = 2	
			LEFT JOIN (SELECT s.SuperId, s.Fromdate, s.Todate, s.ProductId, s.SubProduct, s.Sporttype, SUM (s.ExtraPT) AS ExtraPT
						FROM bodb02.dbo.Acc_GroupExtraPTSetting s WITH (NOLOCK)
						WHERE s.ProductID <> 1
						GROUP BY s.SuperId, s.ProductId, s.SubProduct, s.Sporttype, s.Fromdate, s.Todate 
					  ) pt
					ON CAST(b.TransDate AS DATE) BETWEEN pt.FromDate AND pt.ToDate	
							AND b.srecommend = pt.SuperId
							AND s.ProductId = pt.ProductId
			WHERE	b.winlostdate = @Winlostdate
					AND s.ProductID <> 1  					
					AND b.Epositiontaking <> ISNULL(pt.ExtraPT,0)
					AND b.custid <> 0
					AND b.statusID NOT IN (101, 102, 103)
					AND b.gameID NOT IN (SELECT u.bettype FROM @ExcludeBettype u WHERE u.Reftable = 2)	
							 	
			SELECT @transId = ''
			SELECT TOP (10) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM   #T 
			WHERE  Reftable = 0 

			SELECT @transId = CASE WHEN @transId <> '' THEN '(' + SUBSTRING(@transId, 2, LEN(@transId) - 1) + ') in bettrans,' END
			IF @transId <> '' BEGIN  SET @message = @message + @transId END


			SELECT @transId = ''
			SELECT TOP (10) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM   #T 
			WHERE  Reftable = 1 

			SELECT @transId = CASE WHEN @transId <> '' THEN '(' + SUBSTRING(@transId, 2, LEN(@transId) - 1) + ') in bettransRNG,' END
			IF @transId <> ''  BEGIN SET @message = @message + @transId  END


			SELECT @transId = ''
			SELECT TOP (10) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM   #T 
			WHERE  Reftable = 2 

			SELECT @transId = CASE WHEN @transId <> '' THEN '(' + SUBSTRING(@transId, 2, LEN(@transId) - 1) + ') in bettransLC,' END
			IF @transId <> ''  BEGIN SET @message = @message + @transId END

			SELECT @transId = ''
			SELECT TOP (10) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM   #T 
			WHERE  Reftable = 3 

			SELECT @transId = CASE WHEN @transId <> '' THEN '(' + SUBSTRING(@transId, 2, LEN(@transId) - 1) + ') in translog,' END
			IF @transId <> ''  BEGIN SET @message = @message + @transId END

			IF @message <> ''
			BEGIN
				SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
						,@ErrCode = 104
						,@ErrMsg = @ErrMsg + 'Wrong Epositiontaking vs ExtraPT' + Char(10) + Char(13)
						,@SampleData = @SampleData + 'Wrong Epositiontaking vs ExtraPT with transID ' + @message + '. '+ Char(10) + Char(13)
			END

	END
	IF @CheckMode = 2	
	BEGIN
		--- I.II: Epositiontaking IS NULL	
		------I.II.a. Bettrans
		INSERT INTO #T (epositiontaking, ExtraPT, TransID, Reftable, RuleID)						
		SELECT  TOP (10) epositiontaking, epositiontaking as ExtraPT, TransID, 0 as RefTable, 2 as RuleID  
		FROM 	bodb02.dbo.bettrans b WITH (NOLOCK)
		WHERE 	b.Epositiontaking IS NULL		
				AND b.winlostdate = @Winlostdate			
				AND b.bettype < 19001
				
		
		------I.II.b. translog
		INSERT INTO #T (epositiontaking, ExtraPT, TransID, Reftable, RuleID)			
		SELECT TOP (10) epositiontaking, epositiontaking as ExtraPT, translogid, 3 as RefTable, 2 as RuleID  
		FROM bodb02.dbo.translog b WITh (NOLOCK) 
		WHERE b.Epositiontaking IS NULL
				AND b.WinlostDate = @Winlostdate			
				  

		------I.II.c. BettransRNG
		INSERT INTO #T (epositiontaking, ExtraPT, TransID, Reftable, RuleID)			
		SELECT TOP (10) epositiontaking, epositiontaking as ExtraPT, TransID, 1 as RefTable, 2 as RuleID  
		FROM  bodb02.dbo.BettransRNG b WITH(NOLOCK)
		WHERE b.Epositiontaking IS NULL
				AND b.winlostdate = @Winlostdate	
				  


		------I.II.c. BettransLC	
		INSERT INTO #T (epositiontaking, ExtraPT, TransID, Reftable, RuleID)			
		SELECT TOP (10) epositiontaking, epositiontaking as ExtraPT, TransID, 2 as RefTable, 2 as RuleID  
		FROM   bodb02.dbo.BettransLC b WITH(NOLOCK)
		WHERE  b.Epositiontaking IS NULL
				AND b.winlostdate = @Winlostdate
					

		SELECT @transId = ''
		SELECT TOP (10) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM   #T 
		WHERE  Reftable = 0 

		SELECT @transId = CASE WHEN @transId <> '' THEN '(' + SUBSTRING(@transId, 2, LEN(@transId) - 1) + ') in bettrans,' END
		IF @transId <> '' BEGIN  SET @message = @message + @transId END


		SELECT @transId = ''
		SELECT TOP (10) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM   #T 
		WHERE  Reftable = 1 

		SELECT @transId = CASE WHEN @transId <> '' THEN '(' + SUBSTRING(@transId, 2, LEN(@transId) - 1) + ') in bettransRNG,' END
		IF @transId <> ''  BEGIN SET @message = @message + @transId  END


		SELECT @transId = ''
		SELECT TOP (10) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM   #T 
		WHERE  Reftable = 2 

		SELECT @transId = CASE WHEN @transId <> '' THEN '(' + SUBSTRING(@transId, 2, LEN(@transId) - 1) + ') in bettransLC,' END
		IF @transId <> ''  BEGIN SET @message = @message + @transId END

		SELECT @transId = ''
		SELECT TOP (10) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM   #T 
		WHERE  Reftable = 3 

		SELECT @transId = CASE WHEN @transId <> '' THEN '(' + SUBSTRING(@transId, 2, LEN(@transId) - 1) + ') in translog,' END
		IF @transId <> ''  BEGIN SET @message = @message + @transId END

		IF @message <> ''
		BEGIN
			SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
					,@ErrCode = 104
					,@ErrMsg = @ErrMsg + 'Epositiontaking IS NULL' + Char(10) + Char(13)
					,@SampleData = @SampleData + 'Epositiontaking IS NULL with transID ' + @message + '. '+ Char(10) + Char(13)
		END

	END
			
	
	IF @CheckMode = 3
	----II. Check tpositiontaking  + epositiontaking < 100% (for all tickets)
	BEGIN 	
		----II.I. Check tpositiontaking  + epositiontaking < 100% (for all tickets)
		------II.I.a. Bettrans
		INSERT INTO #T (epositiontaking, ExtraPT, TransID, Reftable, RuleID)							
		SELECT  TOP (10) epositiontaking, epositiontaking as ExtraPT, TransID, 0 as RefTable, 3 as RuleID  
		FROM 	bodb02.dbo.bettrans b WITH (NOLOCK)
		WHERE 	b.Epositiontaking + tpositiontaking > 1		
				AND b.winlostdate = @Winlostdate			
				AND b.bettype < 19001
			
			
		------II.I.b. translog
		INSERT INTO #T (epositiontaking, ExtraPT, TransID, Reftable, RuleID)						
		SELECT  TOP (10) epositiontaking, epositiontaking as ExtraPT, translogid, 3 as RefTable, 3 as RuleID  
		FROM 	bodb02.dbo.translog b WITH (NOLOCK)
		WHERE 	b.Epositiontaking + tpositiontaking > 1		
				AND b.winlostdate = @Winlostdate

		------II.I.c. BettransRNG
		INSERT INTO #T (epositiontaking, ExtraPT, TransID, Reftable, RuleID)						
		SELECT  TOP (10) epositiontaking, epositiontaking as ExtraPT, TransID, 1 as RefTable, 3 as RuleID  
		FROM 	bodb02.dbo.BettransRNG b WITH (NOLOCK)
		WHERE 	b.Epositiontaking + tpositiontaking > 1		
				AND b.winlostdate = @Winlostdate
								
			
		------II.I.d. BettransLC			
		INSERT INTO #T (epositiontaking, ExtraPT, TransID, Reftable, RuleID)							
		SELECT  TOP (10) epositiontaking, epositiontaking as ExtraPT, TransID, 2 as RefTable, 3 as RuleID  
		FROM 	bodb02.dbo.BettransLC b WITH (NOLOCK)
		WHERE 	b.Epositiontaking + tpositiontaking > 1		
				AND b.winlostdate = @Winlostdate
					
			
		SELECT @transId = ''
		SELECT TOP (10) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM   #T 
		WHERE  Reftable = 0 

		SELECT @transId = CASE WHEN @transId <> '' THEN '(' + SUBSTRING(@transId, 2, LEN(@transId) - 1) + ') in bettrans,' END
		IF @transId <> '' BEGIN  SET @message = @message + @transId END


		SELECT @transId = ''
		SELECT TOP (10) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM   #T 
		WHERE  Reftable = 1 

		SELECT @transId = CASE WHEN @transId <> '' THEN '(' + SUBSTRING(@transId, 2, LEN(@transId) - 1) + ') in bettransRNG,' END
		IF @transId <> ''  BEGIN SET @message = @message + @transId  END


		SELECT @transId = ''
		SELECT TOP (10) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM   #T 
		WHERE  Reftable = 2 

		SELECT @transId = CASE WHEN @transId <> '' THEN '(' + SUBSTRING(@transId, 2, LEN(@transId) - 1) + ') in bettransLC,' END
		IF @transId <> ''  BEGIN SET @message = @message + @transId END

		SELECT @transId = ''
		SELECT TOP (10) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM   #T 
		WHERE  Reftable = 3 

		SELECT @transId = CASE WHEN @transId <> '' THEN '(' + SUBSTRING(@transId, 2, LEN(@transId) - 1) + ') in translog,' END
		IF @transId <> ''  BEGIN SET @message = @message + @transId END

		IF @message <> ''
		BEGIN
			SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
					,@ErrCode = 104
					,@ErrMsg = @ErrMsg + 'Epositiontaking + Tpositiontaking > 1' + Char(10) + Char(13)
					,@SampleData = @SampleData + 'Epositiontaking + Tpositiontaking > 1 with transID ' + @message + '. '+ Char(10) + Char(13)
		END
	END 
	DROP TABLE #SportBettype 
	DROP TABLE #T
	
END 
GO 