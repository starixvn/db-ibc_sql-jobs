SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE	dbo.Task_Archive_SelectTranslog
AS
/*
	Creator:	20160614@Lukas
	Task:		Get data from translog14 for archiving
	Database:	DBTXN.bodb02

	Revisions:
		- 20160614@Lukas:	Initial - [Redmine: #000000]
*/
BEGIN 
	SET NOCOUNT ON

	DECLARE  @max_winlostdate SMALLDATETIME

	SELECT	 @max_winlostdate = MAX(winlostdate)
	FROM	dbo.Task_ArchiveDate

	-- to DB06.bodb_Archive.dbo.translog_bk
	SELECT translogid, custid, transdate, odds, stake, status, apositiontaking, mpositiontaking, tpositiontaking, spositiontaking, 
		playerdiscount, discount, adiscount, sdiscount, creator, winlostdate, betfrom, virtualrate, actualrate, actual_stake, currency, 
		CurrencyName, recommend, mrecommend, srecommend, ip, statusID, balance, Username, transdesc, productID, gameID, eventID, vendorID, 
		GameId3rd, TranId3rd, custom1, custom2, custom3, LiveIndicator		 
	FROM dbo.translog14 B   WITH(NOLOCK)
	WHERE
		b.winlostdate <= @max_winlostdate
END
GO
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/