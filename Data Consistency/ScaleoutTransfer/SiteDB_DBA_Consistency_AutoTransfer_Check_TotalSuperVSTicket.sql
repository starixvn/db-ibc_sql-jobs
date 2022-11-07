/*<info serverAlias="DBSIG-bodb02" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[SiteDB_DBA_Consistency_AutoTransfer_Check_TotalSuperVSTicket]
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
		- 20221107@Evan: Count total super on each SiteGroupid [Redmine:#178864]

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
		,@SiteDBGroupID SMALLINT

	---get site group id
	SELECT @SiteDBGroupID = dbo.f_Get_SiteDBGroupID()
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
	WHERE s.SiteDBGroupID = @SiteDBGroupID
		AND MonthDate = @endOfPreviousMonth

	--get list custId
	SELECT 
		@listCustSuper = @listCustSuper + CAST(p.FromCustId AS VARCHAR(20)) + ','
	FROM DBCTG.bodb02.dbo.LicenseeTransferPool p WITH (NOLOCK)
		INNER JOIN CustDB.dbo.Dep_CustSuper s WITH(NOLOCK)
			ON p.FromCustId = s.custid
	WHERE s.SiteDBGroupID = @SiteDBGroupID
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
				,@ErrMsg = 'Automate transfer from Super Balance to Licensee Code: Verify number of transfer tickets match with number of Supers, who make the transfer.'
				,@SampleData =  'Number of transfer tickets: ' + CAST(@totalTransferTicket AS VARCHAR(20)) + ' <> ' + 'Number of Supers: ' + CAST(@totalSuper AS VARCHAR(20))

		SELECT 'NumberOfTransferTickets' = @totalTransferTicket, 'NumberOfSupers' = @totalSuper
	END
	ELSE
	BEGIN
		SELECT 'NumberOfTransferTickets' = t.TempC1, 'NumberOfSupers' = t.TempC2
		FROM
			(
				VALUES (NULL, NULL)
			) AS t(TempC1, TempC2)
		WHERE t.TempC1 IS NOT NULL
	END

END
GO