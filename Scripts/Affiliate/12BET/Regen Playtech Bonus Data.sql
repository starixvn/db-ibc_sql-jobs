/*<info serverAlias="DBAFF12BET-Affiliate_12BET" isFunction="0" isNested="1"></info>*/
use Affiliate_12BET
go

/*
	Created: 20210127@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Playtech bonus is reset due to Bonus on Bettrans - Regen data from 2021-01-01
*/

-- 625 rows
update dbo.APIProduct_ImportQueue with (rowlock)
set FinishedTime = null
where WinlostDate >= '2021-01-01'
	and ProductId = 3

-- 1 row
update dbo.APIProductSettings with (rowlock)
set SettingValue = '4722957'
where SettingName = 'LastQueueId'
	and ProductId = 3