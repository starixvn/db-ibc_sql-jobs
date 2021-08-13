/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_Consistency_CashoutChecking]
	@ProductId		INT		
	,@Rule			INT
	,@ErrCode		INT			 = 0	OUTPUT
	,@ErrMsg		VARCHAR(MAX) = ''	OUTPUT 
	,@SampleData	VARCHAR(MAX) = ''	OUTPUT
AS
/*
	Created: 20210528@July
	Task: Data consistency
	DB: DBCONSISTENCY-bodb_Consistency

	Revisions: 
		- 20210528@July: Check Cashout apply for Sportbook [Redmine:#155761]
		- 20210727@July: Check Data Consistency - Add rule for CashOut [Redmine:#158948]
	
	Param's Expanation:
*/
BEGIN
	DECLARE @transId VARCHAR(MAX)
			,@yesterday DATETIME 

	SET @transId = ''
	SET @yesterday = DATEADD(DAY,-1,CAST(GETDATE() AS DATE))

	CREATE TABLE #CashOutTickets (	
		Matchid				INT,
		TransId				BIGINT,
		BetType				SMALLINT,
		StatusId			TINYINT,	
		RefNo				BIGINT,					
		OriginalBetType		SMALLINT,
		ExtraInfo			VARCHAR(1000),	
		BetdaqId			BIGINT,
		Winlostdate			DATETIME,
		CustId              INT,
		IsDummyCO			BIT DEFAULT(0)
	)

	DECLARE @tblCheckCashOut TABLE (Matchid INT, TransId BIGINT, BetType SMALLINT , OriginalBetType SMALLINT, StatusId TINYINT, Winlostdate SMALLDATETIME, RefNo BIGINT)

	IF @ProductId = 1
	BEGIN
		-- CASE 1: Check main bet tickets is Voided/Rejected, related tickets need have Voided/Rejected
		IF @Rule = 1
		BEGIN
			INSERT @tblCheckCashOut (matchid, transid, bettype, OriginalBetType, statusId, winlostdate)
			SELECT sub.matchid, sub.transid, sub.bettype, main.bettype, sub.statusID, main.winlostdate
			FROM bodb02.dbo.bettrans sub WITH(NOLOCK)
					INNER JOIN bodb02.dbo.bettrans main WITH(NOLOCK)
							ON	main.transid = sub.refno
							AND main.custid = sub.custid
							AND main.matchid = sub.matchid
			WHERE	 sub.bettype = 911 -- SOLD tickets
					AND sub.statusID NOT IN (101,102)
					AND main.statusID IN (101,102) --Rejected, Void
					AND main.betdaqid = 0
					AND CHARINDEX ('p25',main.extrainfo)> 0
					AND main.winlostdate = @yesterday

			INSERT @tblCheckCashOut (transid, bettype, OriginalBetType, statusId, winlostdate)
			SELECT b.transid, b.bettype, sub911.OriginalBetType, b.statusId, sub911.winlostdate
			FROM @tblCheckCashOut sub911
			CROSS APPLY (SELECT b.transid, b.bettype, b.statusID
								  FROM bodb02.dbo.bettrans b WITH(NOLOCK)
								  WHERE	sub911.transid = b.refno
									AND sub911.matchid = b.matchid
									AND b.bettype IN (sub911.OriginalBetType, 912, 913) -- Dummy Cashout BetTicket, 912, 913
									AND b.statusID NOT IN (101,102)
						)b
			WHERE sub911.winlostdate = @yesterday

			SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM @tblCheckCashOut

			IF @transId <> ''
			BEGIN
				SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
						,@ErrCode = 100
						,@ErrMsg = 'Check if main bet ticket is Voided/Rejected, ticket 911 and Dummy Cashout BetTicket, 912, 913 need have status Voided/Rejected on product ' + CAST(@ProductId AS VARCHAR)
						,@SampleData = 'bettrans.TransId IN (' + @transId +' )'
			END

		END

		-- CASE 2: Check Cashout ticket (911) is Voided, related tickets need have Voided
		IF @Rule = 2
		BEGIN
			INSERT @tblCheckCashOut (matchid, transid, bettype, OriginalBetType, statusId, winlostdate)
			SELECT sub.matchid, sub.transid, sub.bettype, main.bettype, sub.statusID, main.winlostdate
			FROM bodb02.dbo.bettrans sub WITH(NOLOCK)
					INNER JOIN bodb02.dbo.bettrans main WITH(NOLOCK)
							ON	main.transid = sub.refno
							AND main.custid = sub.custid
							AND main.matchid = sub.matchid
			WHERE	 sub.bettype = 911 -- SOLD tickets
					AND sub.statusID = 102 --Voided
					AND main.winlostdate = @yesterday

			INSERT @tblCheckCashOut (transid, bettype, OriginalBetType, statusId, winlostdate)
			SELECT b.transid, b.bettype, sub911.OriginalBetType, b.statusId, sub911.winlostdate
			FROM @tblCheckCashOut sub911
			CROSS APPLY (SELECT b.transid, b.bettype, b.statusID
									FROM bodb02.dbo.bettrans b WITH(NOLOCK)
									WHERE	sub911.transid = b.refno
									AND sub911.matchid = b.matchid
									AND b.bettype IN (sub911.OriginalBetType, 912, 913) -- Dummy Cashout BetTicket, 912, 913
									AND b.statusID NOT IN (102) 
						)b
			WHERE sub911.winlostdate = @yesterday

			SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
			FROM @tblCheckCashOut
			WHERE bettype NOT IN (911)
					
			IF @transId <> ''
			BEGIN
				SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
						,@ErrCode = 100
						,@ErrMsg = 'Check if Cashout ticket (bettype 911) is Voided related tickets (Dummy CashOut Bet Ticket, ticket 912, 913) need have status Voided on product ' + CAST(@ProductId AS VARCHAR)
						,@SampleData = 'bettrans.TransId IN (' + @transId +' )'
			END
		END

		IF @Rule IN (3,4)
		BEGIN
			-- Get MAIN ticket of Cash-out
			INSERT INTO #CashOutTickets (Matchid, TransId, BetType, StatusId, RefNo, OriginalBetType, ExtraInfo, BetdaqId, Winlostdate, CustId)
			SELECT matchid, transid, bettype, statusID, refno, bettype, extraInfo, betdaqid, winlostdate, custid
			FROM bodb02.dbo.bettrans  WITH(NOLOCK)
			WHERE betdaqid = 0
				AND CHARINDEX ('p25',extrainfo)> 0
				AND winlostdate = @yesterday

			-- Get sub ticket of Cash-out (911)
			INSERT INTO #CashOutTickets (Matchid, TransId, BetType, StatusId, RefNo, OriginalBetType, ExtraInfo, BetdaqId, Winlostdate, CustId)
			SELECT  main.matchid, sub911.transid, sub911.bettype, sub911.statusID, sub911.refno, main.bettype, sub911.extraInfo, sub911.betdaqid, sub911.winlostdate, sub911.custid
			FROM bodb02.dbo.bettrans sub911 WITH(NOLOCK)
					INNER JOIN #CashOutTickets main 
						ON	sub911.refno = main.transid	
							AND sub911.custid = main.custid							
							AND sub911.bettype = 911
							AND sub911.matchid = main.matchid
			AND sub911.winlostdate = @yesterday

			-- Get Dummy Cashout BetTicket, 912, 913
			INSERT INTO #CashOutTickets (Matchid, TransId, BetType, StatusId, RefNo, OriginalBetType, ExtraInfo, BetdaqId, Winlostdate, CustId, IsDummyCO)
			SELECT sub911.matchid, b.transid, b.bettype, b.statusID, b.refno, sub911.bettype, sub911.extraInfo, sub911.betdaqid, sub911.winlostdate, sub911.custid, b.IsDummyCO
			FROM #CashOutTickets sub911
			CROSS APPLY (SELECT b.transid, b.bettype, b.statusID, b.status, b.refno
								, CASE WHEN b.bettype = sub911.OriginalBetType THEN 1
										ELSE 0 END AS IsDummyCO -- Dummy CO
						 FROM bodb02.dbo.bettrans b WITH(NOLOCK)
						 WHERE	sub911.transid = b.refno
							AND sub911.matchid = b.matchid
							AND b.bettype IN (sub911.OriginalBetType, 912, 913) -- Dummy Cashout BetTicket, 912, 913
						)b
			WHERE sub911.bettype = 911 
			AND sub911.winlostdate = @yesterday

			-- CASE 3: Check if dummy Cashout bet ticket is Rejected -->  Main ticket, ticket 911 (has same RefNo with main ticket) and 912, 913 (have same RefNo with 911) need have status 'Rejected'.
			IF @Rule = 3
			BEGIN
				INSERT INTO @tblCheckCashOut (matchid, transid, bettype, OriginalBetType, statusId, winlostdate, RefNo)
				SELECT sub.matchid, sub.TransId, sub.bettype, sub.OriginalBetType, sub.statusId, sub.winlostdate, sub.RefNo
				FROM #CashOutTickets dummy
				   CROSS APPLY ( SELECT matchid, transid, bettype, OriginalBetType, statusId, winlostdate, RefNo
								 FROM #CashOutTickets sub 
								 WHERE  sub.Matchid = dummy.Matchid
									AND sub.CustId = dummy.CustId
									AND 1 = CASE WHEN dummy.RefNo = sub.RefNo AND sub.StatusId <> 101 THEN 1
												 WHEN dummy.RefNo = sub.transid AND sub.bettype IN (911) THEN 1
												 ELSE 0 END
						)sub
				WHERE dummy.IsDummyCO = 1 AND dummy.statusID = 101 --Reject

				INSERT INTO @tblCheckCashOut (matchid, transid, bettype, OriginalBetType, statusId, winlostdate, RefNo)
				SELECT main.Matchid, main.TransId, main.bettype, main.OriginalBetType, main.statusId, main.winlostdate, main.RefNo
				FROM @tblCheckCashOut sub911
					INNER JOIN #CashOutTickets main 
						ON sub911.refno = main.transid	
								AND sub911.matchid = main.Matchid							
								AND sub911.bettype = 911
				WHERE main.StatusId <> 101 --Reject


				SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
				FROM @tblCheckCashOut
				WHERE statusId <> 101 --Reject
					
				IF @transId <> ''
				BEGIN
					SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
							,@ErrCode = 100
							,@ErrMsg = 'Check if Dummy CO ticket is Rejected, Ticket main and 911(same RefNo main), 912,913(same RefNo 911) are Rejected on product ' + CAST(@ProductId AS VARCHAR)
							,@SampleData = 'bettrans.TransId IN (' + @transId +' )'
				END
			END

			-- CASE 4: Check if Cashout ticket (bettype 912 or 913) is Voided, related tickets (Dummy CashOut Bet Ticket, ticket 911, 912, 913 with same RefNo with 911) are Voided as well.
			IF @Rule = 4
			BEGIN
				INSERT INTO @tblCheckCashOut (matchid, transid, bettype, OriginalBetType, statusId, winlostdate, RefNo)
				SELECT t.matchid, t.transid, t.bettype, t.OriginalBetType, t.statusId, t.winlostdate, t.RefNo
				FROM #CashOutTickets subCO
					CROSS APPLY ( SELECT matchid, transid, bettype, OriginalBetType, statusId, winlostdate, RefNo
									FROM #CashOutTickets t
									WHERE  t.Matchid = subCO.Matchid
										AND t.CustId = subCO.CustId
										AND t.StatusId <> 102
										AND 1 = CASE WHEN subCO.RefNo = t.RefNo THEN 1
													 WHEN subCO.RefNo = t.transid AND t.bettype IN (911) THEN 1
												ELSE 0 END
								)t
				WHERE subCO.bettype IN (912,913) AND subCO.StatusId = 102

				SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
				FROM @tblCheckCashOut
					
				IF @transId <> ''
				BEGIN
					SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
							,@ErrCode = 100
							,@ErrMsg = 'Check if Cashout ticket(912,913) is Voided, Dummy CO Bet Ticket and ticket 911, 912, 913 with same RefNo with 911 are Voided on product ' + CAST(@ProductId AS VARCHAR)
							,@SampleData = 'bettrans.TransId IN (' + @transId +' )'
				END
			END
		END

	END
	DROP TABLE #CashOutTickets;
END
GO
