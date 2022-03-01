CREATE PROCEDURE [dbo].[ExecRep_APL_02]
	@fdate Datetime
AS
/*
	Created by:Sophia
	Date: 20130601
	Task: Called by Task_BalanceUp_DB02 
	DB: DB02.BODB02 / SVRPRO.ProdDB
	Revisions:
		-20130809@viet: revise SP, then add to DB02_odds_info publication.
		-20170322@joychen : add script to fix DBODDS Server ,it haven't match14
 */ 
SET NOCOUNT ON 


IF @@SERVERNAME LIKE 'DBCLS1\SDBPROD' RETURN --- ProdDB of Apollo
		
IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'match' AND type = 'U') RETURN -- no match table, do nothing	

SET @fdate = CONVERT(varchar(10), @fdate, 120)
	
IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'odds' AND type = 'U')
BEGIN	
	delete from odds where matchid not in (select matchid from match)
END

IF (SELECT COUNT(1) FROM sysobjects WHERE name in ('liveScore','match14') AND type = 'U') = 2
BEGIN
	delete from liveScore 
	where matchid not in (
		select matchid from match with(nolock) 
		union all 
		select matchid from match14 with(nolock)
	)
END	
------because DBODDS Server haven't match14
IF @@SERVERNAME LIKE 'DBODDS%' or @@SERVERNAME LIKE 'SITDBODDS%'
BEGIN
	delete from liveScore 
	where matchid not in (
		select matchid from match with(nolock) 
	)

END


GO


