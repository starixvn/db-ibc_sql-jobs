/*<info serverAlias="DBCUST-CUSTDB" executers="" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE dbo.Acc_CustomerInfo_Execrep_11
	@CustList VARCHAR(MAX)
AS
BEGIN
	SET NOCOUNT ON
	IF dbo.f_CheckRepTable('CustInfo') = 0 RETURN

	DECLARE @CustListXML XML
	
	SELECT @CustListXML = @CustList

	SELECT	r.value('./@ID','INT') AS CustID
	INTO #tmpList
	FROM @CustListXML.nodes('//R/C') AS RECORDS(r)

	UPDATE	ci 
	SET	ci.credit = 0
	FROM dbo.custInfo AS ci WITH(ROWLOCK,UPDLOCK)
		INNER JOIN #tmpList c ON c.custid = ci.custid		
END	