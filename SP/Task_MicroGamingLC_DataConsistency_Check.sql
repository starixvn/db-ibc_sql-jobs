USE [bodb02]
GO
alter procedure [dbo].[Task_MicroGamingLC_DataConsistency_Check]
	@FDate smalldatetime, 
	@TDate smalldatetime,
	@ErrMessage varchar(512) = '' output
as
/*
	Created: Francis
	CreatedDate: 20160316
	Task: Check data between bettrans & translog for MGC LC (Run on DB06/DBTP)
	DB: DBTP.bodb02
		
	Revision:
		- 20160517@Patrick: VoidBridge Integration [Redmine: #57675]
		- 20160609@Helen: Remove case 6 from service to check ticket correctness - [Redmine: 58904]
*/
begin
	declare @FromDate smalldatetime, @ToDate smalldatetime

	select @FromDate = @FDate
	select @ToDate = @TDate
	
	set @ErrMessage = ''

--Temp table is used to check wrong setting when placing bet
/*
declare @wrongdataPT table (custid int, transid bigint
	, bettype smallint, playerdiscount decimal(9,8), discount decimal(9,8), adiscount decimal(9,8), sdiscount decimal(9,8),
	apositiontaking money, mpositiontaking money, spositiontaking money, transdate datetime)


declare @wrongdata table (custid int, username varchar(50), transid bigint
	, stake money, winlost money, actual_stake money, playercomm money, playerdiscount decimal(9,8),
	awinlost money, apositiontaking money, comm money, discount decimal(9,8), winlostdate smalldatetime, bettype smallint, status varchar(10)
	,issue varchar(200) )
*/
	
