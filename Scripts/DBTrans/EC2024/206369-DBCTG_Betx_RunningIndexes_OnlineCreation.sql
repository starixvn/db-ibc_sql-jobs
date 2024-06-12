/*<info serverAlias="DBCTG-bodb02" executers="" viewers="" isFunction="0"></info>*/
/*
	Created by: 20240612@Bobby
	Task : Switch to DBTrans [RedmineID: #206369]
	DB: DBCTG/bodb02

*/
USE bodb02;


---1. bettrans indexes
/****** Object:  Index [IX_betrunning_custid]    Script Date: 6/12/2024 11:09:54 AM ******/
CREATE NONCLUSTERED INDEX [IX_betrunning_custid] ON [dbo].[bettrans]
(
	[custid] ASC,
	[bettype] ASC
)
INCLUDE([actual_stake],[adiscount],[apositiontaking],[betcheck],[betid],[betteam],[checktime],[comstatus],[discount],[hdp1],[hdp2],[ip],[liveawayscore],[livehomescore],[liveindicator],[matchid],[modds],[mpositiontaking],[odds],[oddsid],[oddsspread],[oddstype],[refno],[sdiscount],[SecAcceptFlag],[spositiontaking],[stake],[status],[statusID],[transdate],[TransId],[transdesc],[ExtraInfo],[DeviceType]) 
WHERE (([statusID] IN ((0), (1))) AND [SiteDBGroupID]=(3))
WITH (ONLINE = ON) ON [Bettrans_index1]
GO

/****** Object:  Index [IX_betrunning_mrecommend]    Script Date: 6/12/2024 11:09:55 AM ******/
CREATE NONCLUSTERED INDEX [IX_betrunning_mrecommend] ON [dbo].[bettrans]
(
	[mrecommend] ASC,
	[bettype] ASC,
	[matchid] ASC
)
INCLUDE([odds],[stake],[mpositiontaking],[livehomescore],[liveawayscore],[liveindicator],[betteam],[spositiontaking],[actual_stake],[recommend],[custid],[Username],[refno],[TransId],[betid],[hdp1],[hdp2],[modds],[SecAcceptFlag],[checktime],[status],[transdate],[apositiontaking],[tpositiontaking],[discount],[adiscount],[sdiscount],[ip],[oddstype],[comstatus],[betcheck],[oddsspread],[currency],[ExtraInfo]) 
WHERE (([statusID] IN ((0), (1))) AND [SiteDBGroupID]=(3))
WITH (ONLINE = ON) ON [Bettrans_index1]
GO

/****** Object:  Index [IX_betrunning_recommend]    Script Date: 6/12/2024 11:09:55 AM ******/
CREATE NONCLUSTERED INDEX [IX_betrunning_recommend] ON [dbo].[bettrans]
(
	[recommend] ASC,
	[bettype] ASC,
	[matchid] ASC
)
INCLUDE([odds],[stake],[apositiontaking],[livehomescore],[liveawayscore],[liveindicator],[betteam],[custid],[actual_stake],[mpositiontaking],[spositiontaking],[Username],[refno],[TransId],[betid],[hdp1],[hdp2],[modds],[SecAcceptFlag],[checktime],[status],[transdate],[tpositiontaking],[discount],[adiscount],[sdiscount],[ip],[oddstype],[comstatus],[betcheck],[oddsspread],[currency],[ExtraInfo]) 
WHERE (([statusID] IN ((0), (1))) AND [SiteDBGroupID]=(3))
WITH (ONLINE = ON) ON [Bettrans_index1]
GO

