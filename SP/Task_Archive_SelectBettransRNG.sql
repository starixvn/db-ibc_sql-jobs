USE [bodb02]
GO 
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO 
CREATE PROCEDURE [dbo].[Task_Archive_SelectBettransRNG]
AS
/*
	Created by: Sophia
	Date: 20151013
	Task: Insert data from bettransRNG14 to bettransRNG_BK at bodb_Archive
	DB:  DBTXN.bodb02
	Revisions:
     
    
*/
BEGIN 
	SET NOCOUNT ON

	DECLARE  @max_winlostdate SMALLDATETIME

	SELECT	 @max_winlostdate = MAX(winlostdate)
	FROM	dbo.Task_ArchiveDate

	-- to DB06.bodb_Archive.dbo.bettransRNG_BK
	SELECT 
		transid, custid, transdate, odds, stake, status, apositiontaking, mpositiontaking, tpositiontaking, spositiontaking, 
		playerdiscount, discount, adiscount, sdiscount, creator, winlostdate, betfrom, virtualrate, actualrate, actual_stake, 
		currency, CurrencyName, recommend, mrecommend, srecommend, ip, statusID, balance, Username, transdesc, productID, gameID, 
		vendorID, GameId3rd, TranId3rd, RefNo, IsSum, winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, Transdate3rd
	FROM dbo.BettransRNG14 WITH (NOLOCK)
	WHERE winlostdate <= @max_winlostdate
END
GO
 
GRANT VIEW DEFINITION ON [dbo].[Task_Archive_SelectBettransRNG] TO [vnteam] AS [dbo]
GO