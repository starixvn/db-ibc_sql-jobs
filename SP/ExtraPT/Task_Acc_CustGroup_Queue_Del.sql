/*<info serverAlias="DBCUST-CustDB" executers="" isFunction="0" isNested="0"></info>*/
USE CustDB
GO

ALTER PROCEDURE [dbo].[Task_Acc_CustGroup_Queue_Del]
AS

/*
	Created: 20210302@Percy
	DB: DBCUST-CustDB
	Task: Auto Set Primary Extra PT Group - Job clean up data

	Revisions:
		- 20210301@Percy: Initialize SP [RemineID: #146710]
*/

BEGIN
	DECLARE @currentDate DATETIME = CONVERT(DATE, GETDATE())

	DELETE cg WITH (ROWLOCK, UPDLOCK)
	FROM dbo.Acc_CustGroup cg
		INNER JOIN dbo.Acc_CustGroup_Queue q WITH (NOLOCK) ON cg.CustId = q.CustId AND cg.GroupName = q.GroupName
	WHERE q.EndDate < @currentDate

	DELETE dbo.Acc_CustGroup_Queue WITH (ROWLOCK, UPDLOCK)
	WHERE EndDate < @currentDate

	UPDATE dbo.EaGroupHeadline WITH (ROWLOCK, UPDLOCK)
	SET GroupTypeId = 1, EffectiveDate = NULL, EndDate = NULL
	WHERE GroupTypeId = 2 AND EndDate < @currentDate

	DELETE dbo.EaGroupHeadline WITH (ROWLOCK, UPDLOCK)
	WHERE GroupName = '' AND GroupTypeId = 1
END
GO