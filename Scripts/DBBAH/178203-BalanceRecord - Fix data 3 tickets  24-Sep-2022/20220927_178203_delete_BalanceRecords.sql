/*<info serverAlias="DBBAH-balanceRecord" executers="" isFunction="0"></info>*/
/*
    Created: 20220927@Max
	Task: BalanceRecord - Fixing data for 3 tickets in data patch 24-Sep-2022 [Redmine:#178203]
	DB:DBBAH/balanceRecord

*/
USE balanceRecord
GO
---------------------------------------------------------------------------------
DELETE bk
FROM dbo.BalanceRecord_bk bk
WHERE bk.RowID IN (
	60909751450, 60909961037 --Transid: 31000034560442368 
	, 60909751449, 60909961036 --Transid: 30997783997579265  
	, 60909751451, 60909961038 --Transid: 31000309438349317  
)



