USE [bodb_Licensee]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Task_PrepareStaging_CreditSites]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Task_PrepareStaging_CreditSites]
GO

USE [bodb_Licensee]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[Task_PrepareStaging_CreditSites]  
    @datestart smalldatetime
    ,@dateend smalldatetime
AS  
/*
Created: 
Task : 

DB: bodb_Licensee
Original:

Revisions:
	+20120423@Jim: Add more information for BARM Agent
	
Param's Explanation:

*/
BEGIN

    declare @datefrom smalldatetime, @dateto smalldatetime
    select @datefrom = @datestart, @dateto = @dateend
    select @dateto = dateadd(day,1,@dateto)
	
	---------PROCESS OUTRIGHT DATA--------------------------------------------------------------------------------------------  
	TRUNCATE TABLE dbo.outright  
	
	INSERT INTO dbo.outright  
	    (matchid, leagueid, groupmatch, homeid, awayid, eventdate, kickofftime, oddsstatus, odds, [status], risk, sporttype)  	
	SELECT orid AS matchid, outright_bk.leagueid, groupmatch, teamid AS homeid, null AS awayid, eventdate, kickofftime, oddsstatus, odds, [status], risk, sporttype
	FROM db06.bodb_Archive.dbo.outright_bk WITH(NOLOCK)
	    LEFT JOIN bodb02.dbo.league (NOLOCK) ON outright_bk.leagueid = league.leagueid
	WHERE eventdate >= @datefrom AND eventdate < @dateto

	---------PROCESS MATCH DATA--------------------------------------------------------------------------------------------  
	TRUNCATE TABLE [dbo].[match]  
	
	INSERT INTO [dbo].[match]  
			   ([matchid]  
			   ,[leagueid]  
			   ,[homeid]  
			   ,[awayid]  
			   ,[eventdate]  
			   ,[finalhomescore]  
			   ,[finalawayscore]  
			   ,[exrisk]  
			   ,[sporttype],matchcode,  
	 hthomescore,htawayscore,kickofftime)  
	SELECT  m.[matchid] ,m.[leagueid] ,m.[homeid] ,m.[awayid] ,m.[eventdate],m.[finalhomescore],m.[finalawayscore],m.[exrisk],m.[sporttype],  
	    m.matchcode,m.hthomescore,m.htawayscore,m.kickofftime  
	FROM db06.bodb_Archive.dbo.match_bk m WITH(NOLOCK)  
	WHERE eventdate>=@datefrom AND eventdate<@dateto
	  
	---------PROCESS BETTRANS DATA--------------------------------------------------------------------------------------------  
	TRUNCATE TABLE [bettrans]  

	-- Copy history data (bettrans)  
	INSERT INTO dbo.bettrans
			   ([transid]
			   ,winlostdate
			   ,betfrom
			   ,liveindicator
			   ,bettype
			   ,[custid]
			   ,betteam
			   ,[stake]
			   ,actual_stake
			   ,[winlost],[awinlost],[mwinlost],swinlost
			   ,acomm,scomm,playercomm,comm
			   ,[tpositiontaking],spositiontaking,[mpositiontaking],[apositiontaking] 
			   ,matchid
			   ,[status]
			   ,[srecommend]
			   ,actualrate
			   ,currency
			   ,recommend,mrecommend
			   ,refno
			   ,transdate
			   ,statusid
			   ,virtualrate
			   ,isBA
			   ,discount
			   ,customercategory)  
	SELECT b.transid
	    ,b.winlostdate
	    ,b.betfrom
	    ,b.liveindicator
	    ,b.bettype
	    ,b.custid
	    ,b.betteam
        ,CASE WHEN winlostdate < '2011-09-01' THEN b.stake ELSE ABS(b.stake) END stake
        ,b.actual_stake
        ,b.winlost,b.awinlost
        ,b.mwinlost+CASE WHEN b.bettype>30 AND b.bettype<50 THEN b.swinlost ELSE 0 END mwinlost
        ,CASE WHEN b.bettype>30 AND b.bettype<50 THEN (winlost-stake)*(1-tpositiontaking-ISNULL(oddsspread,0)) ELSE b.swinlost END swinlost
        ,acomm,scomm,playercomm,comm
        ,CASE WHEN b.bettype>30 AND b.bettype<50 THEN 1-ISNULL(oddsspread,0) ELSE b.tpositiontaking END tpositiontaking,b.spositiontaking,b.mpositiontaking,b.apositiontaking
        ,b.matchid
        ,CASE WHEN (b.bettype IN (1, 3, 7, 8, 17, 18) AND ABS(b.modds) = 0.25 AND [status] IN ('WON', 'LOSE')) OR (b.bettype IN (33,43) AND [status] <> 'refund' AND b.liveawayscore=0) THEN 'HALF ' ELSE '' END + b.status AS [status]
        ,b.srecommend
        ,null actualrate
        ,b.currency
        ,b.recommend,b.mrecommend
        ,b.refno
        ,b.transdate
        ,statusid
        ,virtualrate
        ,CONVERT(bit,0) isBA
        ,discount
        ,CONVERT(int,-1) customercategory
	FROM db06.bodb_Archive.dbo.bettrans_bk b WITH(NOLOCK)
	    LEFT JOIN bodb02.dbo.Customer c (NOLOCK) ON b.recommend=c.custid
	WHERE winlostdate>=@datefrom AND winlostdate<@dateto
		AND b.status NOT IN ('void', 'reject', 'running','done')
		AND c.site NOT IN (SELECT LicenseeName FROM dbo.Licensees lic (nolock) WHERE IsDeposit=1)

	------PROCESS STATUS ID FOR HALF WON/LOSE
	UPDATE dbo.bettrans
	SET statusid=114
	WHERE [status] IN ('half won')
	
	UPDATE dbo.bettrans
	SET statusid=115
	WHERE [status] IN ('half lose')
	
	--Override commission setting to zero for 8RM ,BARM 
	UPDATE bettrans  
	SET acomm=0,comm=0,scomm=0,playercomm=0,customercategory= CASE WHEN recommend=52466 THEN 27 -- 8RM
											ELSE 28 END 	
	WHERE recommend IN (52466,5707545)

  
END



GO
GRANT EXECUTE ON [dbo].[Task_PrepareStaging_CreditSites] TO [VNTeam]
GO
GRANT VIEW DEFINITION ON [dbo].[Task_PrepareStaging_CreditSites] TO [VNTeam]