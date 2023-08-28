/*<info serverAlias="DBTXN-custdb,DBBOF-bodb02,DBACC-bodb02,DBTP-bodb02" executers="repl_ap" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Repl_SetLastVersion]
	@group int,
	@name varchar(100),
	@last_datetime datetime2 = '2000-1-1 00:00:00',
	@last_timestamp bigint = 0
AS
/*
	Task: In-House
	Revision:
		-- 20230817@Patrick: Add more dbtxn.custdb [Redmine:#189389]
*/
BEGIN
	SET NOCOUNT ON;
	UPDATE [dbo].[RepInfo] SET
		[last_datetime] = @last_datetime, [last_timestamp] = @last_timestamp
		WHERE [group] = @group AND [name] = @name;
END
