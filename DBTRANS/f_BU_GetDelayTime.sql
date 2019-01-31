/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="1" isNested="0"></info>*/
ALTER FUNCTION [dbo].[f_BU_GetDelayTime]
(       
	@KeyId VARCHAR(50)       
) 
RETURNS VARCHAR(50)      
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
						WHEN @KeyId = 'IP2Country' THEN '00:00:00.030'
						WHEN @KeyId = 'FriRoutine' THEN '00:00:00.180'
						ELSE '00:00:00:280' END)
END
GO