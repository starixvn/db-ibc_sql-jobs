
/*<info serverAlias="DBTXN-custdb" executers="repl_ap" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Repl_GetInfo]
	@group int
AS
/*
	Task: In-House
	Revision:
		-- 20220606@Chunyu: For in-house replication use
		-- 20221222@Chunyu: Rename cache_size to batch_size
		-- 20230817@Patrick: Add more dbtxn.custdb [Redmine:#189389]
*/
BEGIN
	SET NOCOUNT ON;
	SELECT [name], [active], [version_key], [version_type], [unique_key], [get_sp], [put_sp], [interval], [back_fix], [delayed_fix], [worker], [worker_expiry], [batch_size], [last_datetime], [last_timestamp]
		FROM [dbo].[RepInfo] WITH(NOLOCK) 
		WHERE [group] = @group;
END