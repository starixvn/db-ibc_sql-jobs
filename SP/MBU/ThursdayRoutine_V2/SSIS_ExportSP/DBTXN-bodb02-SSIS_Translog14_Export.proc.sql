/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_Translog14_Export]
	@winlostdate smalldatetime=null
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]	
	Database: DBTXN.bodb02
	Original: Task_Archive_SelectTranslog
	
	Revisions:
		- 20130831@Bobby: Init
 */
 BEGIN 
	SET NOCOUNT ON

	--DECLARE  @max_winlostdate SMALLDATETIME

	--SELECT	 @max_winlostdate = MAX(winlostdate)
	--FROM	dbo.Task_ArchiveDate

	-- to DB06.bodb_Archive.dbo.translog_bk
	SELECT translogid, custid, transdate, odds, stake, status, apositiontaking, mpositiontaking, tpositiontaking, spositiontaking
		, playerdiscount, discount, adiscount, sdiscount, creator, winlostdate, betfrom, virtualrate, actualrate, actual_stake, currency
		, CurrencyName, recommend, mrecommend, srecommend
		, CONVERT(VARCHAR(45),CASE WHEN ISNULL(B.ip,'') <> '' THEN cip.IP ELSE B.ip END) AS ip
		, statusID, balance, Username, transdesc, productID, gameID, eventID, vendorID
		, GameId3rd, TranId3rd, custom1, custom2, custom3, LiveIndicator		 
	FROM dbo.translog14 B   WITH(NOLOCK)
		CROSS APPLY (SELECT IP from [dbo].f_IP_Compress (B.ip)) cip 
	WHERE
		--b.winlostdate <= @max_winlostdate
		b.winlostdate = @winlostdate
END
GO

