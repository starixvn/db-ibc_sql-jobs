/*<info serverAlias="DBN88-bodb_N88"></info>*/

/*
	Created: 20200818@Percy
	DB: DBN88-bodb_N88
	Task: Novacash - Add new tables
		. TpBetRecord: add new column: ValidBet
		. N88_RptWinloss: add new column: ValidBet
		. DepositInfo: add new column: Flag, Operator, UpdateTime
		. BonusInfo: add new table
		. WithdrawalInfo: add new table
		. CustRegInfo: add new table
*/

use bodb_N88
go

alter table dbo.TpBetRecord
	add ValidBet decimal(18,2)
go

alter table dbo.N88_RptWinloss
	add ValidBet money
go

alter table dbo.DepositInfo
	add Flag int,
		Operator varchar(30),
		UpdateTime datetime
go

create table dbo.BonusInfo
(
  BonusId int NOT NULL,
  TransId varchar(30),
  PromotionType tinyint NOT NULL,
  BonusCode varchar(50) NOT NULL,
  CustId int NOT NULL,
  UserName varchar(30) NOT NULL,
  CurrencyId tinyint NOT NULL,
  SiteId int NOT NULL,
  LockedAmount decimal(18,2) NOT NULL,
  BonusAmount decimal(18,2) NOT NULL,
  ExpiryTime datetime NOT NULL,
  BonusInfo nvarchar(max),
  Memo varchar(100),
  CreateTime datetime NOT NULL,
  Status tinyint NOT NULL,
  WinlostDate as (CONVERT(date, CreateTime, 0)),
  constraint PK_BonusInfo primary key nonclustered
  (
	BonusId asc
  ) on [ReportData]
) on [ReportData]
go

create clustered index CIX_BonusInfo ON dbo.BonusInfo
(
	WinlostDate asc
) on [ReportData]
go

create table dbo.WithdrawalInfo (
	WithdrawalId int not null,
	TransId varchar(30),
	WithdrawalType tinyint,
	CustId int,
	UserName varchar(35),
	CurrencyId tinyint,
	SiteId int,
	WithdrawalInfo nvarchar(max),
	Amount decimal(18,2),
	RefId varchar(100),
	ChargeFee decimal(18,2),
	CreateTime datetime,
	Memo varchar(200),
	Comment varchar(500),
	Status tinyint,
	Flag int,
	Operator varchar(30),
	UpdateTime datetime,
	WinlostDate as (CONVERT(date, CreateTime, 0)),
	constraint PK_WithdrawalInfo primary key nonclustered
	(
		WithdrawalId asc
	) on [ReportData]
) on [ReportData]
go

create clustered index CIX_WithdrawalInfo ON dbo.WithdrawalInfo
(
	WinlostDate asc
) on [ReportData]
go

create table dbo.CustRegInfo
(
  CustId int NOT NULL,
  SiteId int NOT NULL,
  SignupUrl varchar(200) NOT NULL,
  constraint PK_CustRegInfo primary key
  (
	CustId asc
  ) on [SettingData]
) on [SettingData]
go