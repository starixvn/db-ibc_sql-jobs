/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="" viewers="" isFunction="1" isNested="0"></info>*/
ALTER FUNCTION [dbo].[f_Archive_CustomerLog_GetDelayTime]
(       
	@KeyId VARCHAR(50)       
) 
/*
	Created:
	Task: Delay time list
	DB: DBLOG/bodb_CustomerLog
	Revisions:

*/
RETURNS VARCHAR(50)      
AS
BEGIN
	RETURN (SELECT CASE WHEN @KeyId = 'Key1' THEN '00:00:00:010'
						WHEN @KeyId = 'Key2' THEN '00:00:00:020'
						WHEN @KeyId = 'Key3' THEN '00:00:00:050'
						WHEN @KeyId = 'Key4' THEN '00:00:00:100'
						WHEN @KeyId = 'Key5' THEN '00:00:01:000'
						WHEN @KeyId = 'Key6' THEN '00:00:01:500'
						ELSE '00:00:00:280' END)
END
