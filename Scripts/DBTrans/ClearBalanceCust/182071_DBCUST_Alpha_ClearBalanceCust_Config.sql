/*<info serverAlias="DBCUST-CustDB"></info>*/
/*
	Created: 20230511@Bobby
	Task: 182071 - Alpha - AutoJob ClearBalance
	DB: DBCUST.CustDB
	Remark: Run on DBCUST
*/

--DBCUST
USE CustDB;
GO
CREATE TABLE [dbo].[Age_ClearBalanceCust_Setting](
	[FromCustID] [int] NOT NULL,
	[ToCustID] [int] NOT NULL,
	[CreatedDate] [datetime] NULL,
	[EffectiveDate] [datetime] NULL,
	[Creator] [int] NULL,
	CONSTRAINT [PK_Age_ClearBalanceCust_Setting] PRIMARY KEY CLUSTERED 
	(
		[FromCustID] ASC,
		[ToCustID] ASC
	)
) ON [table_customer]
GO


--MsgError
insert into MsgError(MsgID,MsgGroupId,MsgNameEN,MsgNameTH,MsgNameCS,MsgNameCT,MsgNameCN,IsActive)
values
(50018, 6, N'Auto Transfer process is in progress. This account will be auto-transferred at the next scheduled time according to your transfer condition.',
			N'ระบบโอนอัตโนมัติกำลังดำเนินการอยู่ บัญชีนี้จะเริ่มโอนอัตโนมัติในรอบการทำงานครั้งถัดไปตามเงื่อนไขที่คุณกำหนดไว้',
			N'正在进行自动转账的过程。此账号将会根据您的账号的转账设定在下一个预定时间自动转账。',
			N'正在進行自動轉賬的過程。此賬號將會根據您的賬號的轉賬設定在下一個預定時間自動轉賬。',
			N'正在進行自動轉賬的過程。此賬號將會根據您的賬號的轉賬設定在下一個預定時間自動轉賬。',
			1),
(50019, 6,	N'You cannot disable Auto Transfer for this account because the Auto Transfer process is in progress. Please try again after the process has been completed.', 
			N'ขณะนี้ระบบโอนอัตโนมัติกำลังดำเนินการอยู่ จึงไม่สามารถปิดการใช้งานสำหรับบัญชีนี้ได้ กรุณาลองใหม่เมื่อระบบทำงานเสร็จ',
			N'您无法禁用此账号的自动转账功能，因为自动转账正在进行中。请等进行完毕之后再重试。',
			N'您無法禁用此賬號的自動轉賬功能，因為自動轉賬正在進行中。請等進行完畢之後再重試。',
			N'您無法禁用此賬號的自動轉賬功能，因為自動轉賬正在進行中。請等進行完畢之後再重試。',
			1),
(50020, 6,	'You cannot perform transfers for this account because the Auto Transfer process is in progress. Please try again after the process has been completed.',
			N'ขณะนี้ระบบโอนอัตโนมัติกำลังดำเนินการอยู่ จึงไม่สามารถทำการโอนสำหรับบัญชีนี้ได้ กรุณาลองใหม่เมื่อระบบทำงานเสร็จ',
			N'您无法为此账号执行转账因为正在进行自动转账的过程。请等进行完毕之后再重试。',
			N'您無法為此賬號執行轉賬因為正在進行自動轉賬的過程。請等進行完畢之後再重試。',
			N'您無法為此賬號執行轉賬因為正在進行自動轉賬的過程。請等進行完畢之後再重試。',
			1),
(50021, 6,	N'Auto Transfer process is in progress. These accounts will be auto-transferred at the next scheduled time according to your transfer condition.', 
			N'ระบบโอนอัตโนมัติกำลังดำเนินการอยู่ บัญชีเหล่านี้จะเริ่มโอนอัตโนมัติในรอบการทำงานครั้งถัดไปตามเงื่อนไขที่คุณกำหนดไว้',
			N'正在进行自动转账的过程。这些账号将会根据您的账号的转账设定在下一个预定时间自动转账。',
			N'正在進行自動轉賬的過程。這些賬號將會根據您的賬號的轉賬設定在下一個預定時間自動轉賬。。',
			N'正在進行自動轉賬的過程。這些賬號將會根據您的賬號的轉賬設定在下一個預定時間自動轉賬。。',
			1),
