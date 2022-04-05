/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_CashOutSelling_Export]
	@winlostdate smalldatetime=null
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]	
	Database: DBTXN.bodb02
	Original: DBARC.bodb_Archive.dbo.Task_Archive_Copy 
	
	Revisions:
		- 20220317@Bobby: Integrate CashOutSelling table - [Redmine: #166146]	
*/
BEGIN
	SET NOCOUNT ON;
	
	SELECT t1.TransID
		,t1.MatchID
		,t1.Bettype
		,t1.Custid
		,t1.CashOutStatus
		,t1.Winlost
		,t1.PriceInfo
		,t1.CheckTime
		,t1.CreateDate
		,t1.ChangeDate
		,t1.VirtualRate
		,t1.CashoutExtraInfo
	FROM dbo.CashOutSelling AS t1 WITH (NOLOCK)
	INNER JOIN dbo.bettrans14 AS t2 WITH (NOLOCK) ON t1.transid = t2.transid
		AND t2.winlostdate = @winlostdate;

END
GO
