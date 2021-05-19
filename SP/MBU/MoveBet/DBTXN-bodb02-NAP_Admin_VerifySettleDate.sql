/*<info serverAlias="DBTXN-bodb02" executers="dot_member,bodbAdminNet,dot_intg" viewers="" isFunction="0" isNested="1"></info>*/
CREATE PROCEDURE dbo.NAP_Admin_VerifySettleDate
	@Winlostdate SMALLDATETIME,
	@IsAllow BIT = 0 OUTPUT,
	@BeingMovebetDate SMALLDATETIME = NULL OUTPUT
AS
/*
	Created: 20210331@Patrick
	Task: Only allow settling action if winlostdate greater than @BeingMovebetDate
	DB: DBTXN/bodb02
	Params:
		@AllowSettled: 0: not allow settle, 1: allow settle
		@BeingMovebetDate: 
			+ NULL: dont have movebet date comming up or being.
			+ NOT NULL: movebet date comming up or being.
		
	Revisions:   
		- 20210323@Patrick: Initial [Redmine: #149927]
*/
BEGIN
	SET NOCOUNT ON
	SELECT @BeingMovebetDate = CONVERT(SMALLDATETIME, VValue)
	FROM dbo.SystemSettings
	WHERE VName = 'BeingMovebetDate'

	IF @BeingMovebetDate IS NULL
	BEGIN
		SET @IsAllow = 1
		RETURN
	END

	IF @winlostdate > @BeingMovebetDate
		SET @IsAllow = 1
	ELSE
		SET @IsAllow = 0
END
GO
