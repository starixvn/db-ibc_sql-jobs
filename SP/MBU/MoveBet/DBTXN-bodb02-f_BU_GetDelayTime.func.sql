SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE FUNCTION [dbo].[f_BU_GetDelayTime]
(
	@KeyId VARCHAR(50)
) 
/*
	Created:
	Task: Delay time list
	DB: DBTXN/BODB02
	Revisions:
		- 20190131@Patrick: Add more key [RedmineID: #108581]
		- 20221215@Patrick: Balance-Up support transfer 247 [RedmineID: #173554]

*/
RETURNS VARCHAR(50)
AS
BEGIN
	RETURN (SELECT CASE WHEN @KeyId = 'Key1' THEN '00:00:00:700'
						WHEN @KeyId = 'Key2' THEN '00:00:00:900'
						WHEN @KeyId = 'Key3' THEN '00:00:01:000'
						WHEN @KeyId = 'Key4' THEN '00:00:01:000'
						WHEN @KeyId = 'Key5' THEN '00:00:01:000'
						WHEN @KeyId = 'Key6' THEN '00:00:00:020' --for pub SP ExcepRep in MB
						WHEN @KeyId = 'Key7' THEN '00:00:00:030'
						WHEN @KeyId = 'Key8' THEN '00:00:00:100'
						WHEN @KeyId = 'Key9' THEN '00:00:00:120'
						WHEN @KeyId = 'Key10' THEN '00:00:00:010'
						WHEN @KeyId = 'Key11' THEN '00:00:00:800' --for pub bet in MB
						WHEN @KeyId = 'IP2Country' THEN '00:00:00.030'
						WHEN @KeyId = 'FriRoutine' THEN '00:00:00.180'
						WHEN @KeyId = 'BeforeMB' THEN '00:05:00:000'
						WHEN @KeyId = 'AfterUpdMBD' THEN '00:05:00:000'
						WHEN @KeyId = 'BeforeBU' THEN '00:05:00:000'
						WHEN @KeyId = 'AfterUpdBUD' THEN '00:05:00:000'
						WHEN @KeyId = 'DeleteBU' THEN '00:00:00:280'
						ELSE '00:00:00:280' END)
END
GO
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="1" isNested="0"></info>*/