USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Task_MissingCheck]    Script Date: 01/21/2015 23:28:37 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_MissingCheck]
AS
SET NOCOUNT ON
-- get range to check (note:  minus 2 minute to allow repl. delay)
Declare @Message varchar(1000)
Declare @LastCheck bigint
Declare @MaxTrans  bigint
SELECT @LastCheck = transid FROM dbo.bettrans_lastcheck
SELECT @MaxTrans = MAX(transid) FROM dbo.bettrans WHERE transid > @LastCheck
AND TransDate < DATEADD(minute, -2, CURRENT_TIMESTAMP)

SET @Message = CAST(@LastCheck as varchar(20)) + ' :: '
IF @MaxTrans IS NULL		BEGIN PRINT @Message RETURN END
IF @MaxTrans < @LastCheck	BEGIN PRINT @Message RETURN END

SET @Message = @Message + 'FROM ' + CAST(@LastCheck as varchar(20)) + ' to ' + CAST(@MaxTrans as varchar(20)) + ' :: '
-- update lastcheck
UPDATE bettrans_lastcheck 
SET transid = @MaxTrans

-- count ticket
Declare @This int, @That int
SELECT @This = COUNT(*) FROM dbo.bettrans WHERE transid BETWEEN @LastCheck and @MaxTrans
SELECT @That = COUNT(*) FROM DBTrans.bodb02.dbo.bettrans with (rowlock) WHERE transid BETWEEN @LastCheck and @MaxTrans

SET @Message = @Message + 'This ' + CAST(@This as varchar(20)) + ' and That ' + CAST(@That as varchar(20))

IF @This <> @That
BEGIN
	SET @Message = '### Missing ### ' + CAST(@That - @This as varchar(20)) + ' :: ' + @Message

	Declare @Missing TABLE (transid bigint)
	INSERT INTO @Missing
	SELECT transid FROM DBTrans.bodb02.dbo.bettrans
	WHERE transid BETWEEN @LastCheck AND @MaxTrans
	AND transid NOT IN (select transid FROM dbo.bettrans WHERE transid BETWEEN @LastCheck AND @MaxTrans)

	INSERT INTO bettrans_missing (transid)
	SELECT transid FROM @Missing

	SET IDENTITY_INSERT bettrans ON
	INSERT INTO bettrans (
		transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost, playercomm, comm, acomm, apositiontaking, 
		mpositiontaking, tpositiontaking, playerdiscount, discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, 
		winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, mrecommend, ruben, betid, statuswinlost, modds, bettype, 
		betdaqid, actual_stake, currency, ip, transdesc, sdiscount, scomm, spositiontaking, swinlost, srecommend, Username, CurrencyName, 
		virtualrate, oddstype, statusID, currency2, balance, SecAcceptFlag, transid2, recommdate
)	SELECT
		transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost, playercomm, comm, acomm, apositiontaking, 
		mpositiontaking, tpositiontaking, playerdiscount, discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, 
		winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, mrecommend, ruben, betid, statuswinlost, modds, bettype, 
		betdaqid, actual_stake, currency, ip, transdesc, sdiscount, scomm, spositiontaking, swinlost, srecommend, Username, CurrencyName, 
		virtualrate, oddstype, statusID, currency2, balance, SecAcceptFlag, transid2, recommdate
	FROM DBTrans.bodb02.dbo.bettrans with (rowlock)
	WHERE transid IN (SELECT transid FROM @Missing)
	SET IDENTITY_INSERT bettrans OFF

	PRINT @Message
	-- raiserror here to continue to next step of jobs
	RAISERROR ('* Missing Ticket *', -- Message text.
               16, -- Severity.
               1 -- State.
               );
END
ELSE
PRINT '#### OK #### ' + @Message

SET NOCOUNT OFF


GO