--Case 1: check data between translog & bettrans
	SELECT TOP 1 'Case 1' as [CASE], * FROM bettrans bt with (nolock)
		INNER JOIN Translog tl with (nolock) on bt.refno=tl.translogid
	WHERE bt.winlostdate BETWEEN @FromDate AND @ToDate
		AND matchid IN (203)--MGC LC
		AND bettype IN (2001,2002,2003,2004,2005,2006,2007)
		AND bt.statusID NOT IN (0,1)
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
				OR bt.matchid <> tl.productID
				OR bt.bettype <> tl.gameID
				OR bt.statusID <> tl.statusID
			)
	IF @@ROWCOUNT > 0
	BEGIN
		SET @ErrMessage = @ErrMessage + 'Inconsistent - LC Game - ProductId: 203 - Case 1: Check ticket details between translog and bettrans.'
		RETURN
		--RAISERROR('MicroGaming LC - Case 1: Check ticket details between translog and bettrans --INCONSISTENT--', 16, 1);
	END
	
	--Case 2,3,4,5
	--insert into @wrongdata (custid , username , transid 
	--	, stake , winlost , actual_stake , playercomm , playerdiscount , awinlost , apositiontaking , comm ,
	--	discount , winlostdate , bettype, status , issue )
	select top 1 'Case 2,3,4,5' as [CASE], custid,username,transid,stake,winlost,actual_stake,playercomm,playerdiscount,awinlost,apositiontaking,comm,discount,winlostdate,bettype,status,
			case when winlost>actual_stake then 'Issue: Status should be WON'
				 when winlost=actual_stake then 'Issue: Status should be DRAW/REFUND'
				 when winlost<actual_stake then 'Issue: Status should be LOSE'
				 when -(winlost-actual_stake)*apositiontaking<>awinlost then 'Issue: awinlost is calculated wrongly' 
				 when stake*playerdiscount<>playercomm then 'Issue: playercomm is wrong'
			end as 'Comment'
	from dbo.bettrans with(nolock)
	where
		matchid in (203)--MGC LC
		AND bettype IN (2001,2002,2003,2004,2005,2006,2007)
		AND winlostdate BETWEEN @FromDate AND @ToDate
		AND statusID NOT IN (0,1)
		AND (
				(winlost>actual_stake AND status<>'WON')--Case : Check data in Bettrans: if winlost - actual_stake > 0 -> status=WON
				OR
				(winlost=actual_stake AND status not in ('DRAW','REFUND'))--Case : Check data in Bettrans: if winlost - actual_stake = 0 -> status=DRAW
				OR
				(winlost<actual_stake AND status<>'LOSE')--Case : Check data in Bettrans: if winlost - actual_stake < 0 -> status=LOSE
				OR
				(-(winlost-actual_stake)*apositiontaking<>awinlost) --Case 5: Check data in Bettrans: awinlost,playercomm are calculated correctly
				OR
				(stake*playerdiscount<>playercomm) --Case 5b: check player wrong playercomm
			)
	IF @@ROWCOUNT > 0
	BEGIN
		SET @ErrMessage = @ErrMessage + 'Inconsistent - LC Game - ProductId: 203 - Case 2,3,4,5: Check status/awinlost/playercomm of tickets in bettrans.'
		RETURN
		--RAISERROR('MicroGaming LC - Case 2,3,4,5: Check status/awinlost/playercomm of tickets in bettrans --INCONSISTENT--', 16, 1);	
	END
	
	/*
	--Case 5 
	insert into @wrongdata (custid , username , transid 
		, stake , winlost , actual_stake , playercomm , playerdiscount , awinlost , apositiontaking , comm ,
		discount , winlostdate , bettype, status , issue )
	select top 100 custid,username,transid,stake,winlost,actual_stake,playercomm,playerdiscount,awinlost,apositiontaking,comm,discount,winlostdate, bettype, status,
			case when -(winlost-actual_stake)*apositiontaking<>awinlost then 'Issue: awinlost is calculated wrongly' 
				 when stake*playerdiscount<>playercomm then 'Issue: playercomm is wrong'		  
			end as 'Comment'
	from dbo.bettrans with(nolock)
	where 
		matchid in (203)--MGC LC
		AND bettype IN (2001,2002,2003,2004,2005,2006,2007)
		AND winlostdate BETWEEN @FromDate AND @ToDate
		AND statusID NOT IN (0,1)
		AND (
				(-(winlost-actual_stake)*apositiontaking<>awinlost) --Case 5: Check data in Bettrans: awinlost,playercomm are calculated correctly
				OR
				(stake*playerdiscount<>playercomm) --Case 5b: check player wrong playercomm
				
			)

	select * from @wrongdata
	*/
	-------------------------------

	--Case 6,7: 
	--insert into @wrongdataPT (custid, transid, bettype, playerdiscount, discount, 
	--	adiscount, sdiscount, apositiontaking, mpositiontaking, spositiontaking, transdate)
	select top 1 'Case 7' AS [CASE] , t.custid, t.translogid, t.gameID, t.playerdiscount, t.discount,  
			t.adiscount, t.sdiscount, t.apositiontaking, t.mpositiontaking, t.spositiontaking, t.transdate
	from (
		select custid, gameid, max(translogid) as translogid
		from translog with (nolock) 
		where productID=203
		group by custid, gameID
	)tm inner join translog t with (nolock) on t.translogid = tm.translogid
		inner join Dep_CustSettingGame st with (nolock) on tm.custid=st.CustID 
			and case when t.gameID in (2001,2002,2003,2004) then 2001
					 when t.gameID in (2005,2006,2007) then 2005
				end = st.Bettype				
			and st.sporttype=203			
	where productID=203
	and (
		--t.playerdiscount<>st.playerdiscount
		--OR t.discount<>st.discount
		--OR t.adiscount<>st.adiscount 
		--OR t.sdiscount<>st.sdiscount
		
		--OR t.apositiontaking<>st.apositiontaking --Case 6: detect apositiontaking is wrong when placing bet
		--OR t.mpositiontaking<>st.mpositiontaking --Case 6: detect mpositiontaking is wrong when placing bet
		--OR t.spositiontaking<>st.spositiontaking --Case 6: detect spositiontaking is wrong when placing bet
		
		t.apositiontaking+t.mpositiontaking+t.spositiontaking<>t.tpositiontaking --Case 7: detect apositiontaking + mpositiontaking + spositiontaking <>tpositiontaking
		)
	IF @@ROWCOUNT > 0
	BEGIN
		SET @ErrMessage = @ErrMessage + 'Inconsistent - LC Game - ProductId: 203 - Case 6,7: Check PT and discount value of tickets in tranlog.'
		RETURN
		--RAISERROR('MicroGaming LC - Case 6,7: Check PT and discount value of tickets in tranlog --INCONSISTENT--', 16, 1);	
	END
		
	--select * from @wrongdataPT

	------------------
	--case 8
	select top 1 'Case 8' AS [CASE]
	, tt1.gameID AS TranslogGameID, tt1.count AS TranslogCount, tt2.bettype AS BettransBettype, tt2.count AS BetTransCount
	from (
		select count(1) as count
			   --, productid
			   , gameid
		from translog with (nolock)
		where productID= 203
			and gameid between 2001 and 2007
			and winlostdate BETWEEN @FromDate AND @ToDate
			and statusid not in (0,1)
		group by --productid, 
				 gameid
	 ) tt1
	  inner join (
	  select count(1) as count
			--, matchid
			, bettype
	  from bettrans with (nolock)
	  where bettype between 2001 and 2007
		and matchid = 203
		and winlostdate BETWEEN @FromDate AND @ToDate
	  group by --matchid, 
			   bettype) tt2 on tt1.gameid = tt2.bettype
	where tt1.count <> tt2.count
	
	IF @@ROWCOUNT > 0
	BEGIN
		SET @ErrMessage = @ErrMessage + 'Inconsistent - LC Game - ProductId: 203 - Case 8: Check betcount between translog and bettrans.'
		RETURN
		--RAISERROR('MicroGaming LC - Case 8: Check betcount between translog and bettrans --INCONSISTENT--', 16, 1);		
	END

end
grant view definition on Task_MicroGamingLC_DataConsistency_Check to vnteam

GO
GRANT EXECUTE ON [dbo].[Task_MicroGamingLC_DataConsistency_Check] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Task_MicroGamingLC_DataConsistency_Check] TO [vnteam] AS [dbo]