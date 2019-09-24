SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE [dbo].[Task_Core_ProcessingCustListDel]
	@CustIds VARCHAR(4000) = NULL
AS
/*
	Created: 20170914@Patrick
	Task: Delete data on table ProcessingCustList
	DB: DBTXN.BODB02

	Revisions
		- 20170914@Patrick:	Initialize - [Redmine: #000000]
 */
BEGIN
	SET NOCOUNT ON
	--;WITH __CustList AS (
	--	SELECT t.CustId
	--	FROM CustDB.dbo.Customer c WITH(NOLOCK)
	--	CROSS APPLY (
	--		SELECT custid AS CustId UNION ALL
	--		SELECT recommend UNION ALL
	--		SELECT mrecommend UNION ALL
	--		SELECT srecommend
	--	)t
	--	WHERE c.custid IN (SELECT val FROM dbo.strSplit_Key(@CustIds, ','))
	--		AND t.CustId > 0
	--	GROUP BY t.CustId
	--)

	DELETE FROM dbo.ProcessingCustList WITH(ROWLOCK)
	--WHERE CustId IN (SELECT t.CustId FROM __CustList t)

END
GO
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/