/*<info serverAlias="DBTXN-bodb02,DBACC-bodb02,DBAGE-bodb02,DBBOF-bodb02,DBBAH-bodb02,DBTP-bodb02,DBBAL-bodb02" executers="dot_member,bodbAdminNet,bodbExtAccNet,bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE dbo.NAP_Admin_GetMovebetDate
	@MovebetDate SMALLDATETIME OUTPUT
AS
/*
	Created: 20210331@Patrick
	Task: Get current movebet date
	DB: DBTXN-bodb02,DBACC-bodb02,DBAGE-bodb02,DBBOF-bodb02,DBBAH-bodb02,DBTP-bodb02,DBBAL-bodb02
	Params:
		@MovebetDate: current movebet date
		
	Revisions:   
		- 20210323@Patrick: Initial [Redmine: #149927]
		- 20210816@Sophia: add DBBAL [Redmine: #154300]
*/
BEGIN
	SET NOCOUNT ON
	SELECT @MovebetDate = CONVERT(SMALLDATETIME, VValue)
	FROM dbo.SystemSettings
	WHERE VName = 'MovebetDate'

	IF @MovebetDate IS NULL
	BEGIN
		SELECT @MovebetDate = MAX(eventdate) 
		FROM dbo.match14 WITH(NOLOCK)
	END
END
GO