/****** Object:  Index [IX_betrunning_srecommend]    Script Date: 6/12/2024 11:09:56 AM ******/
CREATE NONCLUSTERED INDEX [IX_betrunning_srecommend] ON [dbo].[bettrans]
(
	[srecommend] ASC,
	[bettype] ASC,
	[matchid] ASC
)
INCLUDE([odds],[stake],[livehomescore],[liveawayscore],[liveindicator],[betteam],[spositiontaking],[custid],[mpositiontaking],[actual_stake],[mrecommend],[recommend],[Username],[refno],[TransId],[betid],[hdp1],[hdp2],[modds],[SecAcceptFlag],[checktime],[status],[transdate],[apositiontaking],[tpositiontaking],[discount],[adiscount],[sdiscount],[ip],[oddstype],[comstatus],[betcheck],[oddsspread],[currency],[ExtraInfo]) 
WHERE (([statusID] IN ((0), (1))) AND [SiteDBGroupID]=(3))
WITH (ONLINE = ON) ON [Bettrans_index1]
GO

---2. bettransLC indexes
/****** Object:  Index [IX_betrunning_custid]    Script Date: 6/12/2024 11:17:47 AM ******/
CREATE NONCLUSTERED INDEX [IX_betrunning_custid] ON [dbo].[bettransLC]
(
	[custid] ASC
)
INCLUDE([RefNo],[gameID],[stake],[actual_stake],[apositiontaking],[mpositiontaking],[spositiontaking],[discount],[adiscount],[sdiscount]) 
WHERE (([statusID] IN ((0), (1))) AND [SiteDBGroupID]=(3))
WITH (ONLINE = ON) ON [bettransLC_index]
GO

/****** Object:  Index [IX_betrunning_mrecommend]    Script Date: 6/12/2024 11:17:48 AM ******/
CREATE NONCLUSTERED INDEX [IX_betrunning_mrecommend] ON [dbo].[bettransLC]
(
	[mrecommend] ASC,
	[gameID] ASC
)
INCLUDE([mpositiontaking],[spositiontaking],[actual_stake],[recommend]) 
WHERE (([statusID] IN ((0), (1))) AND [SiteDBGroupID]=(3))
WITH (ONLINE = ON) ON [bettransLC_index]
GO

/****** Object:  Index [IX_betrunning_recommend]    Script Date: 6/12/2024 11:17:48 AM ******/
CREATE NONCLUSTERED INDEX [IX_betrunning_recommend] ON [dbo].[bettransLC]
(
	[recommend] ASC,
	[gameID] ASC
)
INCLUDE([custid],[apositiontaking],[actual_stake],[mpositiontaking],[spositiontaking]) 
WHERE (([statusID] IN ((0), (1))) AND [SiteDBGroupID]=(3))
WITH (ONLINE = ON) ON [bettransLC_index]
GO

/****** Object:  Index [IX_betrunning_srecommend]    Script Date: 6/12/2024 11:17:48 AM ******/
CREATE NONCLUSTERED INDEX [IX_betrunning_srecommend] ON [dbo].[bettransLC]
(
	[srecommend] ASC,
	[gameID] ASC
)
INCLUDE([spositiontaking],[actual_stake],[mrecommend]) 
WHERE (([statusID] IN ((0), (1))) AND [SiteDBGroupID]=(3))
WITH (ONLINE = ON) ON [bettransLC_index]
GO

---3. bettransRNG indexes
/****** Object:  Index [IX_betrunning_custid]    Script Date: 6/12/2024 11:19:23 AM ******/
CREATE NONCLUSTERED INDEX [IX_betrunning_custid] ON [dbo].[bettransRnG]
(
	[custid] ASC
)
INCLUDE([RefNo],[gameID],[stake],[actual_stake],[apositiontaking],[mpositiontaking],[spositiontaking],[discount],[adiscount],[sdiscount]) 
WHERE (([statusID] IN ((0), (1))) AND [SiteDBGroupID]=(3))
WITH (ONLINE = ON) ON [bettransRnG_index]
GO

/****** Object:  Index [IX_betrunning_mrecommend]    Script Date: 6/12/2024 11:19:24 AM ******/
CREATE NONCLUSTERED INDEX [IX_betrunning_mrecommend] ON [dbo].[bettransRnG]
(
	[mrecommend] ASC,
	[gameID] ASC
)
INCLUDE([mpositiontaking],[spositiontaking],[actual_stake],[recommend]) 
WHERE (([statusID] IN ((0), (1))) AND [SiteDBGroupID]=(3))
WITH (ONLINE = ON) ON [bettransRnG_index]
GO

