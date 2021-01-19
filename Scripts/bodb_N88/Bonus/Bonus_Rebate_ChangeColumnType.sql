/*<info serverAlias="DBN88-bodb_N88"></info>*/
/*
	Created: 20210119@Percy
	DB: DBN88-bodb_N88
	Task: B2C - Change column data type
*/
use bodb_N88
go

alter table dbo.CustBonusRollover
	alter column Status smallint
go

-----------
alter table dbo.Promotion
	alter column PromotionType tinyint null
go
alter table dbo.Promotion
	alter column CategoryId tinyint null
go
alter table dbo.Promotion
	alter column ExpiryDays tinyint null
go
alter table dbo.Promotion
	alter column Sort smallint null
go
alter table dbo.Promotion
	alter column PeriodFrom bigint null
go
alter table dbo.Promotion
	alter column PeriodTo bigint null
go

--------
alter table dbo.PromotionSpecific
	alter column Usage int null
go
alter table dbo.PromotionSpecific
	alter column BeenUsed int null
go
alter table dbo.PromotionSpecific
	alter column RollOver int null
go
alter table dbo.PromotionSpecific
	alter column Bonus decimal(18, 2) null
go
alter table dbo.PromotionSpecific
	alter column BonusType tinyint null
go
alter table dbo.PromotionSpecific
	alter column LockedType varchar(45) null
go
alter table dbo.PromotionSpecific
	alter column MaxBonus decimal(18, 2) null
go
alter table dbo.PromotionSpecific
	alter column MinPayout decimal(18, 2) null
go
alter table dbo.PromotionSpecific
	alter column AffId int null
go
alter table dbo.PromotionSpecific
	alter column VN_AffId int null
go