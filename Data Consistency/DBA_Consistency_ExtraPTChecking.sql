/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" isFunction="0"></info>*/
USE [bodb_Consistency]
GO

ALTER PROCEDURE [dbo].[DBA_Consistency_ExtraPTChecking]	
	@RuleID 		TINYINT 		= 0
	,@WinlostDate	SMALLDATETIME 	= NULL
	,@ErrCode		INT				= 0		OUTPUT
	,@ErrMsg		VARCHAR(MAX)	= ''	OUTPUT  
AS
/*
	Created: 20200120@Sophia
	Task: Data consistency - Check ExtraPT vs Epositiontaking
	DB: DBTP/bodb_Consistency

	Revisions: 
		- 20200110@Sophia: initial SP [Redmine: #122071]
		- 20200120@Sophia: Add rule 92% [Redmine: #127042]
	
	Param's Expanation:
		@RuleID = 26   . Wrong Epositiontaking vs ExtraPT
					   . Epositiontaking IS NULL
					   
				= 27   . Epositiontaking + Tpositiontaking > 1
				
				= 28   . Epositiontaking has value under headline XP%
					   . TPositiontaking <> 92% under headline XP% 
		
*/
BEGIN 


	DECLARE @transId VARCHAR(MAX) = '' 
	SELECT @ErrMsg  = ''
	
	IF @WinlostDate IS NULL
	SELECT @Winlostdate = CONVERT (DATE, GETDATE())  
	
	
	CREATE TABLE  #SportBettype (ProductID INT, Bettype INT,SubProduct VARCHAR(500), RefTable SMALLINT)
	INSERT INTO #SportBettype
	SELECT DISTINCT ProductID, Bettype, SubProduct, RefTable  FROM bodb02.dbo.f_SportBettypeMatrix_Sel (0, 0, 0, 2, '', '', 1)

	DELETE #SportBettype WHERE ProductId NOT IN (SELECT DISTINCT ProductID FROM bodb02.dbo.Acc_GroupExtraPTSetting WITH(NOLOCK))	
	
 	CREATE TABLE #T (epositiontaking smallmoney , ExtraPT [decimal](9, 8), transID BIGINT, Reftable Smallint, RuleID Smallint)
 
	---------------------------------Select data -------------------------
	----I. Check Wrong Epositiontaking vs ExtraPT
	IF @RuleID = 26 OR @RuleID = 0
	BEGIN 
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
				AND b.bettype < 19001		
				AND b.Epositiontaking <> ISNULL(pt.ExtraPT,0)		

		  
			SELECT @transId = ''
			SELECT TOP (10) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM   #T 
			WHERE  Reftable = 0 AND RuleID = 1 	
			
			IF @transId <> ''
			BEGIN
				SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
						,@ErrCode = 101					
						,@ErrMsg = @ErrMsg + 'Wrong Epositiontaking vs ExtraPT with bettrans.TransId in (' + @transId + ') ' + Char(10) + Char(13)
			END	

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
					WHERE  b.winlostdate = @Winlostdate	 
						AND b.Epositiontaking <> ISNULL(pt.ExtraPT,0)	
						
			SELECT @transId = ''
			SELECT TOP (10) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM   #T 
			WHERE  Reftable = 3 AND RuleID = 1
			
			IF @transId <> ''
			BEGIN
				SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
						,@ErrCode = 102
						,@ErrMsg = @ErrMsg + 'Wrong Epositiontaking vs ExtraPT with translog.translogid in (' + @transId + ') ' + Char(10) + Char(13)
			END
			
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
			
			SELECT @transId = ''
			SELECT TOP (10) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM   #T 
			WHERE  Reftable = 1 AND RuleID = 1	
			
			IF @transId <> ''
			BEGIN
				SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
						,@ErrCode = 103
						,@ErrMsg = @ErrMsg + 'Wrong Epositiontaking vs ExtraPT with BettransRNG.transID in (' + @transId + ')'+ Char(10) + Char(13)
			END
			
			
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
							 	
	
			SELECT @transId = ''
			SELECT TOP (10) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM   #T 
			WHERE  Reftable = 2 AND RuleID = 1
			
			IF @transId <> ''
			BEGIN
				SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
						,@ErrCode = 104
						,@ErrMsg = @ErrMsg + 'Wrong Epositiontaking vs ExtraPT with BettransLC.transID in (' + @transId + ')'+ Char(10) + Char(13)
			END
			
			--- I.II: Epositiontaking IS NULL	
			------I.II.a. Bettrans
			INSERT INTO #T (epositiontaking, ExtraPT, TransID, Reftable, RuleID)						
			SELECT  TOP (10) epositiontaking, epositiontaking as ExtraPT, TransID, 0 as RefTable, 2 as RuleID  
			FROM 	bodb02.dbo.bettrans b WITH (NOLOCK)
			WHERE 	b.Epositiontaking IS NULL		
					AND b.winlostdate = @Winlostdate			
					AND b.bettype < 19001
					
			SELECT @transId = ''
			SELECT TOP (10) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM   #T 
			WHERE  Reftable = 0 AND RuleID = 2	
			
			IF @transId <> ''
			BEGIN
				SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
						,@ErrCode = 105
						,@ErrMsg = @ErrMsg + 'Epositiontaking IS NULL with bettrans.TransId in (' + @transId + ') ' + Char(10) + Char(13)
			END
					
		
			------I.II.b. translog
			INSERT INTO #T (epositiontaking, ExtraPT, TransID, Reftable, RuleID)			
			SELECT TOP (10) epositiontaking, epositiontaking as ExtraPT, translogid, 3 as RefTable, 2 as RuleID  
			FROM bodb02.dbo.translog b WITh (NOLOCK) 
			WHERE b.Epositiontaking IS NULL
				  AND b.WinlostDate = @Winlostdate			
				  
			SELECT @transId = ''
			SELECT TOP (10) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM   #T 
			WHERE  Reftable = 3 AND RuleID = 2	
			
			IF @transId <> ''
			BEGIN
				SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
						,@ErrCode = 106
						,@ErrMsg = @ErrMsg + 'Epositiontaking IS NULL with translog.translogid in (' + @transId + ') ' + Char(10) + Char(13)
			END

			------I.II.c. BettransRNG
			INSERT INTO #T (epositiontaking, ExtraPT, TransID, Reftable, RuleID)			
			SELECT TOP (10) epositiontaking, epositiontaking as ExtraPT, TransID, 1 as RefTable, 2 as RuleID  
			FROM  bodb02.dbo.BettransRNG b WITH(NOLOCK)
			WHERE b.Epositiontaking IS NULL
				  AND b.winlostdate = @Winlostdate	
				  
			SELECT @transId = ''
			SELECT TOP (10) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM   #T 
			WHERE  Reftable = 1 AND RuleID = 2 	
			
			IF @transId <> ''
			BEGIN
				SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
						,@ErrCode = 107
						,@ErrMsg = @ErrMsg + 'Epositiontaking IS NULL with BettransRNG.transID in (' + @transId + ')'+ Char(10) + Char(13)
			END

			------I.II.c. BettransLC	
			INSERT INTO #T (epositiontaking, ExtraPT, TransID, Reftable, RuleID)			
			SELECT TOP (10) epositiontaking, epositiontaking as ExtraPT, TransID, 2 as RefTable, 2 as RuleID  
			FROM   bodb02.dbo.BettransLC b WITH(NOLOCK)
			WHERE  b.Epositiontaking IS NULL
					AND b.winlostdate = @Winlostdate
					
			SELECT @transId = ''
			SELECT TOP (10) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM   #T 
			WHERE  Reftable = 2 AND RuleID = 2  	
			
			IF @transId <> ''
			BEGIN
				SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
						,@ErrCode = 108
						,@ErrMsg = @ErrMsg + 'Epositiontaking IS NULL with BettransLC.transID in (' + @transId + ')'+ Char(10) + Char(13)
			END
			
	END 
		
	----II. Check tpositiontaking  + epositiontaking < 100% (for all tickets)
	IF @RuleID = 27  OR @RuleID = 0
	BEGIN 	
			----II.I. Check tpositiontaking  + epositiontaking < 100% (for all tickets)
			------II.I.a. Bettrans
			INSERT INTO #T (epositiontaking, ExtraPT, TransID, Reftable, RuleID)							
			SELECT  TOP (10) epositiontaking, epositiontaking as ExtraPT, TransID, 0 as RefTable, 3 as RuleID  
			FROM 	bodb02.dbo.bettrans b WITH (NOLOCK)
			WHERE 	b.Epositiontaking + tpositiontaking > 1		
					AND b.winlostdate = @Winlostdate			
					AND b.bettype < 19001
			
			SELECT @transId = ''
			SELECT TOP (10) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM   #T 
			WHERE  Reftable = 0 AND RuleID = 3	
			
			IF @transId <> ''
			BEGIN
				SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
						,@ErrCode = 109
						,@ErrMsg = @ErrMsg + 'Epositiontaking + Tpositiontaking > 1 with bettrans.TransId in (' + @transId + ') ' + Char(10) + Char(13)
			END				
			
			------II.I.b. translog
			INSERT INTO #T (epositiontaking, ExtraPT, TransID, Reftable, RuleID)						
			SELECT  TOP (10) epositiontaking, epositiontaking as ExtraPT, translogid, 3 as RefTable, 3 as RuleID  
			FROM 	bodb02.dbo.translog b WITH (NOLOCK)
			WHERE 	b.Epositiontaking + tpositiontaking > 1		
					AND b.winlostdate = @Winlostdate

			SELECT @transId = ''
			SELECT TOP (10) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM   #T 
			WHERE  Reftable = 3 AND RuleID = 3	
			
			IF @transId <> ''
			BEGIN
				SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
						,@ErrCode = 110
						,@ErrMsg = @ErrMsg + 'Epositiontaking + Tpositiontaking > 1 with translog.translogid in (' + @transId + ') ' + Char(10) + Char(13)
			END

			
			------II.I.c. BettransRNG
			INSERT INTO #T (epositiontaking, ExtraPT, TransID, Reftable, RuleID)						
			SELECT  TOP (10) epositiontaking, epositiontaking as ExtraPT, TransID, 1 as RefTable, 3 as RuleID  
			FROM 	bodb02.dbo.BettransRNG b WITH (NOLOCK)
			WHERE 	b.Epositiontaking + tpositiontaking > 1		
					AND b.winlostdate = @Winlostdate
					
			SELECT @transId = ''
			SELECT TOP (10) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM   #T 
			WHERE  Reftable = 1 AND RuleID = 3	
			
			IF @transId <> ''
			BEGIN
				SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
						,@ErrCode = 111
						,@ErrMsg = @ErrMsg + 'Epositiontaking + Tpositiontaking > 1 with BettransRNG.transID in (' + @transId + ')'+ Char(10) + Char(13)
			END								
			
			------II.I.d. BettransLC			
			INSERT INTO #T (epositiontaking, ExtraPT, TransID, Reftable, RuleID)							
			SELECT  TOP (10) epositiontaking, epositiontaking as ExtraPT, TransID, 2 as RefTable, 3 as RuleID  
			FROM 	bodb02.dbo.BettransLC b WITH (NOLOCK)
			WHERE 	b.Epositiontaking + tpositiontaking > 1		
					AND b.winlostdate = @Winlostdate
					
			SELECT @transId = ''
			SELECT TOP (10) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM   #T 
			WHERE  Reftable = 2 AND RuleID = 3	
			
			IF @transId <> ''
			BEGIN
				SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
						,@ErrCode = 112
						,@ErrMsg = @ErrMsg + 'Epositiontaking + Tpositiontaking > 1 with BettransLC.transID in (' + @transId + ')'+ Char(10) + Char(13)
			END		
			
	END 
	
	
	----III. Check Extra PT = 0 for CN88 with username of headline has prefix 'XP%' (for CN88 site)
	IF @RuleID = 28  OR @RuleID = 0
	BEGIN 	
		----III.I. Epositiontaking has value under headline XP% 
			------III.I.a. Bettrans			
			INSERT INTO #T (epositiontaking, ExtraPT, TransID, Reftable, RuleID)		
			SELECT  TOP (10) epositiontaking, epositiontaking as ExtraPT, TransID, 0 as RefTable, 4 as RuleID
			FROM 	bodb02.dbo.bettrans b WITH (NOLOCK)
			WHERE   EXISTS (SELECT 1 FROM bodb02.dbo.f_GetHeadlineNoPT() f WHERE f.SuperID = b.Srecommend)
					AND b.Epositiontaking <> 0
					AND b.winlostdate = @Winlostdate			
					AND b.bettype < 19001	

			SELECT @transId = ''
			SELECT TOP (10) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM   #T 
			WHERE  Reftable = 0 AND RuleID = 4
			
			IF @transId <> ''
			BEGIN
				SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
						,@ErrCode = 114
						,@ErrMsg = @ErrMsg + 'Epositiontaking has value under headline XP% with bettrans.TransId in (' + @transId + ') ' + Char(10) + Char(13)
			END					
			
			------III.I.b. translog
			INSERT INTO #T (epositiontaking, ExtraPT, TransID, Reftable, RuleID)				
			SELECT TOP (10)  epositiontaking, epositiontaking as ExtraPT, translogid, 3 as RefTable, 4 as RuleID
			FROM bodb02.dbo.translog b WITh (NOLOCK)
			WHERE  EXISTS (SELECT 1 FROM bodb02.dbo.f_GetHeadlineNoPT() f WHERE f.SuperID = b.Srecommend)
				  AND b.Epositiontaking <> 0
				  AND b.WinlostDate = @Winlostdate
			
			SELECT @transId = ''
			SELECT TOP (10) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM   #T 
			WHERE  Reftable = 3 AND RuleID = 4
			
			IF @transId <> ''
			BEGIN
				SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
						,@ErrCode = 115
						,@ErrMsg = @ErrMsg + 'Epositiontaking has value under headline XP% with translog.translogid in (' + @transId + ') ' + Char(10) + Char(13)
			END
	
			
			------III.I.c. BettransRNG
			INSERT INTO #T (epositiontaking, ExtraPT, TransID, Reftable, RuleID)		
			SELECT TOP (10) epositiontaking, epositiontaking as ExtraPT, TransID, 1 as RefTable, 4 as RuleID
			FROM bodb02.dbo.BettransRNG b WITH(NOLOCK)
			WHERE  EXISTS (SELECT 1 FROM bodb02.dbo.f_GetHeadlineNoPT() f WHERE f.SuperID = b.Srecommend)
				  AND b.Epositiontaking <> 0
				  AND b.winlostdate = @Winlostdate	
				  
			SELECT @transId = ''
			SELECT TOP (10) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM   #T 
			WHERE  Reftable = 1 AND RuleID = 4
			
			IF @transId <> ''
			BEGIN
				SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
						,@ErrCode = 116
						,@ErrMsg = @ErrMsg + 'Epositiontaking has value under headline XP% with BettransRNG.transID in (' + @transId + ')'+ Char(10) + Char(13)
			END
				  
			
			------III.I.d. BettransLC
			INSERT INTO #T (epositiontaking, ExtraPT, TransID, Reftable, RuleID)		
			SELECT TOP (10) epositiontaking, epositiontaking as ExtraPT, TransID, 2 as RefTable, 4 as RuleID
			FROM bodb02.dbo.BettransLC b WITH(NOLOCK)
			WHERE  EXISTS (SELECT 1 FROM bodb02.dbo.f_GetHeadlineNoPT() f WHERE f.SuperID = b.Srecommend)
				  AND b.Epositiontaking <> 0
				  AND b.winlostdate = @Winlostdate	
				  
			SELECT @transId = ''
			SELECT TOP (10) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM   #T 
			WHERE  Reftable = 2 AND RuleID = 4
			
			IF @transId <> ''
			BEGIN
				SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
						,@ErrCode = 117
						,@ErrMsg = @ErrMsg + 'Epositiontaking has value under headline XP% with BettransLC.transID in (' + @transId + ')'+ Char(10) + Char(13)
			END
				  
			
		----III.II. TPositiontaking <> 92% under headline XP% 	
			------III.II.a. Bettrans
			INSERT INTO #T (epositiontaking, ExtraPT, TransID, Reftable, RuleID) 			
			SELECT  TOP (10) epositiontaking, epositiontaking as ExtraPT, TransID, 0 as RefTable, 5 as RuleID
			FROM 	bodb02.dbo.bettrans b WITH (NOLOCK)
			WHERE  EXISTS (SELECT 1 FROM bodb02.dbo.f_GetHeadlineNoPT() f WHERE f.SuperID = b.Srecommend)
				   AND b.tpositiontaking <> 0.92
				   AND b.winlostdate = @Winlostdate			
				   AND b.bettype < 19001
				   
			SELECT @transId = ''
			SELECT TOP (10) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM   #T 
			WHERE  Reftable = 0 AND RuleID = 5
			
			IF @transId <> ''
			BEGIN
				SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
						,@ErrCode = 118
						,@ErrMsg = @ErrMsg + 'TPositiontaking <> 92% under headline XP% with bettrans.TransId in (' + @transId + ') ' + Char(10) + Char(13)
			END
			
			------III.II.b. translog
			INSERT INTO #T (epositiontaking, ExtraPT, TransID, Reftable, RuleID)				
			SELECT TOP (10) epositiontaking, epositiontaking as ExtraPT, translogid, 3 as RefTable, 5 as RuleID
			FROM bodb02.dbo.translog b WITh (NOLOCK)
			WHERE EXISTS (SELECT 1 FROM bodb02.dbo.f_GetHeadlineNoPT() f WHERE f.SuperID = b.Srecommend)
				  AND b.tpositiontaking <> 0.92	
				  AND b.WinlostDate = @Winlostdate	
				  
			SELECT @transId = ''
			SELECT TOP (10) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM   #T 
			WHERE  Reftable = 3 AND RuleID = 5
			
			IF @transId <> ''
			BEGIN
				SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
						,@ErrCode = 119
						,@ErrMsg = @ErrMsg + 'TPositiontaking <> 92% under headline XP% with translog.translogid in (' + @transId + ')'
			END
			
			------III.II.c. BettransRNG
			INSERT INTO #T (epositiontaking, ExtraPT, TransID, Reftable, RuleID)					
			SELECT TOP (10) epositiontaking,epositiontaking as ExtraPT, TransID, 1 as RefTable, 5 as RuleID
			FROM bodb02.dbo.BettransRNG b WITH(NOLOCK)
			WHERE EXISTS (SELECT 1 FROM bodb02.dbo.f_GetHeadlineNoPT() f WHERE f.SuperID = b.Srecommend)
				  AND b.tpositiontaking <> 0.92
				  AND b.winlostdate = @Winlostdate		
				  
			SELECT @transId = ''
			SELECT TOP (10) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM   #T 
			WHERE  Reftable = 1 AND RuleID = 5
			
			IF @transId <> ''
			BEGIN
				SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
						,@ErrCode = 120
						,@ErrMsg = @ErrMsg + 'TPositiontaking <> 92% under headline XP% with BettransRNG.transID in (' + @transId + ')'+ Char(10) + Char(13)
			END
			
			------III.II.d. BettransLC
			INSERT INTO #T (epositiontaking, ExtraPT, TransID, Reftable, RuleID)		 			
			SELECT TOP (10) epositiontaking,epositiontaking as ExtraPT, TransID, 2 as RefTable, 5 as RuleID
			FROM bodb02.dbo.BettransLC b WITH(NOLOCK)
			WHERE EXISTS (SELECT 1 FROM bodb02.dbo.f_GetHeadlineNoPT() f WHERE f.SuperID = b.Srecommend)
				  AND b.tpositiontaking <> 0.92
				  AND b.winlostdate = @Winlostdate	
				  
			SELECT @transId = ''
			SELECT TOP (10) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM   #T 
			WHERE  Reftable = 2 AND RuleID = 5
			
			IF @transId <> ''
			BEGIN
				SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
						,@ErrCode = 121
						,@ErrMsg = @ErrMsg + 'TPositiontaking <> 92% under headline XP% with BettransLC.transID in (' + @transId + ')'+ Char(10) + Char(13)
			END
	END 
	
		
		
	DROP TABLE #SportBettype 
	DROP TABLE #T
	
	 
END 
GO 