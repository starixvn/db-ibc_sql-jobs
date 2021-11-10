/*<info serverAlias="DBARC-bodb_Archive" executers="" selecters="" viewers="" isFunction="0" isNested="0"></info>*/
/*
    Created: 20211110@Max
	Task: Set up MBU on SIT - [Redmine: #164436]
	DB: DBARC/bodb_Archive

	Notes:
		- Clean up data on bet ticket tables before 29/10/2021 
*/

USE [bodb_Archive]
GO

--dbo.bettrans_AGCasino_bk: select COUNT(1) from dbo.bettrans_AGCasino_bk b with (nolock) where b.Winlostdate < '2021-10-29' --> count = 0 --> skip
--dbo.bettrans_Staging_bk:  select top 10 * from dbo.bettrans_Staging_bk b with (nolock) --> No row --> skip

--dbo.bettrans_bk - 1312 rows : select COUNT(1) from dbo.bettrans_bk b with (nolock) where b.winlostdate < '2021-10-29'
BEGIN
	WHILE (1=1)
	BEGIN
		DELETE TOP(2000) b
		FROM dbo.bettrans_bk b WITH (ROWLOCK, UPDLOCK)
		WHERE b.winlostdate < '2021-10-29'

		IF @@ROWCOUNT = 0 BREAK

		WAITFOR DELAY '00:00:00.010'
	END
END

--dbo.bettransG - 686847 rows: select COUNT(1) from dbo.bettransG b with (nolock) where b.winlostdate < '2021-10-29'
BEGIN
	WHILE (1=1)
	BEGIN
		DELETE TOP(2000) b
		FROM dbo.bettransG b WITH (ROWLOCK, UPDLOCK)
		WHERE b.winlostdate < '2021-10-29'

		IF @@ROWCOUNT = 0 BREAK

		WAITFOR DELAY '00:00:00.010'
	END
END

--dbo.bettransLC_bk - 58 rows: select COUNT(1) from dbo.bettransLC_bk b with (nolock) where b.winlostdate < '2021-10-29'
BEGIN
	WHILE (1=1)
	BEGIN
		DELETE TOP(2000) b
		FROM dbo.bettransLC_bk b WITH (ROWLOCK, UPDLOCK)
		WHERE b.winlostdate < '2021-10-29'

		IF @@ROWCOUNT = 0 BREAK

		WAITFOR DELAY '00:00:00.010'
	END
END

--dbo.bettransm - 1237885 rows: select COUNT(1) from dbo.bettransm b with (nolock) where b.winlostdate < '2021-10-29'
BEGIN
	WHILE (1=1)
	BEGIN
		DELETE TOP(2000) b
		FROM dbo.bettransm b WITH (ROWLOCK, UPDLOCK)
		WHERE b.winlostdate < '2021-10-29'

		IF @@ROWCOUNT = 0 BREAK

		WAITFOR DELAY '00:00:00.010'
	END
END

--dbo.bettransRnG_bk - 1259 rows: select COUNT(1) from dbo.bettransRnG_bk b with (nolock) where b.winlostdate < '2021-10-29'
BEGIN
	WHILE (1=1)
	BEGIN
		DELETE TOP(2000) b
		FROM dbo.bettransRnG_bk b WITH (ROWLOCK, UPDLOCK)
		WHERE b.winlostdate < '2021-10-29'

		IF @@ROWCOUNT = 0 BREAK

		WAITFOR DELAY '00:00:00.010'
	END
END

--dbo.translog_BK - 81 rows: select COUNT(1) from dbo.translog_BK b with (nolock) where b.winlostdate < '2021-10-29'
BEGIN
	WHILE (1=1)
	BEGIN
		DELETE TOP(2000) b
		FROM dbo.translog_BK b WITH (ROWLOCK, UPDLOCK)
		WHERE b.winlostdate < '2021-10-29'

		IF @@ROWCOUNT = 0 BREAK

		WAITFOR DELAY '00:00:00.010'
	END
END

