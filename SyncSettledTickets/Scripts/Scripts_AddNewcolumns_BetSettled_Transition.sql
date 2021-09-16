/*<info serverAlias="DBAGE-bodb02" executers="" viewers="" isFunction="0"></info>*/
/*
	Created: 20210813@Helen
	Task: Sync settled ticket - smalldatetime
	DB: DBAGE/bodb02
*/ 
ALTER TABLE BetSettled_Transition ADD statusid TINYINT
GO
ALTER TABLE BetSettled_Transition ADD winlostdate smalldatetime
GO

