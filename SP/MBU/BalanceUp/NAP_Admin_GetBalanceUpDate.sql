/*<info serverAlias="DBTXN-bodb02,DBACC-bodb02,DBAGE-bodb02,DBBAH-bodb02,DBTP-bodb02,DBBAL-bodb02" executers="dot_member,bodbAdminNet,bodbExtAccNet,bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0" isNested="1"></info>*/
CREATE PROCEDURE [dbo].[NAP_Admin_GetBalanceUpDate]
	@BalanceUpDate SMALLDATETIME OUTPUT
AS
/*
	Created: 20220602@Patrick
	Task: Get current balanceUp date
	DB: DBTXN-bodb02,DBACC-bodb02,DBAGE-bodb02,DBBAH-bodb02,DBTP-bodb02,DBBAL-bodb02
	Params:
		@BalanceUpDate: current BalanceUp date
		
	Revisions:   
		- 20220602@Patrick: Initial [Redmine: #173554]
*/
BEGIN
	SET NOCOUNT ON
	SELECT @BalanceUpDate = CONVERT(SMALLDATETIME, VValue)
	FROM dbo.MBUSettings
	WHERE VName = 'BalanceUpDate'

	IF @BalanceUpDate IS NULL
	BEGIN
		--throw exception to let APP have a error 
		RAISERROR('BalanceUpDate value is null. Please contact DBA for support.', 16, 1)
		RETURN
	END
END
