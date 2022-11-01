/*<info serverAlias="DBBAH-bodb02" executers="" viewers="" isFunction="1"></info>*/
ALTER FUNCTION [dbo].[f_Job_SetWaitforDelay] 
(
  @KeyId VARCHAR(50)
)
RETURNS VARCHAR(50)
/* 
	Created by: Max
	Date : 20221101
	Task: NAP/LAP - Wrong balance value shown for functions using BalanceRecord table [Redmine: #179754]
	DB: DBBAH/bodb02
	
	Revisions: 
		- 20221101@Max: Create [Redmine: #179754]
	
	Param's explanation:	
   
	Notes:
		DECLARE @Delay VARCHAR(100) = ''
		SET @Delay = dbo.f_Job_SetWaitforDelay ('Key1') 
		WAITFOR DELAY @Delay

*/
AS
BEGIN
    RETURN (SELECT CASE WHEN @KeyId = 'Key1' THEN '00:00:00:700'
        WHEN @KeyId = 'Key2' THEN '00:00:00:900'
        WHEN @KeyId = 'Key3' THEN '00:00:01:000'
        WHEN @KeyId = 'Key4' THEN '00:00:01:000'
        WHEN @KeyId = 'Key5' THEN '00:00:01:000'
        WHEN @KeyId = 'Key6' THEN '00:00:00:020' 
        WHEN @KeyId = 'Key7' THEN '00:00:00:030'
        WHEN @KeyId = 'Key8' THEN '00:00:00:100'
        WHEN @KeyId = 'Key9' THEN '00:00:00:120'
        WHEN @KeyId = 'Key10' THEN '00:00:00:010'
        WHEN @KeyId = 'Key11' THEN '00:00:00:800' 
        ELSE '00:00:00:280' END)
END
GO

