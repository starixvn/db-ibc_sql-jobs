/*<info serverAlias="DBBAH-bodb02" executers="" viewers="" isFunction="0"></info>*/
CREATE TABLE dbo.StatementMovementHistory
(
	CustId INT
	,MatchId INT
	,TransId BIGINT
	,WinlostDate DATETIME
	,OldWinlostDate DATETIME
	,Winlost MONEY
	,ActualStake MONEY
	,PlayerComm MONEY
	,Bettype SMALLINT
) ON [Others_index]