/*<info serverAlias="DBHIS-bodb_CustHistory" executers="" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Task_DeleteHistoryLogData]
AS
/*
	Created: 
	Task: delete old data in history tables
	DB: DBHIS/bodb_CustHistory
	
	Revisions:
		- 20130523@Lukas: add more tables that need to delete old data
		- 20170530@Lukas: extend retention from 60 to 300 days
		- 20170913@Lukas: extend retention from 300 days to 24 months
		- 20191002@Elodie: Add more tables of DCS and CN88 that need to delete old data 
		                   Remove P2PGameSetting_history, P2PGroupComm_history table
*/
BEGIN
	DECLARE @LastKeepDate datetime
	--SELECT @LastKeepDate = dateadd(d, -300, getdate())
	SELECT @LastKeepDate = dateadd(month, -24, getdate())

	SET NOCOUNT ON
	-------------------custSetting_history-------------------
	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.custSetting_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.custSetting3rd_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	-------------------custOverride_history-------------------
	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.custOverride_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.custOverride3rd_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	-------------------DCS credit setting-------------------
	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.CustBetSetting3rd_Agent_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.CustBetSetting3rd_Member_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.CustDiscount3rd_Agent_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.CustDiscount3rd_Member_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.CustProductStatus_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.CustPTSetting3rd_Agent_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.CustPTSetting3rd_Member_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.CustPTGroupSetting3rd_Member_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.CustSettingMode3rd_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.CustStakeLevel_Agent_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.CustStakeLevel_Member_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.CustWinLossLimit_Agent_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.CustWinLossLimit_Member_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	-------------------DCS Deposit setting-------------------
	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.Dep_CustBetSetting_Agent_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.Dep_CustBetSetting_Member_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.Dep_CustDiscountGroupSetting_Member_History WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.Dep_CustDiscountSetting_Agent_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.Dep_CustDiscountSetting_Member_History WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.Dep_CustProductStatus_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.Dep_CustPTSetting_Agent_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.Dep_CustPTSetting_Member_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.Dep_CustPTGroupSetting_Member_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.Dep_CustSettingMode_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.Dep_CustStakeLevel_Agent_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.Dep_CustStakeLevel_Member_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END
	-------------------CN88 setting-------------------
	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.CS_CustBetSetting_Agent_History WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.CS_CustBetSetting_Member_History WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.CS_CustDiscount_Agent_History WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.CS_CustDiscount_Member_History WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.CS_CustGroupDiscount_Member_History WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.CS_CustomerStatus_History WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.CS_CustPTGroupSetting_Member_History WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.CS_CustPTSetting_Agent_History WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.CS_CustSettingMode_History WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	-------------------CustInfo_history-------------------
	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.CustInfo_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	-------------------Live Casino setting history-------------------
	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.custsettingGame_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.custoverrideGame_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END
	
	-------------------deposit customer setting history-------------------
	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.Dep_custsetting_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.Dep_custsetting3rd_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END
	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.Dep_CustSettingGame_History WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END
	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.CustGameType_History WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END
	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.CustWinLimit_History WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END
	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.CustVirtualSetting_History WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END
	SET NOCOUNT OFF

END
