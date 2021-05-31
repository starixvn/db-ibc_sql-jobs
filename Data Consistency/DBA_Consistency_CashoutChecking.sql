/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_CashoutChecking]
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
	
	Param's Expanation:
*/
BEGIN
	DECLARE @transId VARCHAR(MAX)
			,@yesterday DATETIME 

	SET @transId = ''
	SET @yesterday = DATEADD(DAY,-1,CAST(GETDATE() AS DATE))

	DECLARE @tblCheckCashOut TABLE (matchid INT, transid BIGINT, bettype SMALLINT , OriginalBetType SMALLINT, statusId TINYINT, winlostdate SMALLDATETIME)

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
			CROSS APPLY (SELECT b.*
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
			CROSS APPLY (SELECT b.*
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
	END
END
GO