(50022, 6,	N'You cannot disable Auto Transfer for these accounts because the Auto Transfer process is in progress. Please try again after the process has been completed.', 
			N'ขณะนี้ระบบโอนอัตโนมัติกำลังดำเนินการอยู่ จึงไม่สามารถปิดการใช้งานสำหรับบัญชีเหล่านี้ได้ กรุณาลองใหม่เมื่อระบบทำงานเสร็จ',
			N'您无法禁用這些账号的自动转账功能，因为自动转账正在进行中。请等进行完毕之后再重试。',
			N'您無法禁用這些賬號的自動轉賬功能，因為自動轉賬正在進行中。請等進行完畢之後再重試。。',
			N'您無法禁用這些賬號的自動轉賬功能，因為自動轉賬正在進行中。請等進行完畢之後再重試。。',
			1),
(50023, 6,	N'Due to changes in transfer conditions.', 
			N'เนื่องจากมีการเปลี่ยนแปลงเงื่อนไขการโอน',
			N'由于转账发生变更',
			N'由於轉賬發生變更',
			N'由於轉賬發生變更',
			1),
(50024, 6,	N'Due to partial maintenance on the Transfer function, ongoing until <TO_TIME> (GMT+8).', 
			N'เนื่องจากการปิดปรับปรุงบางส่วนของฟังก์ชั่นการโอน ซึ่งจะดำเนินการจนถึง <TO_TIME> (GMT+8)',
			N'由于转账功能进行部分维护，一直持续到 <TO_TIME> (GMT+8)。',
			N'由於轉賬功能進行部分維護，一直持續到 <TO_TIME> (GMT+8)。',
			N'由於轉賬功能進行部分維護，一直持續到 <TO_TIME> (GMT+8)。',
			1),
(50025, 6,	N'Due to insufficient balance.', 
			N'เนื่องจากยอดเงินไม่เพียงพอ',
			N'由于余额不足',
			N'由於餘額不足',
			N'由於餘額不足',
			1),
(50026, 6,	N'Due to existing transfer.', 
			N'เนื่องจากมีการโอนอยู่แล้ว',
			N'由于现有转账导致',
			N'由於現有轉賬導致',
			N'由於現有轉賬導致',
			1),
(50027, 6,	N'Due to unexpected issues.', 
			N'เนื่องจากเกิดปัญหาที่ไม่คาดคิด',
			N'由于意想不到的事件',
			N'由於意想不到的事件',
			N'由於意想不到的事件',
			1),
(50028, 6,	N'Auto Transfer process status has changed to Processing. Please refresh the page.', 
			N'สถานะระบบโอนอัตโนมัติได้เปลี่ยนเป็น กำลังดำเนินการ โปรดทำการรีเฟรชหน้านี้',
			N'自动转账流程状态已更改为进行中。请刷新页面。',
			N'自動轉賬流程狀態已更改為進行中。請刷新頁面。',
			N'自動轉賬流程狀態已更改為進行中。請刷新頁面。',
			1),
(50029, 6,	N'Auto Transfer process status has changed to Completed. Please refresh the page.', 
			N'สถานะระบบโอนอัตโนมัติได้เปลี่ยนเป็น ทำงานเสร็จ โปรดทำการรีเฟรชหน้านี้',
			N'自动转账流程状态已更改为完成。请刷新页面。',
			N'自動轉賬流程狀態已更改為完成。請刷新頁面。',
			N'自動轉賬流程狀態已更改為完成。請刷新頁面。',
			1),
(50030, 6,	N'Auto Transfer process status has changed to Failed. Please refresh the page.', 
			N'สถานะของระบบโอนอัตโนมัติได้เปลี่ยนเป็น ล้มเหลว โปรดทำการรีเฟรชหน้านี้',
			N'自动转账进行状态已更改为失败。 请刷新页面。',
			N'自動轉賬進行狀態已更改為失敗。請刷新頁面。',
			N'自動轉賬進行狀態已更改為失敗。請刷新頁面。',
			1),
(50031, 6,	N'Auto Transfer process status has changed to Pending. Please refresh the page.', 
			N'สถานะของระบบโอนอัตโนมัติได้เปลี่ยนเป็น รอดำเนินการ โปรดทำการรีเฟรชหน้านี้',
			N'自动转账进行状态已更改为待处理。 请刷新页面。',
			N'自動轉賬進行狀態已更改為待處理。請刷新頁面。',
			N'自動轉賬進行狀態已更改為待處理。請刷新頁面。',
			1),
(50032, 6,	N'Auto Transfer process status has changed. Please refresh the page.', 
			N'สถานะของระบบโอนอัตโนมัติมีการเปลี่ยนแปลง โปรดทำการรีเฟรชหน้านี้',
			N'自动转账进行状态已更改。 请刷新页面。',
			N'自動轉賬進行狀態已更改為待處理。請刷新頁面。',
			N'自動轉賬進行狀態已更改為待處理。請刷新頁面。',
			1)
GO