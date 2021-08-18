/*<info serverAlias="DB042-ServiceBrokerDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_SSB_Remove_Logs]
AS
/*
	20180621 @ Patrick
	DB: DB042.bodb02
	Revision: 
		-20191127@Patrick: Setup sync status ticket on DB052 -> DB054 - [Redmine: #124482]
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @datetimeTmp DATETIME 
	SET @datetimeTmp = DATEADD(HOUR, -2, GETDATE())

	--for case retry 5 times for the same message_body
	DECLARE @__archive TABLE (message_body NVARCHAR(MAX))
	INSERT INTO @__archive(message_body)
	SELECT message_body
	FROM sb.[SettedTicketLogs] WITH(NOLOCK)
	WHERE creationTime > @datetimeTmp
	GROUP BY message_body
	HAVING COUNT(1) > 5

	UPDATE t
	SET message_error = '', try_count = 5
	FROM sb.[SettedTicketLogs] t WITH(ROWLOCK, UPDLOCK)
	WHERE creationTime > @datetimeTmp
		AND message_body IN (SELECT tt.message_body FROM @__archive tt)
		
	DELETE FROM sb.[SettedTicketLogs] WITH(ROWLOCK)
	WHERE creationTime < DATEADD(DAY, -3, GETDATE())
		AND (message_error IS NULL OR message_error = '')

END
GO