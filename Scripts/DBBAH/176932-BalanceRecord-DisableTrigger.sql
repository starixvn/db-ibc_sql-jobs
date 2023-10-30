/*<info serverAlias="DBBAH-bodb02" executers="" viewers="" isFunction="0"></info>*/
use bodb02
go
/*
   Created:Thomas@20231030  
   DB: DBBAH-bodb02
   Task: Disable trigger [RedmineID: #176932]
*/
DISABLE TRIGGER dbo.Bettrans_After_Insert ON dbo.bettrans
go
DISABLE TRIGGER dbo.Bettrans_After_Update ON dbo.bettrans
go
DISABLE TRIGGER dbo.bettransG_After_Insert ON dbo.bettransG
go
DISABLE TRIGGER dbo.bettransG_After_Update ON dbo.bettransG
go
DISABLE TRIGGER dbo.bettransLC_After_Update ON dbo.bettransLC
go
DISABLE TRIGGER dbo.bettransLC_After_Insert ON dbo.bettransLC
go
DISABLE TRIGGER dbo.BettransRNG_After_Insert ON dbo.BettransRNG
go
DISABLE TRIGGER dbo.BettransRNG_After_Update ON dbo.BettransRNG
go
DISABLE TRIGGER dbo.TransLog_After_Insert ON dbo.translog
go
DISABLE TRIGGER dbo.TransLog_After_Update ON dbo.translog