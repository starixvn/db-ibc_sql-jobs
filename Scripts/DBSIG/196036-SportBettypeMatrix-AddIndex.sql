/*<info serverAlias="DBSIG-bodb02" executers="" viewers="" isFunction="0"></info>*/   
-- run on DBSIG
USE [bodb02]
GO

CREATE NONCLUSTERED INDEX [IX_SportBettypeMatrix_bettype] ON [dbo].[SportBettypeMatrix]
(
	[BetType] ASC,
	[RefTable] ASC
) WITH(ONLINE = ON) ON [DATA]
GO


