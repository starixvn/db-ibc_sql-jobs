/*<info serverAlias="DBN88-bodb_N88" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_N88_Archive_DeleteData]
	@WinlostDate	SMALLDATETIME
	,@DataSource	VARCHAR(128)
AS

/*
	Created: 20220222@Percy
	DB: DBN88-bodb_N88
	Task: Job - Archive data for TpBetRecord - Delete data

	Revisions:
		- 20220222@Percy: Initialize SP [RedmineID: #167823]
*/

BEGIN
	SET NOCOUNT ON

	IF @DataSource = 'TpBetRecord'
		WHILE 1 = 1
		BEGIN
			DELETE TOP (3000) FROM dbo.TpBetRecord WITH (ROWLOCK, UPDLOCK)
			WHERE WinlostDate = @WinlostDate

			IF @@ROWCOUNT < 3000
				BREAK

			WAITFOR DELAY '00:00:00.280'
		END

	ELSE IF @DataSource = 'TpBetRecord_bk'
		WHILE 1 = 1
		BEGIN
			DELETE TOP (3000) FROM bodb_N88_Archive.dbo.TpBetRecord_bk WITH (ROWLOCK, UPDLOCK)
			WHERE WinlostDate = @WinlostDate

			IF @@ROWCOUNT < 3000
				BREAK

			WAITFOR DELAY '00:00:00.280'
		END
END
GO