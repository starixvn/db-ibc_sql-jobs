/*<info serverAlias="DBSIG-bodb02" executers="" viewers="" isFunction="0"></info>*/
/*
	Created by: 20230706@July
	Task: Mark DEL_ + SP drop  [Redmine:#190859]  
	DB: DBSIG-bodb02
	
*/
USE bodb02
GO

DECLARE @command VARCHAR(MAX)
DECLARE @tmpRenameObjectsName TABLE ( command VARCHAR(MAX), IsRename BIT)

INSERT INTO @tmpRenameObjectsName (command)
SELECT 'sp_rename ' + name + ', DEL_' + name
 FROM dbo.sysobjects
 WHERE (type = 'P')
 AND (
  /*  File sheet mismatch row 248-252  */
    name LIKE 'SSIS_Archive_TVS_PreInit%'
OR  name LIKE 'SSIS_TicketVoiding_Request_Export%' --X
OR  name LIKE 'SSIS_TicketVoiding_RequestDetail_Export%'
OR  name LIKE 'SSIS_TicketVoiding_RequestDetailTicket_Single_Export%'
OR  name LIKE 'SSIS_TicketVoiding_RequestDetailTicket_SubParlay_Export%'
OR  name LIKE 'SSIS_TicketVoiding_VoidingHistory_Export%'
OR  name LIKE 'SSIS_TicketVoiding_VoidedTransaction_Export%' --X
OR  name LIKE 'SSIS_TicketVoiding_OperatorInfo_Export%'
OR  name LIKE 'SSIS_TicketVoiding_AutoUnmarkSetting_Export%' 
OR  name LIKE 'SSIS_TicketVoiding_Reason_Export%' 
)
WHILE (1=1)
BEGIN
	UPDATE TOP (1) @tmpRenameObjectsName
	SET @command = command, IsRename = 1
	WHERE IsRename IS NULL

	IF @@ROWCOUNT = 0 BREAK;
	
	EXEC (@command)

END
SELECT * FROM @tmpRenameObjectsName