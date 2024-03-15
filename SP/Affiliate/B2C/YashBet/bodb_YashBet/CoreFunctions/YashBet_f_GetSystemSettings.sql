/*<info serverAlias="DBYASHBET-bodb_YashBet" executers="wsv_lap" isFunction="1" isNested="1"></info>*/
USE bodb_YashBet
GO

ALTER FUNCTION [dbo].[YashBet_f_GetSystemSettings]
(
	@SName VARCHAR(50)
)
RETURNS VARCHAR(200)
AS

/*
	Created: 20240115@Sally
	DB: DBYASHBET-bodb_YashBet
	Task: Core function get data in SystemSettings

	Revisions:
		- 20240115@Sally: Initialize function [RedmineID: #198909]

*/

BEGIN
	DECLARE @SValue VARCHAR(200) = ''
	SELECT  @SValue = SValue 
	FROM dbo.SystemSettings WITH (NOLOCK) 
	WHERE SName = @SName
	
	RETURN @SValue
END
GO