/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_UpdClearBalanceList]
(
	@mode TINYINT = 1,
	@custid INT = 0,
	@status VARCHAR(20) = NULL,
	@LastTransfer DATETIME = NULL,
	@msg NVARCHAR(1000) = NULL,
	@CustIDList VARCHAR(MAX) = NULL,
	@IsTransferring BIT = 1
	
)
AS
/*
	Created: 20150617@DAniel
	DB: DBCUST/custDB
	Task: Update Table Acc_ClearBalanceList in DBCUST.custDB
	
	Revisions: 
		- 20150617@Daniel: Created for nested Sp call in Task_ClearBalanceAllDownline - separating custDB to new server DBCUST [Redmine:#36216]  
		- 20200727@Sophia: prevent duplicated transfer [Redmine: #137141]
		
	Param explain:
	   * @Mode = 0: Update status 'waiting' for customers having lastTransfer date before today, params are not used
	   * @Mode = 1: Update data for a specific customer with param below
	    + @custid: Specify custid to update
	    + @status: Set status's value, skip update if value is NULL
	    + @LastTransfer: Set LastTransfer's value, skip update if value is NULL
	    + @msg: Set msg's value, skip update if value is NULL	
	   * @Mode = 2: Update flag for a specific customer list with param @CustIDs
 
*/

SET NOCOUNT ON
IF @mode = 0
BEGIN
	 
    DECLARE @Today DATETIME
    SET @today = DATEADD(dd, DATEDIFF(d, 0, CURRENT_TIMESTAMP), 0)

    UPDATE dbo.Acc_ClearBalanceList WITH(ROWLOCK)
    SET [status] = 'waiting'
    WHERE LastTransfer < @today AND [status] <> 'waiting'
END
ELSE IF @mode = 1
BEGIN
    IF @custid = 0 OR (@status IS NULL AND @LastTransfer IS NULL AND @msg IS NULL) RETURN
	
    UPDATE dbo.Acc_ClearBalanceList WITH(ROWLOCK)
    SET 
       [status] = ISNULL(@status, [status]),
       LastTransfer = ISNULL(@LastTransfer, LastTransfer),
       msg = ISNULL(@msg, msg),
	   IsTransferring = @IsTransferring
    WHERE custid = @CustID
END
ELSE IF @mode = 2
BEGIN
    IF @CustIDList = NULL RETURN
	
    UPDATE 	dbo.Acc_ClearBalanceList WITH(ROWLOCK)
    SET  	IsTransferring = @IsTransferring
    WHERE 	Custid IN (Select Val from [f_SplitString](@CustIDList, ','))
	OPTION (MAXRECURSION 0)
END
 

GO