/*<info serverAlias="DBN88-bodb_N88"></info>*/

/*
	Created: 20200916@Percy
	DB: DBN88-bodb_N88
	Task: repull data due to API issue
*/

use bodb_N88
go

-- 1. BonusInfo
exec dbo.Task_API_TimeTracker_Import
	@DataSource = 'BonusInfo'
	,@CalledTime = '2020-08-31'
	,@KeyValue = '0'
	,@IsReset = 1
go

-- 2. Customer
exec dbo.Task_API_TimeTracker_Import
	@DataSource = 'Customer'
	,@CalledTime = '2020-08-31'
	,@KeyValue = ''
	,@IsReset = 1
go

-- 3. CustRegInfo
exec dbo.Task_API_TimeTracker_Import
	@DataSource = 'CustRegInfo'
	,@CalledTime = '2020-08-31'
	,@KeyValue = ''
	,@IsReset = 1
go

-- 4. DepositInfo
exec dbo.Task_API_TimeTracker_Import
	@DataSource = 'DepositInfo'
	,@CalledTime = '2020-08-31'
	,@KeyValue = '0'
	,@IsReset = 1
go

-- 5. TpBetRecord
exec dbo.Task_API_TimeTracker_Import
	@DataSource = 'TpBetRecord'
	,@CalledTime = '2020-01-01'
	,@KeyValue = ''
	,@IsReset = 1
go

-- 6. TpTransferInfo
exec dbo.Task_API_TimeTracker_Import
	@DataSource = 'TpTransferInfo'
	,@CalledTime = '2020-08-31'
	,@KeyValue = '0'
	,@IsReset = 1
go

-- 7. WithdrawalInfo
exec dbo.Task_API_TimeTracker_Import
	@DataSource = 'WithdrawalInfo'
	,@CalledTime = '2020-08-31'
	,@KeyValue = '0'
	,@IsReset = 1
go