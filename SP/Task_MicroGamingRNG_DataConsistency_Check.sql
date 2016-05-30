USE [bodb02]
GO
ALTER procedure [dbo].[Task_MicroGamingRNG_DataConsistency_Check]
	@FDate smalldatetime, 
	@TDate smalldatetime,
	@ErrMessage varchar(512) = '' output
as
/*
	Created: Francis
	CreatedDate: 20160316
	Task: Check data between bettrans & bettransRNG for MGC RNG (Run on DB06/DBTP)
	Revision:
		- 20160517@Patrick: VoidBridge Integration [Redmine: #57675]
*/
begin
	declare @FromDate smalldatetime, @ToDate smalldatetime

	select @FromDate = @FDate
	select @ToDate = @TDate
	set @ErrMessage = ''

	declare @tempdata table (custid int, username varchar(50), transid bigint
		, stake money, actual_stake money, playerdiscount decimal (9,8), ProductID int
		, apositiontaking money, discount decimal(9,8), gameid smallint
		, winlostdate smalldatetime, status varchar(10)
		, winlost money, awinlost money, mwinlost money, swinlost money
		, scomm money, acomm money, comm money, playercomm money, issum bit, StatusID tinyint)
		
	declare @sourcedata table (custid int, username varchar(50), matchid int
		, bettype smallint, winlostdate smalldatetime, status varchar(10)
		, turnover money, winlost money, awinlost money, mwinlost money, swinlost money
		, scomm money, acomm money, comm money, playercomm money)

	declare @targetdata table (custid int, username varchar(50), matchid int
		, bettype smallint, winlostdate smalldatetime, status varchar(10)
		, turnover money, winlost money, awinlost money, mwinlost money, swinlost money
		, scomm money, acomm money, comm money, playercomm money)
	/*
	--Temp table is used to check wrong setting when placing bet
	declare @wrongdataPT table (custid int, transid bigint
		, bettype smallint, playerdiscount decimal(9,8), discount decimal(9,8), adiscount decimal(9,8), sdiscount decimal(9,8),
		apositiontaking money, mpositiontaking money, spositiontaking money, transdate datetime)
		

	declare @wrongdata table (custid int, username varchar(50), transid bigint
		, stake money, winlost money, actual_stake money, playercomm money, playerdiscount decimal(9,8),
		awinlost money, apositiontaking money, comm money, discount decimal(9,8), winlostdate smalldatetime, gameid smallint, status varchar(10)
		,issue varchar(200))
	*/
	insert into @tempdata (custid, username, transid
		, stake, actual_stake, playerdiscount, ProductID
		, apositiontaking, discount, gameid
		, winlostdate, status
		, winlost, awinlost, mwinlost, swinlost
		, scomm, acomm, comm, playercomm, issum)
	select custid, username, transid
		, stake, actual_stake, playerdiscount, gameID
		, apositiontaking, discount, gameid
		, winlostdate, status
		, winlost, awinlost, mwinlost, swinlost
		, scomm, acomm, comm, playercomm, IsSum
	from dbo.bettransRnG with (nolock)
	where 1=1
		and productID in (205)
		and winlostdate BETWEEN @FromDate AND @ToDate

	--Case 1: Check sum all detail tickets in BettransRNG & sum ticket in Bettrans
	insert into @sourcedata(custid, username, matchid, bettype, winlostdate, status
		, turnover, winlost, awinlost, swinlost, mwinlost, scomm, acomm, comm, playercomm)
	select custid, username, productid, gameID, winlostdate
		, case when sum(winlost-actual_stake) > 0 then 'WON'
			when sum(winlost-actual_stake) < 0 then 'LOSE'
			else 'DRAW' end as status
		, sum(stake) as stake, sum(winlost-actual_stake) as winlost, sum(awinlost) as awinlost, sum(swinlost) as swinlost, sum(mwinlost) as mwinlost
		, sum(scomm) as scomm, sum(acomm) as acomm, sum(comm) as comm, sum(playercomm) as playercomm
	from @tempdata 
	where --custid in (select custid from @CustIds) and
		productID in (205)--MGC RNG
		and winlostdate BETWEEN @FromDate AND @ToDate
		and issum = 1
	group by custid, username, productid, gameid, winlostdate

	insert into @targetdata(custid, username, matchid, bettype, winlostdate, status
		, turnover, winlost, awinlost, swinlost, mwinlost, scomm, acomm, comm, playercomm)
	select custid, username, matchid, bettype, winlostdate, status
		, sum(stake) as stake, sum(winlost-actual_stake) as winlost
		, sum(awinlost) as awinlost, sum(swinlost) as swinlost, sum(mwinlost) as mwinlost
		, sum(scomm) as scomm, sum(acomm) as acomm, sum(comm) as comm, sum(playercomm) as playercomm
	from dbo.bettrans with(nolock)
	where --custid in (select custid from @CustIds) and
		matchid in (205)--MGC RNG
		and winlostdate BETWEEN @FromDate AND @ToDate
		and statusid not in (0,1,131)
	group by custid, username, matchid, bettype, winlostdate, status

	select top 1 'Case 1' AS [CASE], s.*, t.*
	from @sourcedata s
		inner join @targetdata t on s.custid = t.custid and s.bettype = t.bettype and s.winlostdate = t.winlostdate
	where s.turnover <> t.turnover 
		or s.winlost <> t.winlost 
		or s.swinlost <> t.swinlost 
		or s.mwinlost <> t.mwinlost 
		or s.awinlost <> t.awinlost
		or s.scomm <> t.scomm 
		or s.acomm <> t.acomm 
		or s.comm <> t.comm 
		or s.playercomm <> t.playercomm
		or s.status <> t.status
		
	IF @@ROWCOUNT > 0
	BEGIN
		SET @ErrMessage = @ErrMessage + 'Inconsistent - RnG Game - ProductId: 205 - Case 1: Check ticket details between bettrans and bettransRNG.'
		RETURN
		--RAISERROR('Microgaming RNG - Case 1: Check ticket details between bettrans and bettransRNG --INCONSISTENT--', 16, 1);	
	END
	--------------------------

	--Case 2,3,4,5
	--insert into @wrongdata (custid , username , transid 
	--	, stake , winlost , actual_stake , playercomm , playerdiscount , awinlost , apositiontaking , comm ,
	--	discount , winlostdate ,gameid, status , issue )
	select top 1 'Case 2,3,4,5' AS [CASE]
	,custid,username,transid,stake,winlost,actual_stake,playercomm,playerdiscount,awinlost,apositiontaking,comm,discount,winlostdate,gameid,status,
			case when winlost>actual_stake then 'Issue: Status should be WON'
				 when winlost=actual_stake then 'Issue: Status should be DRAW/REFUND'
				 when winlost<actual_stake then 'Issue: Status should be LOSE'
				 when -(winlost-actual_stake)*apositiontaking<>awinlost then 'Issue: awinlost is calculated wrongly' 
				 when stake*playerdiscount<>playercomm then 'Issue: playercomm is wrong' 
			end as 'Comment'
	from @tempdata
	where 1=1
		AND StatusID NOT IN (0,1)
		AND (
				(winlost>actual_stake AND status<>'WON')--Case 2: Check data in BettransRNG - if winlost - actual_stake > 0 -> status=WON
				OR
				(winlost=actual_stake AND status not in ('DRAW', 'REFUND'))--Case 3: Check data in BettransRNG - if winlost - actual_stake = 0 -> status=DRAW
				OR
				(winlost<actual_stake AND status<>'LOSE')--Case 4: Check data in BettransRNG - if winlost - actual_stake < 0 -> status=LOSE			
				OR
				(-(winlost-actual_stake)*apositiontaking<>awinlost) --Case 5: Check data in BettransRNG - awinlost,playercomm are calculated correctly
				OR
				(stake*playerdiscount<>playercomm) --Case 5b: playercomm is wrong
			)
	IF @@ROWCOUNT > 0
	BEGIN
		SET @ErrMessage = @ErrMessage + 'Inconsistent - RnG Game - ProductId: 205 - Case 2,3,4,5: Check status/awinlost/playercomm of tickets in bettransRNG.'
		RETURN
		--RAISERROR('Microgaming RNG - Case 2,3,4,5: Check status/awinlost/playercomm of tickets in bettransRNG --INCONSISTENT--', 16, 1);	
	END
	
	/*
	--Case 5 
	insert into @wrongdata (custid , username , transid 
		, stake , winlost , actual_stake , playercomm , playerdiscount , awinlost , apositiontaking , comm ,
		discount , winlostdate ,gameid, status , issue )
	select top 100 custid,username,transid,stake,winlost,actual_stake,playercomm,playerdiscount,awinlost,apositiontaking,comm,discount,winlostdate,gameid,status,
			case when -(winlost-actual_stake)*apositiontaking<>awinlost then 'Issue: awinlost is calculated wrongly' 
				 when stake*playerdiscount<>playercomm then 'Issue: playercomm is wrong'
				 
			end as 'Comment'
	from dbo.bettransRnG with(nolock)
	where --custid in (select custid from @CustIds) AND
		productID in (205)--MGC RNG
		AND winlostdate BETWEEN @FromDate AND @ToDate
		AND statusID NOT IN (0,1)
		AND (	(-(winlost-actual_stake)*apositiontaking<>awinlost) --Case 5: Check data in BettransRNG - awinlost,playercomm are calculated correctly
				OR
				(stake*playerdiscount<>playercomm) --Case 5b: playercomm is wrong		
			)

	select * from @wrongdata
	*/
	--------------------------
	--Case 6,7: 
	--insert into @wrongdataPT (custid, transid, bettype, playerdiscount, discount, 
	--	adiscount, sdiscount, apositiontaking, mpositiontaking, spositiontaking, transdate)
	select top 1 'Case 6,7' AS [CASE], t.custid, t.transid, t.gameID, t.playerdiscount, t.discount,  
			t.adiscount, t.sdiscount, t.apositiontaking, t.mpositiontaking, t.spositiontaking, t.transdate
	from bettransRnG t with (nolock)
	inner join (
		SELECT custid, gameid, max(transid) as transid  
		FROM bettransRnG with (nolock) 
		Where productID=205
		GROUP BY custid, gameID
	) tm on t.custid = tm.custid and t.transid = tm.transid
	inner join Dep_CustSettingGame st with (nolock) on tm.custid=st.CustID 
		and t.gameID=
				case when st.Bettype=2001 then 2009
					 when st.Bettype=2005 then 2008
				end
		and st.sporttype = 203
	where productID=205
	and (t.playerdiscount<>st.playerdiscount
		OR t.discount<>st.discount
		OR t.adiscount<>st.adiscount 
		OR t.sdiscount<>st.sdiscount
		OR t.apositiontaking<>st.apositiontaking --Case 6: detect apositiontaking is wrong when placing bet
		OR t.mpositiontaking<>st.mpositiontaking --Case 6: detect mpositiontaking is wrong when placing bet
		OR t.spositiontaking<>st.spositiontaking --Case 6: detect spositiontaking is wrong when placing bet
		OR t.apositiontaking+t.mpositiontaking+t.spositiontaking<>t.tpositiontaking --Case 7: detect apositiontaking + mpositiontaking + spositiontaking <>tpositiontaking
		)
	IF @@ROWCOUNT > 0
	BEGIN
		SET @ErrMessage = @ErrMessage + 'Inconsistent - RnG Game - ProductId: 205 - Case 6,7: Check PT and discount value of tickets in bettransRNG.'
		RETURN
		--RAISERROR('Microgaming RNG - Case 6,7: Check PT and discount value of tickets in bettransRNG --INCONSISTENT--', 16, 1);
	END
	--select * from @wrongdataPT
end
grant view definition on Task_MicroGamingRNG_DataConsistency_Check to vnteam

GO
GRANT EXECUTE ON [dbo].[Task_MicroGamingRNG_DataConsistency_Check] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Task_MicroGamingRNG_DataConsistency_Check] TO [vnteam] AS [dbo]