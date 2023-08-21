/*<info serverAlias="DBTXN-custdb" executers="repl_ap" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Repl_TryLockWorker]
	@group int,
	@name varchar(100),
	@worker varchar(100),
	@duration int = 30000	-- in millision
AS
-- 20230817@Patrick: Add more dbtxn.custdb [Redmine:#189389]

BEGIN
	SET NOCOUNT ON;

	BEGIN TRANSACTION;

	DECLARE @current_worker varchar(100);
	DECLARE @current_expiry datetime2;
	SELECT @current_worker = [worker], @current_expiry = [worker_expiry]
	FROM [dbo].[RepInfo] WHERE [group] = @group AND [name] = @name;

	IF @current_worker <> @worker AND (@current_expiry IS NOT NULL AND @current_expiry >= GETDATE())
		BEGIN
			SELECT 0 AS [status], 0 AS [switched], @current_worker AS [worker]
		END
	ELSE
		BEGIN
			UPDATE [dbo].[RepInfo]
				SET [worker] = @worker, [worker_expiry] = DATEADD(ms, @duration, GETDATE())
				WHERE [group] = @group AND [name] = @name
			SELECT
				1 AS [status],
				CASE WHEN @current_worker = @worker THEN 0 ELSE 1 END AS [switched],
				@worker AS [worker]
		END;

	COMMIT;
END