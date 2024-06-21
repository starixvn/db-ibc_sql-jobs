/*<info serverAlias="DBAGE-bodb02" executers="" isFunction="1" isNested="0"></info>*/
ALTER function [dbo].[f_DBA_GetDelayTime]
(
	@KeyId varchar(50)
) 
/*  Created: Patrick@20210801
	Task: Get waifor delay time
	DB: DBAGE-bodb02
	Revisions:  
		- 20210801@Patrick: Implement settlement can run parallels [Redmine:#159486]
		- 20240621@July: Adjust wait for delay 3s -> 10ms - [Redmine:#206915]

*/
returns varchar(50)
as
begin
	return (select case when @KeyId = 'TO_Control' then '00:00:00:010' -- waitfor on TO_Control
						else '00:00:00:100' end)
end
GO
