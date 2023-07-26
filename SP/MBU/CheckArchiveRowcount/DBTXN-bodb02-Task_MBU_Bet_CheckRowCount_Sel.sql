/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_MBU_Bet_CheckRowCount_Sel]
	@DateCheck SMALLDATETIME,
	@OutputData VARCHAR(4000) = '' OUTPUT
AS
/*
	Created: 20180925@Patrick
	Task: Check consistency data for archiving process

	Revisions:
		- 20180926@Patrick:	Initial - [RedmineId: #101207]
		- 20190806@Patrick: Add transfer_bk - [RedmineId: #118277] 
		- 20191030@Billy:	Remove table [BetLucky3Result] - [Redmine: #122987]
		- 20200728@Brice:	Add 13 tables - [Redmine: #111093]
		- 20210628@Helen:	Move checking for TVS tables to another SP Task_MBU_TVS_CheckRowCount_Sel [RedmineId: #157539]
		- 20211214@Kathy: Separate Transfer Tickets[Redmine:#164197]
		- 20220317@Helen: Missing bettype when checking transfer data [Redmine:#164197]
		- 20220324@Kathy: Add index hint to get rowcount of transfer [Redmine:#170113]
		- 20230725@Brice: remove NG2 [RedmineID: #186722]
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @__tempCount TABLE (rowcnt INT, tableName VARCHAR(128))

	--//sum_winloss
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'sum_winloss' 
	FROM dbo.sum_winloss WITH(NOLOCK) 
	WHERE winlostdate = @DateCheck
	
	--//bettransLC
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'bettransLC' 
	FROM dbo.bettransLC14 WITH(NOLOCK)
	WHERE winlostdate = @DateCheck
	
	--//bettransRnG
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'bettransRnG' 
	FROM dbo.bettransRnG14 WITH(NOLOCK) 
	WHERE winlostdate = @DateCheck	

	--//translog
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'translog' 
	FROM dbo.translog14 WITH(NOLOCK)
	WHERE winlostdate = @DateCheck

	--//bettransm
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'bettransm' 
	FROM dbo.bettransm14 WITH(NOLOCK)
	WHERE winlostdate = @DateCheck

	--//bettrans
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT COUNT(1), 'bettrans' 
	FROM dbo.bettrans14 WITH(NOLOCK) 
	WHERE winlostdate = @DateCheck

	--//transfer
	INSERT INTO @__tempCount(rowcnt, tableName)
	SELECT	COUNT(1), 'Transfer'
	FROM	dbo.Transfer WITH(NOLOCK, INDEX=IX_WinlostDate)
	WHERE	WinlostDate = @DateCheck
			AND custid <> 0
			AND (winlost + actual_stake) <> 0
			AND bettype > 20000

	
	SELECT @OutputData = (
		SELECT rowcnt AS r, tableName AS t
		FROM @__tempCount
		FOR XML RAW ('r')
	)

END
GO
