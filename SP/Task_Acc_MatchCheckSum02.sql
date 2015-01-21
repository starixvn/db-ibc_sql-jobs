USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Task_Acc_MatchCheckSum02]    Script Date: 01/21/2015 01:56:40 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_Acc_MatchCheckSum02]
	@winlostdate smalldatetime = NULL
AS
	SET NOCOUNT ON

	IF @winlostdate IS NULL
		SET @winlostdate = DATEADD(day, -1, CONVERT(varchar(10), CURRENT_TIMESTAMP, 120))

	DELETE FROM dbo.Task_tmp_MatchCheckSUM02
	WHERE winlostdate = @winlostdate

	INSERT INTO dbo.Task_tmp_MatchCheckSUM02
	SELECT
		@winlostdate, 'b', matchid, bettype--, statusID
		--,ticketcount, winlost, awinlost, mwinlost, swinlost
		,CHECKSUM(CS_BigInt, CS_Bit, CS_Decimal, CS_Float, CS_Int, CS_Money, CS_Char, CS_SmallMoney, CS_Odds, CS_SmallInt) AS [CS_Global+Odds]
		,CHECKSUM(CS_BigInt, CS_Bit, CS_Decimal, CS_Float, CS_Int, CS_Money, CS_Char, CS_SmallMoney, CS_SmallInt) AS [CS_Global-Odds]
	FROM (
	SELECT
		matchid, bettype--, statusID
		--,count(transid) ticketcount
		--,sum(winlost) winlost, sum(awinlost) awinlost, sum(mwinlost) mwinlost, sum(swinlost) swinlost
		,CHECKSUM_AGG( CHECKSUM([transid],[refno],[betid],[betdaqid]) ) AS CS_BigInt
		,CHECKSUM_AGG( CHECKSUM([liveindicator]) ) AS CS_Bit
		,CHECKSUM_AGG( CHECKSUM([transdate],[checktime],[winlostdate]) ) AS CS_DateTime
		,CHECKSUM_AGG( CHECKSUM([playerdiscount],[discount],[adiscount],[sdiscount]) ) AS CS_Decimal
		,CHECKSUM_AGG( CHECKSUM([actualrate],[virtualrate]) ) AS CS_Float
		,CHECKSUM_AGG( CHECKSUM([custid],[oddsid],[creator],[matchid],[recommend],[mrecommend],[srecommend]) ) AS CS_Int
		,CHECKSUM_AGG( CHECKSUM([stake],[winlost],[awinlost],[mwinlost],[playercomm],[comm],[acomm],[actual_stake],[scomm],[swinlost]) ) AS CS_Money
		,CHECKSUM_AGG( CHECKSUM([status],[betteam],[comstatus],[betfrom],[betcheck],[ip],[transdesc],[Username],[CurrencyName]) ) AS CS_Char
		,CHECKSUM_AGG( CHECKSUM([hdp1],[hdp2],[apositiontaking],[mpositiontaking],[tpositiontaking],[oddsspread],[spositiontaking]) ) AS CS_SmallMoney
		,CHECKSUM_AGG( CHECKSUM([odds],[modds]) ) AS CS_Odds
		,CHECKSUM_AGG( CHECKSUM([livehomescore],[liveawayscore],[ruben],[statuswinlost],[bettype],[currency],[oddstype],[statusID],[currency2]) ) AS CS_SmallInt
	FROM bettrans (nolock)
	WHERE winlostdate = @winlostdate
	GROUP BY matchid, bettype--, statusID
	) AS X
	ORDER BY matchid, bettype--, statusID

	INSERT INTO dbo.Task_tmp_MatchCheckSUM02
	SELECT
		@winlostdate, 'm', matchid, 0
		,CHECKSUM(CS_BigInt, CS_Bit, CS_Decimal, CS_Float, CS_Int, CS_Money, CS_Char, CS_SmallMoney, CS_Odds, CS_SmallInt) AS [CS_Global+Odds]
		,CHECKSUM(CS_BigInt, CS_Bit, CS_Decimal, CS_Float, CS_Int, CS_Money, CS_Char, CS_SmallMoney, CS_SmallInt) AS [CS_Global-Odds]
	FROM (
	SELECT matchid
		,CHECKSUM_AGG( CHECKSUM([refno]) ) AS CS_BigInt
		,CHECKSUM_AGG( CHECKSUM([liveindicator]) ) AS CS_Bit
		,CHECKSUM_AGG( CHECKSUM([transdate], [winlostdate], [matchdate], [checktime]) ) AS CS_DateTime
		,CHECKSUM_AGG( CHECKSUM([playerdiscount], [discount], [adiscount], [sdiscount]) ) AS CS_Decimal
		,CHECKSUM_AGG( CHECKSUM([actualrate]) ) AS CS_Float
		,CHECKSUM_AGG( CHECKSUM([transid], [custid], [matchid], [oddsid], [creator]) ) AS CS_Int
		,CHECKSUM_AGG( CHECKSUM([stake], [winlost], [awinlost], [mwinlost], [swinlost], [playercomm], [comm], [acomm], [scomm]) ) AS CS_Money
		,CHECKSUM_AGG( CHECKSUM([betteam], [status], [betfrom], [betcheck], [comstatus], [isfinish]) ) AS CS_Char
		,CHECKSUM_AGG( CHECKSUM([hdp1], [hdp2], [oddsspread], [apositiontaking], [mpositiontaking], [spositiontaking], [tpositiontaking]) ) AS CS_SmallMoney
		,CHECKSUM_AGG( CHECKSUM([odds], [finalodds]) ) AS CS_Odds
		,CHECKSUM_AGG( CHECKSUM([bettype], [ruben], [statusID], [statuswinlost], [liveawayscore], [livehomescore]) ) AS CS_SmallInt
	FROM bettransm (nolock)
	WHERE winlostdate = @winlostdate
	GROUP BY matchid
	) AS X
	ORDER BY matchid

	PRINT CONVERT(varchar(10), @winlostdate, 120)

GO

GRANT VIEW DEFINITION ON [dbo].[Task_Acc_MatchCheckSum02] TO [vnteam] AS [dbo]
GO


