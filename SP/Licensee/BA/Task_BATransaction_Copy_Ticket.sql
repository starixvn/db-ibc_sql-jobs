/*<info serverAlias="DB053-bodb_Licensee,DB042-bodb_Licensee" executers="" viewers="" isFunction="0" isNested="0"></info>*/
Use bodb_Licensee
GO    

CREATE PROCEDURE dbo.Task_BATransaction_Copy_Ticket @XmlData NVARCHAR(MAX), @ErrorCode INT = 0 OUTPUT
AS  
/*  
	Created: 20180806@Patrick
	Task: Copy BA ticket from DB052 for temporary
	DB: DB042.bodb_Licensee  
	Revisions: 
		- 20181002@Sophia: Sync BA ticket to DB053 [Redmine #99855]
		- 20181016@Sophia: Sync more table LicenseeBATransaction to DB053 [Redmine #99855]
						   This step support for UAT, when release on PRO will remove
 */  
BEGIN
	SET NOCOUNT ON

	IF @XmlData IS NULL RETURN

	SET @ErrorCode = 0
	DECLARE @xml XML = CAST(@XmlData AS XML)

	DECLARE @__BATransData TABLE (transid BIGINT, transdate DATETIME, custId INT, recommend INT, srecommend INT)
	INSERT @__BATransData(transid, transdate, custId, recommend, srecommend)
	SELECT r.value('./@t','bigint'), r.value('./@td','datetime'), r.value('./@c','int')
		, r.value('./@r','int'), r.value('./@s','int')
	FROM @xml.nodes('//root/r') AS RECORDS(r)
	OPTION (OPTIMIZE FOR (@xml = NULL ))

	----- server DB042 and DB053
	INSERT INTO dbo.LicenseeBATransaction_active(TransID, transdate, custid, recommend, srecommend)
	SELECT transid, transdate, custId, recommend, srecommend
	FROM @__BATransData t
	WHERE NOT EXISTS (
		SELECT TOP 1 1 
		FROM dbo.LicenseeBATransaction_active b WITH(NOLOCK)
		WHERE t.transid = b.TransID
	)
	
	IF @@SERVERNAME = 'DB053'
	BEGIN 
	----- server DB053
	INSERT INTO dbo.LicenseeBATransaction (TransID, transdate)
	SELECT transid, transdate
	FROM @__BATransData t
	WHERE NOT EXISTS (
		SELECT TOP 1 1 
		FROM dbo.LicenseeBATransaction  b WITH(NOLOCK)
		WHERE t.transid = b.TransID
	)
	END 

END


GO
 
