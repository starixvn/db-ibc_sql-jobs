USE [bk]
GO
ALTER PROCEDURE [dbo].[Task_Bets_TransForecast]
	@transid BIGINT
AS
/*
Created: 
Task:	 
DB: DBBET/BK
Revisions:
	- 20120904@Viet: add new sportsbook and number game bettype		   
	- 20130121@Johnson: move sp from DB052.BODB02 to DBBET/BK
	- 20160415@Percy: expand range Sportbook [Redmine: #53217]

Param's Explanation:
*/ 
INSERT INTO dbo.bets 
(
	transid,
	hdp1,
	hdp2,
	odds,
	stake,
	status,
	livehomescore,
	liveawayscore,
	liveindicator,
	betteam,
	tpositiontaking,
	matchid,
	oddsid,
	ruben,
	bettype,
	currency,
	custid,
	winlostdate
) 
SELECT
	transid,
	hdp1,
	hdp2,
	odds,
	stake,
	status,
	livehomescore,
	liveawayscore,
	liveindicator,
	betteam,
	tpositiontaking,
	matchid,
	oddsid,
	ruben,
	bettype,
	currency,
	custid,
	winlostdate
	-- remove  -50 : Joe : 20100627
	--From BetTrans with  (nolock) Where  transid > @transid-50 and bettype<41
FROM bodb02.dbo.bettrans WITH (NOLOCK)
WHERE transid > @transid --and bettype<41
	AND
	(
		bettype < 50
		OR bettype between 81 and 999
		OR bettype between 1201 and 1299
		OR bettype BETWEEN 1301 AND 1399  -- Open range of Sportsbook
	)
GO
GRANT VIEW DEFINITION ON [dbo].[Task_Bets_TransForecast] TO [vnteam] AS [dbo]
GO