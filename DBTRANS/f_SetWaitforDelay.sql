/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="1"></info>*/
ALTER FUNCTION [dbo].[f_SetWaitforDelay] (
	@ConfigName	VARCHAR(100)
)
RETURNS VARCHAR(100)
/* 
	Created:20220706@Max
    Task: Bettrans Running DB for WC2022
    DB: dbtrans/bodb02 -
    
    
	Revisions:
		- 20220706@Max: Create function - [Redmine: #172094]
   
	Notes:
		DECLARE @Delay VARCHAR(100) = ''
		SET @Delay = dbo.f_SetWaitforDelay () 
		WAITFOR DELAY @Delay

*/
AS
BEGIN
	DECLARE @WaitforDelay VARCHAR(50)
	
	IF @ConfigName IS NULL
	BEGIN
		SET @WaitforDelay = '00:00:05:000'
	END
	IF @ConfigName = 'NegativeBalance'
	BEGIN
		SET @WaitforDelay = '00:00:05:000'
	END
	ELSE IF @ConfigName = 'Exchange'
	BEGIN
		SET @WaitforDelay = '00:00:05:000'
	END

    RETURN @WaitforDelay
END
GO


