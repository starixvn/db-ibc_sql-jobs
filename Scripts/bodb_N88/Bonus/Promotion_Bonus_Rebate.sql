/*<info serverAlias="DBN88-bodb_N88"></info>*/
/*
	Created: 20210111@Percty
	DB: DBN88-bodb_N88
	Task: B2C - Add new tables for Bonus & Rebate Info
*/
USE bodb_N88
GO

CREATE TABLE dbo.CustBonusRollover (
	BonusId int NOT NULL,
	PromoCategoryId int NOT NULL,
	TpId int NOT NULL,
	CustId int NOT NULL,
	SiteId int NOT NULL,
	Rollover decimal(18,4) NOT NULL,
	Turnover decimal(18,4) NOT NULL,
	Status tinyint NOT NULL,
	CreateTime datetime NOT NULL,
	UpdateTime datetime,
	Winlostdate AS CONVERT(DATE, CreateTime)
	CONSTRAINT PK_CustBonusRollover PRIMARY KEY NONCLUSTERED
	(
		BonusId ASC
	)
) ON ReportData

CREATE CLUSTERED INDEX CIX_CustBonusRollover ON dbo.CustBonusRollover (Winlostdate) ON ReportData
GO

CREATE TABLE dbo.Promotion (
	BonusCode varchar(50) NOT NULL,
	SiteId int NOT NULL,
	Description varchar(300),
	PromotionType tinyint NOT NULL,
	CategoryId tinyint NOT NULL,
	TpId int,
	PeriodFrom bigint NOT NULL,
	PeriodTo bigint NOT NULL,
	StartDate datetime,
	EndDate datetime,
	ExpiryDays tinyint NOT NULL,
	Sort smallint NOT NULL,
	CreateTime datetime NOT NULL,
	Status tinyint NOT NULL,
	LastUpdateTime datetime,
	LastUpdateUser varchar(50),
	WalletType tinyint,
	RedeemHours tinyint,
	PeriodType tinyint,
	PeriodDay tinyint,
	SpecialCode varchar(20),
	IsSpecial bit,
	Winlostdate AS CONVERT(DATE, CreateTime)
	CONSTRAINT PK_Promotion PRIMARY KEY NONCLUSTERED
	(
		BonusCode ASC,
		SiteId ASC
	)
) ON ReportData

CREATE CLUSTERED INDEX CIX_Promotion ON dbo.Promotion (Winlostdate) ON ReportData
GO

CREATE TABLE dbo.PromotionSpecific (
	BonusCode varchar(50) NOT NULL,
	CurrencyId tinyint NOT NULL,
	SiteId int NOT NULL,
	Usage int NOT NULL,
	BeenUsed int NOT NULL,
	RollOver int NOT NULL,
	Bonus decimal(18,2) NOT NULL,
	BonusType tinyint NOT NULL,
	RequiredAmount decimal(18,2),
	LockedType varchar(45) NOT NULL,
	MaxBonus decimal(18,2) NOT NULL,
	Status tinyint NOT NULL,
	Details nvarchar(max),
	CreateTime datetime NOT NULL,
	UpdateTime datetime,
	LastClaimTime datetime,
	MinPayout decimal(18,2) NOT NULL,
	SettleTime datetime,
	AffId int NOT NULL,
	VN_AffId int NOT NULL,
	VN_AffIds nvarchar(max),
	VN_AffCodes nvarchar(max),
	Winlostdate AS CONVERT(DATE, CreateTime)
	CONSTRAINT PK_PromotionSpecific PRIMARY KEY NONCLUSTERED
	(
		BonusCode ASC,
		CurrencyId ASC,
		SiteId ASC
	)
) ON ReportData

CREATE CLUSTERED INDEX CIX_PromotionSpecific ON dbo.PromotionSpecific (Winlostdate) ON ReportData
GO


CREATE TABLE dbo.RebateMLog (
	Id int NOT NULL,
	CustId int,
	CurrencyId tinyint,
	RebateType tinyint,
	UserName varchar(30),
	SiteId int,
	RedeemAmount decimal(18,4),
	BonusCode varchar(50),
	Memo varchar(200),
	RelId bigint,
	CreateTime datetime,
	Winlostdate AS CONVERT(DATE, CreateTime)
	CONSTRAINT PK_RebateMLog PRIMARY KEY NONCLUSTERED
	(
		Id ASC
	)
) ON ReportData

CREATE CLUSTERED INDEX CIX_RebateMLog ON dbo.RebateMLog (Winlostdate) ON ReportData
GO