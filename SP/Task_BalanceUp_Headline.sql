/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_BalanceUp_Headline]
	@winlostdate smalldatetime,
	@preview bit = 0
AS
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #__custList (KeyID int PRIMARY KEY IDENTITY(1,1), custid int)
	DECLARE @rc INT, @r INT

	INSERT INTO #__custList(custid)
	SELECT custid
	FROM dbo.balanceTable_tmp WITH(NOLOCK)
	WHERE roleid = 0

	SET @rc = @@ROWCOUNT
	SET @r = 1

	DECLARE @tblNoBetTmp TABLE (custid INT, transid BIGINT)
	DECLARE @delayTimeValue VARCHAR(50)
	SET @delayTimeValue = '00:00:01.500'

	DECLARE @transIds VARCHAR(MAX)
	SET @transIds = ''

	WHILE @r <= @rc
	BEGIN
	
		DELETE FROM @tblNoBetTmp
		SET @transIds = NULL

		INSERT INTO @tblNoBetTmp(custid, transid)
		SELECT custid, BAL_transid
		FROM #custid_nobet WITH (NOLOCK) WHERE KeyID BETWEEN @r AND @r + 1000
	
		DELETE FROM dbo.balanceTable_tmp WHERE custid IN (SELECT t.custid FROM @tblNoBetTmp t)
		--DELETE FROM dbo.bettrans WITH (ROWLOCK) WHERE transid IN (SELECT t.transid FROM @tblNoBetTmp t)
	
		SELECT @transIds = COALESCE(@transIds + '^' + CAST(transid AS VARCHAR(50)), CAST(transid AS VARCHAR(50)))
		FROM @tblNoBetTmp

		EXEC dbo.ExecRep_07 @custids = '', @custid = 0, @roleid = 111, @winlostdate = @winlostdate, @transIds = @transIds

		SET @r = @r + 1000

		SELECT @delayTimeValue = dbo.f_BU_GetDelayTime('Key1')
		WAITFOR DELAY @delayTimeValue

	END
END
GO
