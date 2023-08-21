/*<info serverAlias="DBBAH-bodb02" executers="" viewers="" isFunction="0"></info>*/
USE bodb02
GO
--A): alter trigger case:

	--1)check long running
	--2)set lock timeout
	--3)set deadlock priority low
	--4)GO
	--5)alter trigger

--B): alter table case:

	--1)check long running
	--2)set lock timeout
	--3)set deadlock priority low
	--4)alter command

--#1)
DECLARE @__messageInfo VARCHAR(200)
__tryAgain:
IF (dbo.f_dba_check_long_holding_locks ('bettransG' /*tableName*/, getdate() /*current time*/, 1000 /*long query exceeded 1s*/, 1 /*retry in 1 min*/)) = 1
BEGIN
	SELECT @__messageInfo = 'curdt: ' + convert(varchar(50), getdate(), 121) + ' | Too many long running operations on the table. Retry attempt again ...'
	RAISERROR(@__messageInfo, 0, 1) WITH NOWAIT
	WAITFOR DELAY '00:00:00:333' --wait for alter schema
	GOTO __tryAgain
END


--doing.... 
--#2 #3)
SET LOCK_TIMEOUT 1024
SET DEADLOCK_PRIORITY LOW

--#4
GO
    
CREATE TRIGGER [dbo].[BettransG_Instead_Of_Insert]
   ON [dbo].[bettransG]
   INSTEAD OF INSERT
AS 
/*
    Created: Helen
    DB: DBBAH.bodb02
    Task: 
    Revision:
        - 20230818@Helen: NAP - SA Gaming - can not use betlist to search the refno which showed on bet credit history [Redmine:#179580]
*/
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	INSERT INTO [dbo].[bettransG]
           (
		   [transid], [custid], [transdate], [oddsid], [odds], [stake], [status], [winlost], [betteam], [creator], [refno], [winlostdate], [betfrom], [checktime], [apositiontaking], [mpositiontaking], [tpositiontaking], [awinlost], [mwinlost], [playerdiscount], [discount], [adiscount], [playercomm], [comm], [acomm], [actualrate], [matchid], [matchdate], [statuswinlost], [ruben], [bettype], [spositiontaking], [swinlost], [sdiscount], [scomm], [statusID], [virtualrate], [SiteID], [transdesc], [BetID3rd], [epositiontaking], [actual_stake], [netstake], [RepUpdateTime], [SiteDBGroupID]
		   )
	SELECT [transid], [custid], [transdate], [oddsid], [odds], [stake], [status], [winlost], [betteam], [creator], [refno], [winlostdate], [betfrom], [checktime], [apositiontaking], [mpositiontaking], [tpositiontaking], [awinlost], [mwinlost], [playerdiscount], [discount], [adiscount], [playercomm], [comm], [acomm], [actualrate], [matchid], [matchdate], [statuswinlost], [ruben], [bettype], [spositiontaking], [swinlost], [sdiscount], [scomm], [statusID], [virtualrate], [SiteID], [transdesc], [BetID3rd], [epositiontaking], [actual_stake], [netstake], [RepUpdateTime], [SiteDBGroupID]
	FROM INSERTED AS i
	WHERE i.SiteDBGroupID = 0
	
END

GO


