/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_CleanUp_CustID_EqualToZero_Job]
AS
/*
Created by: 20220817@Victoria
Task: Clean Up custid equal to zero
DB: DBTXN-bodb02
Revisions:
	- 20220817@Victoria: Deleting records with custid equal to zero for the following tables: 
							bettrans/bettransLC/bettransRnG/Transfer/TransferInfo/Transfer_Coll [Redmine:#176760]
	
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @MovebetDate SMALLDATETIME = NULL
	EXEC dbo.NAP_Admin_GetMovebetDate	@MovebetDate = @MovebetDate OUTPUT
	--SELECT @MovebetDate

	DELETE b
	FROM dbo.bettransLC b WITH(ROWLOCK, UPDLOCK)
	WHERE b.winlostdate = @MovebetDate AND b.custid = 0

	DELETE b
	FROM dbo.bettrans b WITH(ROWLOCK, UPDLOCK)
	WHERE b.winlostdate = @MovebetDate AND b.custid = 0

	DELETE b
	FROM dbo.bettransRnG b WITH(ROWLOCK, UPDLOCK)
	WHERE b.winlostdate = @MovebetDate AND b.custid = 0

	DELETE binfo
	FROM dbo.TransferInfo binfo WITH(ROWLOCK, UPDLOCK)
		INNER JOIN dbo.Transfer b WITH(NOLOCK) ON b.TransId = binfo.TransId
	WHERE b.winlostdate = @MovebetDate AND b.custid = 0

	DELETE b
	FROM dbo.Transfer b WITH(ROWLOCK, UPDLOCK)
	WHERE b.winlostdate = @MovebetDate AND b.custid = 0

	DELETE b
	FROM dbo.Transfer_Coll b WITH(ROWLOCK, UPDLOCK)
	WHERE b.winlostdate = @MovebetDate AND b.custid = 0

END

