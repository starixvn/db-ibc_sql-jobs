/*<info serverAlias="DBSIG-bodb02" executers="" viewers="" isFunction="0"></info>*/
/*
	Created by: 20230706@July
	Task: [TVS] Drop SP/tables are not needed on sitedb3 and all sitedb  [Redmine:#190859]  
	DB: DBSIG-bodb02
	
*/
USE bodb02
GO

DECLARE @command VARCHAR(MAX)
DECLARE @tmpDropObjectsName TABLE ( command VARCHAR(MAX), IsDrop BIT)

INSERT INTO @tmpDropObjectsName (command)
SELECT 'DROP PROCEDURE ' +name
 FROM dbo.sysobjects
 WHERE (type = 'P')
 AND (
  /*  File sheet mismatch row 248-252  */
    name LIKE 'DEL_SSIS_Archive_TVS_PreInit%'
OR  name LIKE 'DEL_SSIS_TicketVoiding_Request_Export%' --X
OR  name LIKE 'DEL_SSIS_TicketVoiding_RequestDetail_Export%'
OR  name LIKE 'DEL_SSIS_TicketVoiding_RequestDetailTicket_Single_Export%'
OR  name LIKE 'DEL_SSIS_TicketVoiding_RequestDetailTicket_SubParlay_Export%'
OR  name LIKE 'DEL_SSIS_TicketVoiding_VoidingHistory_Export%'
OR  name LIKE 'DEL_SSIS_TicketVoiding_VoidedTransaction_Export%' --X
OR  name LIKE 'DEL_SSIS_TicketVoiding_OperatorInfo_Export%'
OR  name LIKE 'DEL_SSIS_TicketVoiding_AutoUnmarkSetting_Export%' 
OR  name LIKE 'DEL_SSIS_TicketVoiding_Reason_Export%' 
)
SELECT * FROM @tmpDropObjectsName
WHILE (1=1)
BEGIN
	UPDATE TOP (1) @tmpDropObjectsName
	SET @command = command, IsDrop = 1
	WHERE IsDrop IS NULL

	IF @@ROWCOUNT = 0 BREAK;
	
	EXEC (@command)

END

