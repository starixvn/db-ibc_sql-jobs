/*<info serverAlias="DBBAH-bodb02" executers="" viewers="" isFunction="0"></info>*/
use bodb02
go
/*
   Created:Thomas@20231030  
   DB: DBBAH-bodb02
*/
DROP TRIGGER IF EXISTS dbo.Bettrans_Instead_Of_Insert
go
DROP TRIGGER IF EXISTS dbo.Bettrans_After_Update
go
DROP TRIGGER IF EXISTS dbo.bettransG_After_Insert
go
DROP TRIGGER IF EXISTS dbo.bettransG_After_Update
go
DROP TRIGGER IF EXISTS dbo.bettransLC_After_Update
go
DROP TRIGGER IF EXISTS dbo.bettransLC_After_Insert
go
DROP TRIGGER IF EXISTS dbo.BettransRNG_After_Insert
go
DROP TRIGGER IF EXISTS dbo.BettransRNG_After_Update
go
DROP TRIGGER IF EXISTS dbo.TransLog_After_Insert
go
DROP TRIGGER IF EXISTS dbo.TransLog_After_Update