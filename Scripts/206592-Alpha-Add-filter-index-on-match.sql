/*<info serverAlias="DBAGE-bodb02" isNested="0"></info>*/
USE [bodb02]
GO

CREATE NONCLUSTERED INDEX [IXF_eventdate_sporttype] ON [dbo].[match]
(
	[eventdate] ASC,
	[sporttype] ASC,
	[matchid] ASC
)
INCLUDE([leagueid]) 
WHERE ([sporttype] IN ((1), (2), (50), (43), (5), (4), (47)))
WITH (ONLINE = ON) ON [DAT3]
GO