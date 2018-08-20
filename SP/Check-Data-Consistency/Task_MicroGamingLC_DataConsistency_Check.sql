/*<info serverAlias="DBTP-bodb02" executers="" viewers="vnteam" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[Task_MicroGamingLC_DataConsistency_Check]
	@FDate			SMALLDATETIME, 
	@TDate			SMALLDATETIME,
	@ProductId		INT,
	@ErrMessage		VARCHAR(512) = '' OUTPUT
AS
/*
	Created: Francis
	CreatedDate: 20160316
	Task: Check data between bettrans & translog for MGC LC (Run on DB06/DBTP)
	DB: DBTP.bodb02
		
	Revision:
		- 20160517@Patrick: VoidBridge Integration [Redmine: #57675]
		- 20160609@Helen: Remove case 6 from service to check ticket correctness - [Redmine: 58904]
		- 20180518@Kathy: Add code for Bullfighting [Redmine:#95199]
*/
BEGIN
	DECLARE	@FromDate SMALLDATETIME
			,@ToDate SMALLDATETIME

	CREATE TABLE #tmpData (
		translogid BIGINT, custid INT, stake MONEY, status NVARCHAR(10)
		, apositiontaking SMALLMONEY, mpositiontaking SMALLMONEY, tpositiontaking SMALLMONEY, spositiontaking SMALLMONEY
		, playerdiscount DECIMAL(9,8), discount DECIMAL(9,8), adiscount DECIMAL(9,8), sdiscount DECIMAL(9,8)
		, winlostdate SMALLDATETIME, actual_stake MONEY, statusID TINYINT
		, productID INT, gameID INT, eventID INT, currency TINYINT
		, tmpmatchId INT
	)

	SELECT @FromDate = @FDate
			,@ToDate = @TDate
			,@ErrMessage = ''

	INSERT INTO #tmpData(
		translogid, custid, stake, status
		, apositiontaking, mpositiontaking, tpositiontaking, spositiontaking
		, playerdiscount, discount , adiscount , sdiscount 
		, winlostdate , actual_stake , statusID 
		, productID , gameID , eventID, currency
		, tmpmatchId
	)
	SELECT	translogid, custid, stake, status
			, apositiontaking, mpositiontaking, tpositiontaking, spositiontaking
			, playerdiscount, discount , adiscount , sdiscount 
			, winlostdate , actual_stake , statusID 
			, productID , gameID , eventID, currency
			, CASE WHEN @ProductId = 207 THEN tl.eventID ELSE @ProductId END AS tmpmatchId
	FROM	dbo.translog tl WITH (NOLOCK)
	WHERE	tl.productID = @ProductId
			AND tl.winlostdate BETWEEN @FromDate AND @ToDate

	--Case 1: check data between translog & bettrans
	BEGIN
		SELECT	TOP 1
				'Case 1' AS [CASE]
				,*
		FROM	dbo.bettrans bt WITH (NOLOCK)
			INNER JOIN #tmpData tl
				ON	bt.refno = tl.translogid
		WHERE	bt.winlostdate BETWEEN @FromDate AND @ToDate
				AND bt.matchid = tl.tmpmatchId
				AND bt.statusID NOT IN (0, 1)
				AND (
					bt.stake <> tl.stake
					OR bt.actual_stake <> tl.actual_stake
					OR bt.status <> tl.status
					OR bt.playerdiscount <> tl.playerdiscount
					OR bt.discount <> tl.discount
					OR bt.adiscount <> tl.adiscount
					OR bt.sdiscount <> tl.sdiscount
					OR bt.apositiontaking <> tl.apositiontaking
					OR bt.mpositiontaking <> tl.mpositiontaking
					OR bt.spositiontaking <> tl.spositiontaking
					OR bt.tpositiontaking <> tl.tpositiontaking
					OR bt.bettype <> tl.gameID
					OR bt.statusID <> tl.statusID
				)
		
		IF @@ROWCOUNT > 0
		BEGIN
			SET @ErrMessage = @ErrMessage + 'Inconsistent - ProductId: ' + CAST(@ProductId AS VARCHAR) + ' - Case 1: Check ticket details between translog and bettrans.'
		
			RETURN
		END
	END

	--Case 2,3,4,5: check winlost, stake, comm
	BEGIN
		SELECT	TOP 1
				'Case 2,3,4,5' AS [CASE]
			   ,custid
			   ,username
			   ,transid
			   ,stake
			   ,winlost
			   ,actual_stake
			   ,playercomm
			   ,playerdiscount
			   ,awinlost
			   ,apositiontaking
			   ,comm
			   ,discount
			   ,winlostdate
			   ,bettype
			   ,status
			   ,CASE
					WHEN winlost > actual_stake AND status <> 'WON' THEN 'Issue: Status should be WON'
					WHEN winlost = actual_stake AND status NOT IN ('DRAW', 'REFUND', 'VOID') THEN 'Issue: Status should be DRAW/REFUND/VOID'
					WHEN winlost < actual_stake AND status <> 'LOSE' THEN 'Issue: Status should be LOSE'
					WHEN -(winlost - actual_stake) * apositiontaking <> awinlost THEN 'Issue: awinlost is calculated wrongly'
					WHEN status NOT IN ('REFUND', 'VOID', 'DRAW') AND stake * playerdiscount <> playercomm THEN 'Issue: playercomm is wrong'
				END AS 'Comment'
		FROM	dbo.bettrans b WITH (NOLOCK)
			INNER JOIN (
				SELECT	translogid, tmpmatchId
				FROM	#tmpData  
			
			)tl
				ON	b.refno = tl.translogid
		WHERE	b.matchid = tl.tmpmatchId
				AND winlostdate BETWEEN @FromDate AND @ToDate
				AND statusID NOT IN (0, 1, 101)
				AND (
					(winlost > actual_stake
					AND status <> 'WON')--Case : Check data in Bettrans: if winlost - actual_stake > 0 -> status=WON
					OR
					(winlost = actual_stake
					AND status NOT IN ('DRAW', 'REFUND', 'VOID'))--Case : Check data in Bettrans: if winlost - actual_stake = 0 -> status=DRAW
					OR
					(winlost < actual_stake
					AND status <> 'LOSE')--Case : Check data in Bettrans: if winlost - actual_stake < 0 -> status=LOSE
					OR
					(-(winlost - actual_stake) * apositiontaking <> awinlost) --Case 5: Check data in Bettrans: awinlost,playercomm are calculated correctly
					OR
					(status NOT IN ('REFUND', 'VOID', 'DRAW') AND stake * playerdiscount <> playercomm) --Case 5b: check player wrong playercomm
				)

		IF @@ROWCOUNT > 0
		BEGIN
			SET @ErrMessage = @ErrMessage + 'Inconsistent - ProductId: ' + CAST(@ProductId AS VARCHAR) + ' - Case 2,3,4,5: Check status/awinlost/playercomm of tickets in bettrans.'
		
			RETURN
		END
	END

	--Case 6,7: positiontaking 
	IF @ProductId = 203
	BEGIN
		SELECT TOP 1
				'Case 7' AS [CASE]
			   ,t.custid
			   ,t.translogid
			   ,t.gameID
			   ,t.playerdiscount
			   ,t.discount
			   ,t.adiscount
			   ,t.sdiscount
			   ,t.apositiontaking
			   ,t.mpositiontaking
			   ,t.spositiontaking
			   ,t.transdate
		FROM (SELECT custid
					,gameid
					,MAX(translogid) AS translogid
			FROM	translog WITH (NOLOCK)
			WHERE	productID = @ProductId
			GROUP BY custid, gameID
		) tm
		INNER JOIN translog t WITH (NOLOCK)
			ON	t.translogid = tm.translogid
		INNER JOIN Dep_CustSettingGame st WITH (NOLOCK)
			ON	tm.custid = st.CustID
				AND CASE
						WHEN t.gameID IN (2001, 2002, 2003, 2004) THEN 2001
						WHEN t.gameID IN (2005, 2006, 2007) THEN 2005
					END = st.Bettype
				AND st.sporttype = @ProductId
		WHERE	productID = @ProductId
				AND (
					t.apositiontaking + t.mpositiontaking + t.spositiontaking <> t.tpositiontaking --Case 7: detect apositiontaking + mpositiontaking + spositiontaking <>tpositiontaking
				)

		
		IF @@ROWCOUNT > 0
		BEGIN
			SET @ErrMessage = @ErrMessage + 'Inconsistent - ProductId: ' + CAST(@ProductId AS VARCHAR) + ' - Case 7: Check PT and discount value of tickets in tranlog.'
		
			RETURN
		END

	END
	
	--case 8: count ticket between bettrans and translog
	IF @ProductId <> 207
	BEGIN
		SELECT	TOP 1
				'Case 8' AS [CASE]
				,tt1.gameID AS TranslogGameID
				,tt1.count AS TranslogCount
				,tt2.bettype AS BettransBettype
				,tt2.count AS BetTransCount
		FROM (SELECT COUNT(1) AS count
					,isnull(gameid, 0) AS gameid
					,isnull(winlostdate, '2016-01-01') AS winlostdate
			FROM	translog WITH (NOLOCK)
			WHERE	productID = @ProductId
					AND winlostdate BETWEEN @FromDate AND @ToDate
					AND statusid NOT IN (0, 1)
			GROUP BY gameid, winlostdate
		) tt1
		FULL OUTER JOIN (SELECT COUNT(1) AS count
								,isnull(bettype, 0) AS bettype
								,isnull(winlostdate, '2016-01-01') AS winlostdate
						FROM	dbo.bettrans WITH (NOLOCK)
						WHERE	matchid = @ProductId
								AND winlostdate BETWEEN @FromDate AND @ToDate
						GROUP BY bettype, winlostdate
				) tt2
			ON	tt1.gameid = tt2.bettype
				AND tt1.winlostdate = tt2.winlostdate
		WHERE	isnull(tt1.count, 0) <> isnull(tt2.count, 0)
	
		IF @@ROWCOUNT > 0
		BEGIN
			SET @ErrMessage = @ErrMessage + 'Inconsistent - ProductId: ' + CAST(@ProductId AS VARCHAR) + ' - Case 8: Check betcount between translog and bettrans.'
		
			RETURN
		END
	END

	IF @ProductId = 207
	BEGIN
		--case 8: count ticket between bettrans and translog
		BEGIN
			SELECT TOP 1
				'Case 8' AS [CASE]
				,tl.gameID AS TransLogGameId
				,tl.count AS TransLogCount
				,bt.bettype AS BettransBettype
				,bt.count AS BettransCount
			FROM (
				SELECT	COUNT(1) AS count
						,bettype
						,winlostdate
				FROM	dbo.Match3rd m WITH(NOLOCK)
					INNER JOIN dbo.bettrans b WITH(NOLOCK)
						ON m.Match3rdId = b.matchid
				WHERE	m.SportType = @ProductId
						AND b.winlostdate BETWEEN @FromDate AND @ToDate
						AND b.statusID NOT IN (0,1)
				GROUP BY bettype, winlostdate
			) bt
			FULL OUTER JOIN (
				SELECT	COUNT(1) AS count
						,gameID 
						,winlostdate
				FROM	dbo.translog tl WITH(NOLOCK)
				WHERE	tl.productID = @ProductId
						AND tl.statusID NOT IN (0,1)
						AND tl.winlostdate BETWEEN @FromDate AND @ToDate
				GROUP BY tl.gameID, tl.winlostdate
			) tl
				ON	bt.bettype = tl.gameID
					AND bt.winlostdate = tl.winlostdate
			WHERE	ISNULL(bt.count,0) <> ISNULL(tl.count,0)

			IF @@ROWCOUNT > 0
			BEGIN
				SET @ErrMessage = @ErrMessage + 'Inconsistent - ProductId: ' + CAST(@ProductId AS VARCHAR) + ' - Case 8: Check betcount between translog and bettrans.'
		
				RETURN
			END
		END

		-- Discount value
		BEGIN
			SELECT	TOP 1 
					'Checking discount in translog' AS [CASE]
					,CASE
						WHEN tl.sdiscount < tl.adiscount THEN 'Issue: sdiscount must be larger than adiscount'
						WHEN tl.adiscount < tl.discount THEN 'Issue: sdiscount must be larger than adiscount'
						WHEN tl.discount < tl.playerdiscount THEN 'Issue: sdiscount must be larger than adiscount'
						WHEN (tl.tpositiontaking = 0 OR tl.spositiontaking = 0 OR tl.mpositiontaking = 0 OR tl.apositiontaking = 0) THEN 'Issue: positiontaking must be larger than 0'
					END AS 'Comment'
					,sdiscount
					,adiscount
					,discount
					,playerdiscount
					,spositiontaking
					,mpositiontaking
					,apositiontaking
			FROM	#tmpData tl
			WHERE	(tl.sdiscount < tl.adiscount
						OR tl.adiscount < tl.discount 
						OR tl.discount < tl.playerdiscount
						OR ((tl.tpositiontaking = 0 OR tl.spositiontaking = 0 OR tl.mpositiontaking = 0 OR tl.apositiontaking = 0) AND currency <> 20)

					)

			IF @@ROWCOUNT <> 0
			BEGIN
				SET @ErrMessage = @ErrMessage + 'Inconsistent - ProductId: ' + CAST(@ProductId AS VARCHAR) + ' - Checking discount/positiontaking in translog'
			
				RETURN
			END
		END

		-- EventDate (match3rd) = winlostdate (translog)
		BEGIN
			DECLARE @yesterday DATE = DATEADD(DAY,-1,CAST(GETDATE() AS DATE))
			DECLARE @tmpMatchId TABLE (MatchId INT, EventDate DATE, EventStatus VARCHAR(50), MatchNo VARCHAR(30))
		
			INSERT INTO @tmpMatchId (MatchId, EventDate, EventStatus, MatchNo)
			SELECT m.Match3rdId
					,m.EventDate
					,m.EventStatus
					,m.MatchNo
			FROM	dbo.Match3rd m WITH (NOLOCK)
			WHERE	m.EventDate BETWEEN @FromDate AND @ToDate
		
			SELECT	TOP 1
					'Checking data between match3rd and translog ' AS [CASE]
					,CASE
						WHEN t.winlostdate <> m.EventDate THEN 'Issue: translog.winlostdate must be equal match3rd.eventdate'
						WHEN (t.statusID IN (0,1) AND m.EventStatus = 'Completed') THEN 'Issue: when match completed, all related tickets must be settled'
						WHEN (m.EventDate <= @yesterday AND t.statusID IN (0,1)) THEN 'Issue: all yesterday matches must be settled'
						WHEN (m.EventStatus = 'Completed' AND m.MatchNo = 0 AND t.statusID <> 103) THEN 'Issue: match has been refunded but still have ticket not refund'
					END AS 'Comment'
				   ,t.translogid
				   ,t.eventID
				   ,t.winlostdate
				   ,m.EventDate
			FROM	#tmpData t WITH (NOLOCK)
				INNER JOIN @tmpMatchId m
					ON	t.eventID = m.MatchId
			WHERE	t.productID = @ProductId
					AND winlostdate BETWEEN @FromDate AND @ToDate
					AND (
						t.winlostdate <> m.EventDate
							OR (t.statusID IN (0,1) AND m.EventStatus = 'Completed')
							OR (m.EventDate <= @yesterday AND t.statusID IN (0,1))
							OR (m.EventStatus = 'Completed' AND m.MatchNo = 0 AND t.statusID <> 103)
						)

			IF @@ROWCOUNT <> 0
			BEGIN
				SET @ErrMessage = @ErrMessage + 'Inconsistent - ProductId: ' + CAST(@ProductId AS VARCHAR) + ' - Checking data between match3rd and translog'
			
				RETURN
			END
		END
	END
END
GO