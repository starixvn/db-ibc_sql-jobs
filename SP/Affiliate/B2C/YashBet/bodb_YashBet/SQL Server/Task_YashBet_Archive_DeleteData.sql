/*<info serverAlias="DBYASHBET-bodb_YashBet" isFunction="0" isNested="1"></info>*/
USE bodb_YashBet
GO
CREATE PROCEDURE [dbo].[Task_YashBet_Archive_DeleteData]
	@WinlostDate	SMALLDATETIME
	,@DataSource	VARCHAR(128)
AS

/*
	Created: 20240115@Sally
	DB: DBYASHBET-bodb_YashBet
	Task: Job - Archive data for TpBetRecord - Delete data

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

*/

BEGIN
	SET NOCOUNT ON

	IF @DataSource = 'TpBetRecord'
		WHILE 1 = 1
		BEGIN
			DELETE TOP (3000) 
			FROM dbo.TpBetRecord WITH (ROWLOCK, UPDLOCK)
			WHERE WinlostDate = @WinlostDate

			IF @@ROWCOUNT < 3000
				BREAK

			WAITFOR DELAY '00:00:00.280'
		END

	ELSE IF @DataSource = 'TpBetRecord_bk'
		WHILE 1 = 1
		BEGIN
			DELETE TOP (3000) 
			FROM bodb_YashBet_Archive.dbo.TpBetRecord_bk WITH (ROWLOCK, UPDLOCK)
			WHERE WinlostDate = @WinlostDate

			IF @@ROWCOUNT < 3000
				BREAK

			WAITFOR DELAY '00:00:00.280'
		END
END
GO