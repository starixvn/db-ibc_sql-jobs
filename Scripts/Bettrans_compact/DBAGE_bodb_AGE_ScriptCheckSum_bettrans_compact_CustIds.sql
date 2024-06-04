/*<info serverAlias="DBAGE-bodb_AGE" isNested="0"></info>*/
DECLARE @winlostdate SMALLDATETIME = '2024-06-03'
	,@checkCustids VARCHAR(MAX)='2';

---------------------------------------------------
DROP TABLE IF EXISTS #checkBettransData;
CREATE TABLE #checkBettransData(
		[custid] [int] NOT NULL,
		[winlostdate] [smalldatetime] NOT NULL,
		[productId] [tinyint] NOT NULL,
		[sporttype] [int] NOT NULL,
		[bettype] [smallint] NOT NULL,
		[leagueGroupID] [int] NOT NULL,
		[ticketType] [int] NOT NULL,
		[betcount] [int] NULL,
		[turnover] [money] NULL,
		[netTurnover] [money] NULL,
		[TurnoverNoDraw] [money] NULL,
		[winlost] [money] NULL,
		[awinlost] [money] NULL,
		[mwinlost] [money] NULL,
		[swinlost] [money] NULL,
		[playercomm] [money] NULL,
		[comm] [money] NULL,
		[acomm] [money] NULL,
		[scomm] [money] NULL,
		[grosscomm] [money] NULL,
		[extraComm] [decimal](38, 6) NULL,
		[extraWinloss] [decimal](38, 6) NULL
);

--TODO: gen data from bettrans
INSERT INTO #checkBettransData(
	custid,winlostdate,productid,sporttype,bettype,leagueGroupID,ticketType
	,betcount,winlost,turnover,netTurnover,awinlost,mwinlost,swinlost,playercomm,comm,acomm,scomm,TurnoverNoDraw,grosscomm,ExtraComm,ExtraWinloss)
EXEC dbo.[Task_Gen_Compact_bettrans] @winlostdate= @winlostdate, @custids = @checkCustids


--TODO: get data from bettrans_compact
DROP TABLE IF EXISTS #__checkbettrans_compact;
select custid,winlostdate,productid,sporttype,bettype,leagueGroupID,ticketType
	,betcount,winlost,turnover,netTurnover,awinlost,mwinlost,swinlost,playercomm,comm,acomm,scomm,TurnoverNoDraw,grosscomm,ExtraComm,ExtraWinloss
into #__checkbettrans_compact
from dbo.bettrans_compact bc (NOLOCK)
WHERE custid IN (select value from string_split(@checkCustids, ','))
AND winlostdate=@winlostdate;


select 'bettrans', custid,winlostdate,productid,sporttype,bettype,leagueGroupID,ticketType
	,betcount,winlost,turnover,netTurnover,awinlost,mwinlost,swinlost,playercomm,comm,acomm,scomm,TurnoverNoDraw,grosscomm,ExtraComm,ExtraWinloss
from #checkBettransData

select 'bettrans_compact', custid,winlostdate,productid,sporttype,bettype,leagueGroupID,ticketType
	,betcount,winlost,turnover,netTurnover,awinlost,mwinlost,swinlost,playercomm,comm,acomm,scomm,TurnoverNoDraw,grosscomm,ExtraComm,ExtraWinloss
from #__checkbettrans_compact

--TODO: compare checkSum  bettrans vs bettrans_compact
;WITH bt_checksum AS (
	SELECT cal.custid, cal.winlostdate
		, (SELECT cal.custid, cal.winlostdate, cal.productId, cal.sporttype, cal.bettype, cal.leagueGroupID, cal.ticketType FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS KeyValue_BT
		, CHECKSUM(CONCAT_WS('|', cal.productid, cal.sporttype, cal.bettype, cal.leagueGroupID, cal.ticketType)) AS checkSumKey
		, (CHECKSUM(CONCAT_WS('|',betcount,	winlost, turnover,netTurnover
			,awinlost, mwinlost,swinlost,playercomm,comm,acomm,scomm,TurnoverNoDraw,grosscomm))) AS checkSumData

	FROM #checkBettransData AS cal 
), compact_checkSum AS (
	SELECT b.custid, b.winlostdate
		, (SELECT b.custid, b.winlostdate,b.productId, b.sporttype, b.bettype, b.leagueGroupID, b.ticketType FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS KeyValue_CP
		, CHECKSUM(CONCAT_WS('|', b.productId, b.sporttype, bettype, leagueGroupID, ticketType)) AS checkSumKey
		, (CHECKSUM(CONCAT_WS('|',betcount,	winlost, turnover,netTurnover
			, awinlost, mwinlost,swinlost,playercomm,comm,acomm,scomm,TurnoverNoDraw,grosscomm))) AS checkSumData 
		
	FROM #__checkbettrans_compact b
)
SELECT
	'bettrans >>' AS [bettrans]
	, bt.custid, bt.winlostdate, bt.KeyValue_BT, bt.checkSumKey, bt.checkSumData
	,'compact >>' AS [compact]
	, ck.custid, ck.winlostdate, ck.KeyValue_CP, ck.checkSumKey, ck.checkSumData
FROM  bt_checksum bt
FULL JOIN compact_checkSum ck ON ck.custid = bt.custid
	AND ck.winlostdate = bt.winlostdate
	AND ck.checkSumKey = bt.checkSumKey
WHERE (bt.custid IS NULL OR ck.custid IS NULL OR ck.checkSumData <> bt.checkSumData)
;