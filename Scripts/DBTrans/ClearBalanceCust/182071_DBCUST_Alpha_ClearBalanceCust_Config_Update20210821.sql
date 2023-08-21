/*<info serverAlias="DBCUST-CustDB"></info>*/
/*
	Created: 20230511@Bobby
	Task: 182071 - Alpha - AutoJob ClearBalance
	DB: DBCUST.CustDB
	Remark: Run on DBCUST
*/

--DBCUST
USE CustDB;
--MsgError
UPDATE MsgError WITH(ROWLOCK, UPDLOCK)
SET MsgNameEN = N'The Auto Transfer has been enabled for this account. However, this process is running, and the account will be queued for Auto Transfer at the next scheduled time based on its transfer conditions.',
	MsgNameTH =	N'การโอนอัตโนมัติสำหรับบัญชีนี้ได้เปิดใช้งานแล้ว อย่างไรก็ตาม ระบบกำลังดำเนินการอยู่ในขณะนี้ บัญชีนี้จะเริ่มการโอนอัตโนมัติในเวลาที่กำหนดครั้งถัดไปตามเงื่อนไขการโอน',
	MsgNameCS =	N'这个账号已启用自动转账。但是，自动转账的过程正在进行，所以该账号将根据您的账号转账设定在队列中等待下一个预定时间自动转账。',
	MsgNameCT =	N'這個賬號已啟用自動轉賬。但是，自動轉賬的過程正在進行，所以該賬號將根據您的賬號轉賬設定在隊列中等待下一個預定時間自動轉賬。',
	MsgNameCN =	N'這個賬號已啟用自動轉賬。但是，自動轉賬的過程正在進行，所以該賬號將根據您的賬號轉賬設定在隊列中等待下一個預定時間自動轉賬。'
WHERE MsgID = 50018
GO

UPDATE MsgError WITH(ROWLOCK, UPDLOCK)
SET MsgNameEN = N'Auto Transfer process status has changed. Please refresh the page.', 
	MsgNameTH =	N'สถานะของระบบโอนอัตโนมัติมีการเปลี่ยนแปลง โปรดทำการรีเฟรชหน้านี้',
	MsgNameCS =	N'自动转账进行状态已更改。 请刷新页面。',
	MsgNameCT =	N'自動轉賬進行狀態已更改。請刷新頁面。',
	MsgNameCN =	N'自動轉賬進行狀態已更改。請刷新頁面。'
WHERE MsgID = 50032
GO