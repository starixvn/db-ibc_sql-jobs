SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE [dbo].[Task_Core_ProcessingCustListIns]
	@CustIds VARCHAR(4000)
AS
/*
	Created: 20170914@Patrick
	Task: Insert/Delete data on table ProcessingCustList
	DB: DBTXN.BODB02

	Revisions:
		- 20170914@Patrick:	Initialize - [Redmine: #000000]
		- 20220315@Kathy: Change to use STRING_SPLIT [Redmine:#166457]
 */
 BEGIN
	SET NOCOUNT ON
	;WITH __CustList AS (
		SELECT t.CustId
		FROM CustDB.dbo.Customer c WITH(NOLOCK)
		CROSS APPLY (
			SELECT custid AS CustId UNION ALL
			SELECT recommend UNION ALL
			SELECT mrecommend UNION ALL
			SELECT srecommend
		)t
		WHERE c.custid IN (SELECT value FROM STRING_SPLIT(@CustIds, ','))
			AND t.CustId > 0
		GROUP BY t.CustId
	)

	INSERT INTO dbo.ProcessingCustList(CustId)
	SELECT CustId FROM __CustList

 END
GO
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/