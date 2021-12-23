/*<info serverAlias="DBMA-bodb_Maintenance" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Task_DailyDeleteMailData]
AS

/*
	Created: 20211223@Kos
	Task: Daily delete mail data on bodb_Maintenance
	DB: DBMA.bodb_Maintenance

	Revisions:
		- 20211223@Kos: Created [#Redmine: 166221]
*/

BEGIN
	SET NOCOUNT ON

	CREATE TABLE #__delete (MailID BIGINT PRIMARY KEY)
	CREATE TABLE #__temp (MailID BIGINT)
	CREATE TABLE #__temp_Attachment (Id INT)
	CREATE TABLE #__temp_Mail_Error (Id BIGINT)
	CREATE TABLE #__temp_Mail_LinkedResource (Id INT)

	--get all data need to delete
	INSERT INTO #__delete(MailID)
	SELECT MailID
	FROM dbo.Mail_Record WITH (NOLOCK)
	WHERE MailDate < DATEADD(MONTH, -6, GETDATE())
	ORDER BY MailID

	__try_deleted:
	TRUNCATE TABLE #__temp
	TRUNCATE TABLE #__temp_Attachment
	TRUNCATE TABLE #__temp_Mail_Error
	TRUNCATE TABLE #__temp_Mail_LinkedResource

	;WITH __cte_delete AS (
		SELECT TOP(1000) MailID FROM #__delete ORDER BY MailID
	)
	DELETE FROM __cte_delete OUTPUT deleted.MailID INTO #__temp(MailID)
	
	IF @@ROWCOUNT = 0
		GOTO __finishing

	--++Mail_Attachment
	INSERT INTO #__temp_Attachment(Id)
	SELECT AttachmentID FROM dbo.Mail_Attachment WITH(NOLOCK)
	WHERE MailID IN (SELECT t.MailID FROM #__temp t)

	WHILE 1 = 1
	BEGIN
		DELETE TOP(2000)
		FROM dbo.Mail_Attachment WITH(ROWLOCK)
		WHERE AttachmentID IN (SELECT Id FROM #__temp_Attachment)

		IF @@ROWCOUNT = 0
			BREAK
	END

	--++Mail_Error
	INSERT INTO #__temp_Mail_Error(Id)
	SELECT ErrorID FROM dbo.Mail_Error WITH(NOLOCK)
	WHERE MailID IN (SELECT t.MailID FROM #__temp t)

	WHILE 1 = 1
	BEGIN
		DELETE TOP(2000)
		FROM dbo.Mail_Error WITH(ROWLOCK)
		WHERE ErrorID IN (SELECT Id FROM #__temp_Mail_Error)

		IF @@ROWCOUNT = 0
			BREAK
	END

	--++Mail_LinkedResource
	INSERT INTO #__temp_Mail_LinkedResource(Id)
	SELECT LinkedID FROM dbo.Mail_LinkedResource WITH(NOLOCK)
	WHERE MailID IN (SELECT t.MailID FROM #__temp t)

	WHILE 1 = 1
	BEGIN
		DELETE TOP(2000)
		FROM dbo.Mail_LinkedResource WITH(ROWLOCK)
		WHERE LinkedID IN (SELECT Id FROM #__temp_Mail_LinkedResource)

		IF @@ROWCOUNT = 0
			BREAK
	END

	--++Mail_Record
	DELETE FROM dbo.Mail_Record WITH (ROWLOCK)
	WHERE MailID IN (SELECT t.MailID FROM #__temp t)

	WAITFOR DELAY '00:00:00.280'
	GOTO __try_deleted

	__finishing:

	DROP TABLE #__temp_Mail_Error
	DROP TABLE #__temp_Attachment
	DROP TABLE #__temp_Mail_LinkedResource
	DROP TABLE #__temp
	DROP TABLE #__delete

	PRINT 'Done!!!'
END
GO
