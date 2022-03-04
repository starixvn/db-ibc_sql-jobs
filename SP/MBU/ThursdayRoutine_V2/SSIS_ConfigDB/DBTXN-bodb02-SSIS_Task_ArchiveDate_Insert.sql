/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_Task_ArchiveDate_Insert]
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]				
	Database:	DBTXN.bodb02
	Revisions:
		- 20130831@Bobby: Init
*/
BEGIN
	SET NOCOUNT ON;

	DELETE FROM dbo.SSIS_Task_ArchiveDate

	INSERT INTO dbo.SSIS_Task_ArchiveDate
	SELECT DISTINCT TOP 7 winlostdate
	FROM dbo.bettrans14 WITH(NOLOCK)
	ORDER BY winlostdate ASC

END
GO
