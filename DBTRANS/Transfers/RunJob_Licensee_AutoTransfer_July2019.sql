--DBTXN.bodb02
----------------------------------------
DECLARE @RC int
DECLARE @MoveBetsDay smalldatetime
DECLARE @TransferMonthDate smalldatetime
DECLARE @ErrCode int
DECLARE @ErrMsg varchar(4000)

-- TODO: Set parameter values here.
SELECT @MoveBetsDay = MAX(winlostdate)
FROM dbo.bettrans14 WITH(NOLOCK)

EXECUTE @RC = [bodb02].[dbo].[Acc_LicenseeTransfer_Job] 
   @MoveBetsDay
  ,@TransferMonthDate
  ,@ErrCode OUTPUT
  ,@ErrMsg OUTPUT
  
SELECT @ErrCode, @ErrMsg
GO