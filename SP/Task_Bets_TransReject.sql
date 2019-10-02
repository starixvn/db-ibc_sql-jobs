/*<info serverAlias="DBBET-bk" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Bets_TransReject]
	@transid BIGINT -- no need, will remove after
AS
/*
	Created: 
	Task:	 
	DB: DBBET/BK
	Revisions:
		- 20120904@Viet: add new sportsbook and number game bettype		   
		- 20130121@Johnson: move sp from DB052.BODB02 to DBBET/BK
		- 201604015@Percy: fix missed ticket in bet check report [Redmine: #53217]
		- 20170704@Robert: Integrate Betradar Virtual Sports Product [Redmine: #78495]
		- 20170814@Tom: Enhance performance
		- 20170828@Robert: Integrate Lucky3 product into NAP Acc Reports [RedmineID: #78214]
		- 20171122@Dominic: Exclude Metric Superlive from this job
		- 20190926@Patrick: Revise sp to let it use another index to reduce IO read [RedmineID: #118117]

Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON;
	DECLARE @isTest BIT= 0;
	SELECT @isTest = dbo.f_CheckSPVersion(@@PROCID);

	DECLARE @tstamp_min BINARY(8), @tstamp_max BINARY(8)

	SELECT @tstamp_min = CAST(CAST(ISNULL(VValue, 0) AS BIGINT)+1 AS BINARY(8))
	FROM dbo.BetBackupSettings WITH (ROWLOCK)
	WHERE VName = 'betReject'

	SELECT @tstamp_max = ISNULL(MAX(tstamp), @tstamp_min)  
	FROM bodb02.dbo.bettrans WITH(NOLOCK)

	WAITFOR DELAY '00:00:00:010'

	DECLARE @__transIdList TABLE (transId BIGINT)
	INSERT INTO @__transIdList(transId)
	SELECT transid
	FROM bodb02.dbo.bettrans with (NOLOCK)
	WHERE tstamp BETWEEN @tstamp_min AND @tstamp_max

	IF @@ROWCOUNT > 0
	BEGIN
 
		INSERT INTO dbo.betsreject
		([transid]
			,[hdp1]
			,[hdp2]
			,[odds]
			,[stake]
			,[status]
			,[livehomescore]
			,[liveawayscore]
			,[liveindicator]
			,[betteam]
			,[tpositiontaking]
			,[matchid]
			,[oddsid]
			,[ruben]
			,[bettype]
			,[currency]
			,[custid]
			,[winlostdate]
			,[transdesc])
		SELECT transid,
			hdp1,
			hdp2,
			odds,
			stake,
			STATUS,
			livehomescore,
			liveawayscore,
			liveindicator,
			betteam,
			tpositiontaking,
			matchid,
			oddsid,
			ruben,
			b.bettype,
			currency,
			custid,
			winlostdate,
			case when b.bettype = 1600 then transdesc else NULL end as transdesc
		FROM bodb02.dbo.bettrans b WITH (NOLOCK)
		WHERE NOT EXISTS (
				SELECT transid
				FROM dbo.betsreject r WITH (NOLOCK)
				WHERE r.transid = b.transid
			)
			AND EXISTS (SELECT TOP 1 1 FROM @__transIdList t WHERE t.transId = b.transid)
			AND b.statusID IN(101, 102)
			AND b.bettype IN (
						SELECT Bettype                       
						FROM bodb02.dbo.f_SportBettypeMatrix_Sel(0, 0, 0, 2, '', '', @isTest)
						WHERE ProductID IN(1, 2, 3, 5, 25, 26, 27)
							AND SubProduct NOT IN('BT-Sold', 'BT-Bought', 'BT-Comm', 'BT-Winloss', 'MG-SuperLive')
					)
	END

	IF @@ROWCOUNT = 0
	BEGIN
		UPDATE dbo.BetBackupSettings WITH(ROWLOCK, UPDLOCK)
		SET VValue = CAST(CAST(@tstamp_max AS BIGINT) AS VARCHAR(200))
		WHERE VName = 'betReject'
	END
END