/****** Object:  Index [IX_betrunning_recommend]    Script Date: 6/12/2024 11:19:24 AM ******/
CREATE NONCLUSTERED INDEX [IX_betrunning_recommend] ON [dbo].[bettransRnG]
(
	[recommend] ASC,
	[gameID] ASC
)
INCLUDE([custid],[apositiontaking],[actual_stake],[mpositiontaking],[spositiontaking]) 
WHERE (([statusID] IN ((0), (1))) AND [SiteDBGroupID]=(3))
WITH (ONLINE = ON) ON [bettransRnG_index]
GO

/****** Object:  Index [IX_betrunning_srecommend]    Script Date: 6/12/2024 11:19:24 AM ******/
CREATE NONCLUSTERED INDEX [IX_betrunning_srecommend] ON [dbo].[bettransRnG]
(
	[srecommend] ASC,
	[gameID] ASC
)
INCLUDE([spositiontaking],[actual_stake],[mrecommend]) 
WHERE (([statusID] IN ((0), (1))) AND [SiteDBGroupID]=(3))
WITH (ONLINE = ON) ON [bettransRnG_index]
GO


---4. translog indexes
/****** Object:  Index [IX_betrunning_custid]    Script Date: 6/12/2024 11:20:38 AM ******/
CREATE NONCLUSTERED INDEX [IX_betrunning_custid] ON [dbo].[translog]
(
	[custid] ASC,
	[gameID] ASC
)
INCLUDE([translogid],[eventID],[odds],[status],[stake],[actual_stake],[transdate],[apositiontaking],[mpositiontaking],[spositiontaking],[discount],[adiscount],[sdiscount],[ip],[custom1],[custom2],[custom3],[transdesc],[Gameid3rd],[Tranid3rd],[liveindicator]) 
WHERE (([statusID] IN ((0), (1))) AND [SiteDBGroupID]=(3))
WITH (ONLINE = ON) ON [translog_index]
GO

/****** Object:  Index [IX_betrunning_mrecommend]    Script Date: 6/12/2024 11:20:39 AM ******/
CREATE NONCLUSTERED INDEX [IX_betrunning_mrecommend] ON [dbo].[translog]
(
	[mrecommend] ASC,
	[gameID] ASC
)
INCLUDE([mpositiontaking],[spositiontaking],[actual_stake],[recommend]) 
WHERE (([statusID] IN ((0), (1))) AND [SiteDBGroupID]=(3))
WITH (ONLINE = ON) ON [translog_index]
GO

/****** Object:  Index [IX_betrunning_recommend]    Script Date: 6/12/2024 11:20:39 AM ******/
CREATE NONCLUSTERED INDEX [IX_betrunning_recommend] ON [dbo].[translog]
(
	[recommend] ASC,
	[gameID] ASC
)
INCLUDE([custid],[apositiontaking],[actual_stake],[mpositiontaking],[spositiontaking]) 
WHERE (([statusID] IN ((0), (1))) AND [SiteDBGroupID]=(3))
WITH (ONLINE = ON) ON [translog_index]
GO

/****** Object:  Index [IX_betrunning_srecommend]    Script Date: 6/12/2024 11:20:39 AM ******/
CREATE NONCLUSTERED INDEX [IX_betrunning_srecommend] ON [dbo].[translog]
(
	[srecommend] ASC,
	[gameID] ASC
)
INCLUDE([spositiontaking],[actual_stake],[mrecommend]) 
WHERE (([statusID] IN ((0), (1))) AND [SiteDBGroupID]=(3))
WITH (ONLINE = ON) ON [translog_index]
GO

---5.SportBettypeMatrix
CREATE NONCLUSTERED INDEX [IX_productID2] ON [dbo].[SportBettypeMatrix]
(
	[ProductID] ASC,
	[IsTest] ASC
)
INCLUDE([BetType],[Enabled],[EventType],[SubProduct],[RefTable]) 
WITH (ONLINE = ON) ON [DATA]
GO