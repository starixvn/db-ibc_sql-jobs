/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_BalanceUp_Headline]
	@winlostdate smalldatetime,
	@preview bit = 0
AS
/*
	Task: Sumup balance amount for headline account
	Location: DBTXN.bodb02

	Revision: Init [RedmineId: #118818]
*/
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #__custList (keyId int PRIMARY KEY IDENTITY(1,1), custid int)
	DECLARE @rc INT, @r INT

	INSERT INTO #__custList(custid)
	SELECT custid
	FROM dbo.balanceTable_tmp WITH(NOLOCK)
	WHERE roleid = 0

	SET @rc = @@ROWCOUNT
	SET @r = 1

	--DECLARE @__tempTransIds TABLE (transid BIGINT)
	DECLARE @__tempCustIds TABLE(custid INT)

	DECLARE @delayTimeValue VARCHAR(50)
	SET @delayTimeValue = '00:00:01.500'

	DECLARE @transIds VARCHAR(MAX)
	SET @transIds = ''

	WHILE @r <= @rc
	BEGIN
	
		DELETE FROM @__tempCustIds

		SET @transIds = NULL

		INSERT INTO @__tempCustIds(custid)
		SELECT t.custid
		FROM #__custList t WITH (NOLOCK)
		WHERE keyId >= @r AND keyId < @r + 200

		SELECT @transIds = COALESCE(@transIds + '^' + CAST(transid AS VARCHAR(50)), CAST(transid AS VARCHAR(50)))
		FROM dbo.bettrans b WITH(NOLOCK)
		WHERE b.custid IN (SELECT t.custId FROM @__tempCustIds t)
			AND b.winlostdate < @winlostdate
	
		DELETE FROM dbo.balanceTable_tmp WHERE custid IN (SELECT t.custid FROM @__tempCustIds t)
		EXEC dbo.ExecRep_07 @custids = '', @custid = 0, @roleid = 111, @winlostdate = @winlostdate, @transIds = @transIds

		SET @r = @r + 200

		SELECT @delayTimeValue = dbo.f_BU_GetDelayTime('Key1')
		WAITFOR DELAY @delayTimeValue

	END

	DROP TABLE #__custList
END
GO
