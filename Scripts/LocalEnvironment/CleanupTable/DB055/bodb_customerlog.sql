USE bodb_CustomerLog
GO

set nocount on

TRUNCATE TABLE UserLog_Transfer
TRUNCATE TABLE UserLog_UserControl
TRUNCATE TABLE UserLog_Settle
TRUNCATE TABLE UserLog_Login
TRUNCATE TABLE UserLog_RunSP
TRUNCATE TABLE SettlementLog
TRUNCATE TABLE Age_ClearBalanceCust_ProcessHistory
DECLARE @batchNo INT = 10000DECLARE @todate SMALLDATETIME = DATEADD(MONTH, -3, GETDATE())-- AppLog_Logwhile (1=1)begin	DELETE top (@batchNo) FROM AppLog_Log WHERE Timestamp < @todate	if @@rowcount <> @batchNo		breakend