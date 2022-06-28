/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_BetParlayResult_Export]
	@winlostdate smalldatetime=null
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]	
	Database: DBTXN.bodb02
	Original: DB06x.bodb_archive.Task_Archive_SelectBetParlayResult
	
	Revisions:
		- 20130831@Bobby: Init
		- 20220628@Kathy: Remove column rID [Redmine:#173205]
 */
 BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	Declare @refNos TABLE (refno bigint PRIMARY KEY)
	INSERT INTO @refNos
	SELECT DISTINCT refno
	FROM dbo.bettrans14 with (nolock)
	WHERE winlostdate = @winlostdate AND bettype = 29

	SELECT
		b.RefNo, Serial, transid, winlostdate, statusid, stake, Odds, mOdds,
		winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm
	FROM
		dbo.BetParlayResult b WITH (NOLOCK)
		INNER JOIN @refNos r ON b.refno = r.refno
END
GO
