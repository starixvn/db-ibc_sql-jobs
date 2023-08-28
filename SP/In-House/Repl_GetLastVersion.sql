/*<info serverAlias="DBTXN-custdb,DBBOF-bodb02,DBACC-bodb02,DBTP-bodb02" executers="repl_ap" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Repl_GetLastVersion]
	@group int,
	@name varchar(100)
AS
/*
	Task: In-House
	Revision:
		-- 20230817@Patrick: Add more dbtxn.custdb [Redmine:#189389]
*/
BEGIN
	SET NOCOUNT ON;
	SELECT [last_datetime], [last_timestamp]
		FROM [dbo].[RepInfo] WHERE [group] = @group AND [name] = @name;
END
