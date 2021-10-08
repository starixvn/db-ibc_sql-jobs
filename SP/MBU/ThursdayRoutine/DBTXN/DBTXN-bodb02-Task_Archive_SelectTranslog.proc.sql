/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE	dbo.Task_Archive_SelectTranslog
AS
/*
	Creator:	20160614@Lukas
	Task:		Get data from translog14 for archiving
	Database:	DBTXN.bodb02

	Revisions:
		- 20160614@Lukas:	Initial - [Redmine: #000000]
		- 20211004@Helen:	Support IPv6 Phase 1 - change datatype first - [Redmine: #160390]
*/
BEGIN 
	SET NOCOUNT ON

	DECLARE  @max_winlostdate SMALLDATETIME

	SELECT	 @max_winlostdate = MAX(winlostdate)
	FROM	dbo.Task_ArchiveDate

	-- to DB06.bodb_Archive.dbo.translog_bk
	SELECT translogid, custid, transdate, odds, stake, status, apositiontaking, mpositiontaking, tpositiontaking, spositiontaking
		, playerdiscount, discount, adiscount, sdiscount, creator, winlostdate, betfrom, virtualrate, actualrate, actual_stake, currency
		, CurrencyName, recommend, mrecommend, srecommend
		, CASE WHEN ISNULL(B.ip,'') <> '' THEN cip.IP ELSE B.ip END AS IP
		, statusID, balance, Username, transdesc, productID, gameID, eventID, vendorID
		, GameId3rd, TranId3rd, custom1, custom2, custom3, LiveIndicator		 
	FROM dbo.translog14 B   WITH(NOLOCK)
		CROSS APPLY (SELECT IP from [dbo].f_IP_Compress (B.ip)) cip 
	WHERE
		b.winlostdate <= @max_winlostdate
END
GO
