USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Task_FollowBet_Step2_PlaceBet]    Script Date: 01/27/2015 03:52:41 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.Task_FollowBet_Step2_PlaceBet    Script Date: 10/10/2014 12:33:42 PM ******/
/****** Object:  Stored Procedure dbo.Task_FollowBet_Step2_PlaceBet    Script Date: 30/09/2014 1:37:44 PM ******/
CREATE PROCEDURE [dbo].[Task_FollowBet_Step2_PlaceBet]
	@follow_transid BIGINT
AS
/*
	Create:  
	Task:  
	DB: DBTRANS.BODB02

	Revisions:
		- 20120529@Sophia: . Update credit/debit balance
						   . Check @@Error to rollback
		- 20131108@Elodie: Splitting bodb02 into CustDB (call CustInfo, Exchange by link database)	
		- 20130107@Kathy: Get follower from Cust_FollowBet instead of hardcoded		
		- 20140919@Kathy: Allow to follow running ticket only [Redmine:#22392]	
		- 20141001@Lukas: remove param @betfrom on sp: DB02.bodb02.dbo.Dot_Member_Prod_Autobookie	   
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @matchid	INT
		,@oddsid		INT
		,@bettype		SMALLINT
		,@betteam		NVARCHAR(1)
		,@liveindicator BIT
		,@stake			MONEY
		,@odds			SMALLMONEY			
		,@custid		INT
		,@transid		BIGINT
		,@rc			INT
		,@custBet		INT
		,@LogData		NVARCHAR(300)
		,@Err			INT
	
	SELECT @matchid		= t.matchid
		,@oddsid		= t.oddsid
		,@bettype		= t.bettype
		,@betteam		= t.betteam
		,@liveindicator = t.liveindicator
		,@stake			= t.follow_stake
		,@odds			= t.odds		
		,@custBet		= t.custid
	FROM dbo.Task_FollowBet_Details t WITH(NOLOCK)
		INNER JOIN dbo.bettrans b WITH(NOLOCK) ON b.transid = t.transid
	WHERE t.transid = @follow_transid

		
	SELECT @custid = (
		SELECT TOP (1) Follower
		FROM CustDB.dbo.Cust_FollowBet WITH(NOLOCK)
		WHERE custid = @custBet
		)

	SELECT @custid = ISNULL(@custid, 6153451)

	--=====================================
	DECLARE @currency			TINYINT
		,@recommend				INT
		,@mrecommend			INT
		,@srecommend			INT
		,@CurrencyName			NVARCHAR(10)
		,@Username				NVARCHAR(50)
		,@VirtualMultiplier		SMALLMONEY
		,@virtualrate			FLOAT
		,@betactualrate			FLOAT
		,@autosuspend			BIT

	SELECT @Username		= username
		,@recommend			= ISNULL(recommend, 0)
		,@mrecommend		= ISNULL(mrecommend, 0)
		,@srecommend		= ISNULL(srecommend, 0)
		,@currency			= currency
		,@VirtualMultiplier = ISNULL(VirtualMultiplier, 1)
		,@autosuspend		= ISNULL(autosuspend, 0)
	FROM CustDB.dbo.custinfo WITH(NOLOCK)
	WHERE custid = @custid 
		AND roleid = 1

	SELECT @betactualrate	= actualrate
		,@virtualrate		= @VirtualMultiplier * actualrate
		,@CurrencyName		= currency
	FROM CustDB.dbo.exchange WITH(NOLOCK)
	WHERE exchangeid = @currency

	--=====================================
	--=====================================
	DECLARE @betstake		MONEY
		,@betactual_stake	MONEY
		,@stake_to_company	MONEY

	SET @betstake = @stake
	SET @betactual_stake = CASE WHEN @odds > 0 THEN @stake ELSE ABS(@odds) * @stake END
	SET @stake_to_company = @stake * @betactualrate -- NO PT for uplines, then all stake go to HOUSE

	--Update pending debit balance	 
	INSERT INTO BalancePendingDebit (custid, Balance)
	VALUES (@custid, @betactual_stake)

	INSERT INTO dbo.bettrans (
		custid
		,oddsid
		,oddsspread
		,hdp1
		,hdp2
		,odds
		,stake
		,actual_stake
		,[status]
		,statusID
		,livehomescore
		,liveawayscore
		,liveindicator
		,betfrom
		,betteam
		,creator
		,refno
		,tpositiontaking
		,apositiontaking
		,mpositiontaking
		,spositiontaking
		,playerdiscount
		,discount
		,adiscount
		,sdiscount
		,actualrate
		,virtualrate
		,matchid
		,recommend
		,mrecommend
		,srecommend
		,scomm
		,swinlost
		,bettype
		,currency
		,winlostdate
		,transdesc
		,ip
		,Username
		,CurrencyName
		,betid
		)
	SELECT @custid
		,@oddsid
		,0
		,hdp1
		,hdp2
		,@odds
		,@betstake
		,@betactual_stake
		,b.STATUS
		,b.statusID
		,livehomescore
		,liveawayscore
		,@liveindicator
		,'i'
		,@betteam
		,@custid
		,100000000000		
		,0 -- tpos
		,0 -- apos
		,0 -- mpos
		,0 -- spos
		,0 -- playerdiscount
		,0 -- adiscount
		,0 -- mdiscount
		,0 -- sdiscount
		,@betactualrate
		,@virtualrate
		,@matchid
		,@recommend
		,@mrecommend
		,@srecommend
		,0
		,0
		,@bettype
		,@currency
		,winlostdate
		,'Follow from ' + username + ' transid:' + CAST(@follow_transid AS VARCHAR(30)) + ' delay ' + CAST(DATEDIFF(millisecond, transdate, CURRENT_TIMESTAMP) AS VARCHAR(20)) + ' ms'
		,''
		,@Username
		,@CurrencyName
		,@follow_transid
	FROM dbo.bettrans b WITH(NOLOCK)
	WHERE transid = @follow_transid 
		AND statusID = 0

	SELECT @Err = @@ERROR
		,@rc = @@ROWCOUNT
		,@transid = scope_identity()

	IF @Err <> 0
	BEGIN
		--Rollback Balance   
		INSERT INTO BalancePendingCredit (custid, Balance)
		VALUES (@custid,@betactual_stake)

		RETURN
	END

	IF @rc > 0
	BEGIN
		--=====================================
		UPDATE odds WITH(ROWLOCK, UPDLOCK)
		SET hometotal = hometotal + (CASE WHEN @betteam = 'h' THEN (@stake * @betactualrate) ELSE 0 END)
			,awaytotal = awaytotal + (CASE WHEN @betteam = 'a' THEN (@stake * @betactualrate) ELSE 0 END)
		WHERE oddsid = @oddsid

		EXEC DB02.bodb02.dbo.Dot_Member_Prod_Autobookie @custid = @custid
			,@oddsid = @oddsid
			,@matchid = @matchid
			,@odds = @odds
			,@bettype = @bettype
			,@betteam = @betteam
			--,@betfrom = 'i'
			,@stake_to_company = @stake_to_company
			,@currency = @currency
			,@autosuspend = @autosuspend
			,@liveindicator = @liveindicator

		--=====================================
		SET @LogData = N'Follow betting custid:' + CAST(ISNULL(@custid, 'x') AS NVARCHAR(10)) + N' insert bet oddsid:' + CAST(ISNULL(@oddsid, 'x') AS NVARCHAR(10)) + N' at ' + CONVERT(NVARCHAR(10), CAST(ISNULL(@odds, 0) AS FLOAT)) + ' bet ' + CAST(ISNULL(@betteam, 'x') AS NVARCHAR(10)) + N' stake:' + CONVERT(NVARCHAR(50), ISNULL(@stake, 0)) + N' transid:' + CAST(ISNULL(@transid, 'x') AS NVARCHAR(20)) + N' ip:--system--' + N' from:' + CAST(@follow_transid AS NVARCHAR(30))

		EXEC dbo.logfile @custid, @logdata
	END -- if @rc > 0

	DELETE FROM dbo.Task_FollowBet_Details WITH(UPDLOCK, ROWLOCK)
	WHERE transid = @follow_transid		
	
	WAITFOR DELAY '000:00:01' -- WAIT 1 second, then back to the 1st step (list ticket)
END
GO


