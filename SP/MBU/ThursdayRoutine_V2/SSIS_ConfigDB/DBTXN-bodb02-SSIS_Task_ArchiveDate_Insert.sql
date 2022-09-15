/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_Task_ArchiveDate_Insert]
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]				
	Database:	DBTXN.bodb02
	Revisions:
		- 20130831@Bobby: Init
		- 20220811@Bobby: Support scaleout DB [Redmine: #175602]
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @MoveBetsDay SMALLDATETIME,  @BUDate SMALLDATETIME
	DECLARE @MBU TABLE ( MoveBetsDay SMALLDATETIME, BalanceUpDay SMALLDATETIME)

	INSERT INTO @MBU (BalanceUpDay, MoveBetsDay)
	EXEC dbo.Age_SelBalanceUpDay

	SELECT @MoveBetsDay = MoveBetsDay, @BUDate = BalanceUpDay
	FROM @MBU


	EXEC DBPRO.bodb02.dbo.ExecRep_APL_07 @TableName = 'Task_ArchiveDate'
		,@BUDate = @BUDate;

END
GO
