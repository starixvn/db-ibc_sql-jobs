/*<info serverAlias="DBLOG-bodb_CustomerLog"></info>*/
/*
	Created: 20230511@Bobby
	Task: 182071 - Alpha - AutoJob ClearBalance
	DB: DBLOG.bodb_CustomerLog
	Remark: DBLOG
*/
-- DBLOG
use bodb_CustomerLog;
GO
insert into [LogAction] (ActionID,ActionTypeID,	SPName,	ActionNameEN, ActionNameTH, ActionNameCN, ActionNameCS, ActionNameCH)
VALUES
(95086,	4,	'Age_ClearBalanceCust_SettingUpdate',
	N'Enable/Disable Auto Transfer',
	N'เปิด/ปิดการโอนอัตโนมัติ',
	N'开启/禁用自动转账',
	N'开启/禁用自动转账',
	N'開啟/禁用自動轉賬'
);
