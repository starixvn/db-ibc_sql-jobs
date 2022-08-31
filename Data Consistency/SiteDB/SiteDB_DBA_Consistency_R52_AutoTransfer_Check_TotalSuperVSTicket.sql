/*<info serverAlias="DBSIG-bodb02" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[SiteDB_DBA_Consistency_R52_AutoTransfer_Check_TotalSuperVSTicket]
(
	@ScheduledDate DATE = NULL
	,@ErrCode		INT				= 0		OUTPUT
	,@ErrMsg		VARCHAR(MAX)	= ''	OUTPUT 
	,@SampleData	VARCHAR(MAX)	= ''	OUTPUT
)
AS
/*
	Created: 20220823@Sol
	Task: Data consistency - rule 52
	DB: DBSIG-bodb02

	Revisions: 
		- 20220823@Sol: Scale out DBTrans - Detect data consistency SiteDB and CentralDB 
						- Compare total transfer ticket with total super - [Redmine:#175881]

	Param's Expanation:
*/
BEGIN
	SET NOCOUNT ON
	
	--parameters
	DECLARE 
		@totalSuper INT = 0
		,@totalTransferTicket INT = 0
		,@endOfPreviousMonth DATE
		,@currentDate DATETIME
		,@listCustSuper VARCHAR(MAX) = ''

	--set value for para
	SELECT @currentDate = GETDATE(), @endOfPreviousMonth = EOMONTH(DATEADD(MONTH, - 1, @currentDate))

	IF (ISNULL(@ScheduledDate, '') = '' ) 
	BEGIN
		SET @ScheduledDate = DATEADD(DAY, 5, @endOfPreviousMonth) ---5th of each month
	END

	--get total super in table LicenseeTransferPool from central DB
	SELECT 
		@totalSuper = COUNT(1)
	FROM DBCTG.bodb02.dbo.LicenseeTransferPool p WITH (NOLOCK)
		INNER JOIN CustDB.dbo.Dep_CustSuper s WITH(NOLOCK)
			ON p.FromCustId = s.custid
	WHERE s.SiteDBGroupID > 0 
		AND MonthDate = @endOfPreviousMonth

	--get list custId
	SELECT 
		@listCustSuper = @listCustSuper + CAST(p.FromCustId AS VARCHAR(20)) + ','
	FROM DBCTG.bodb02.dbo.LicenseeTransferPool p WITH (NOLOCK)
		INNER JOIN CustDB.dbo.Dep_CustSuper s WITH(NOLOCK)
			ON p.FromCustId = s.custid
	WHERE s.SiteDBGroupID > 0 
		AND MonthDate = @endOfPreviousMonth

	--get total ticket from transfer table in siteDB
	SELECT @totalTransferTicket = Count(1)
	FROM bodb02.dbo.Transfer t WITH (NOLOCK)
	WHERE 
		t.WinlostDate = @ScheduledDate
		AND t.CustId IN (SELECT value FROM STRING_SPLIT(@listCustSuper, ',') WHERE ISNULL(value, '') <> '')

	--compare value
	IF (@totalSuper <> @totalTransferTicket)
	BEGIN
		SELECT	 @ErrCode = 100
				,@ErrMsg = 'Compare number of transfer tickets (from Super to Licensee Code) equal to number of Supers is incorrect'
				,@SampleData =  'Number of transfer tickets: ' + CAST(@totalTransferTicket AS VARCHAR(20)) + ' <> ' + 'Number of Supers: ' + CAST(@totalSuper AS VARCHAR(20))
	END

END
GO