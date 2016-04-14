USE [bk]
GO
/****** Object:  StoredProcedure [dbo].[Task_Bets_TransReject]    Script Date: 04/13/2016 22:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.GetBetTransReject    Script Date: 1/30/2013 11:24:41 AM ******/
ALTER   PROCEDURE [dbo].[Task_Bets_TransReject]
	@transid bigint
AS
-- 20120904@Viet: add new sportsbook and number game bettype
-- 20130121@Johnson: move sp from DB052.BODB02 to DBBET/BK

insert into dbo.betsreject 
SELECT transid,   hdp1, hdp2, odds,  stake, status, 
livehomescore,  liveawayscore, liveindicator, betteam,
tpositiontaking,matchid,oddsid, ruben,  bettype, currency,custid,winlostdate

From bodb02.dbo.BetTrans with  (nolock)
Where  
	transid >@transid --and bettype<41 
	and (bettype < 50 OR bettype between 81 and 999 OR bettype between 1201 and 1299)
	and status in (N'reject',N'void')
	--and NOT (bettype IN (31,32,33) AND status = N'void')

GO
GRANT VIEW DEFINITION ON [dbo].[Task_Bets_TransReject] TO [vnteam] AS [dbo]