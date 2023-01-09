/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_Consistency_AutoTransfer_Check_TotalTicketCorrect]
(
	@ScheduledDate DATE = NULL
	,@ErrCode		INT				= 0		OUTPUT
	,@ErrMsg		VARCHAR(MAX)	= ''	OUTPUT 
	,@SampleData	VARCHAR(MAX)	= ''	OUTPUT
)
AS
/*
	Created: 20220823@Sol
	Task: Data consistency - rule 51
	DB: DBCONSISTENCY-bodb_Consistency

	Revisions: 
		- 20220823@Sol: Scale out DBTrans - Detect data consistency SiteDB and CentralDB 
						- Check total ticket is correctly insert related to the number of super accounts - [Redmine:#175881]
		- 20221206@Danny: Skip check transfer Info - crypto Licensee [Redmine: #181343]
		- 20230105@Danny: Skip check transfer Info - crypto Licensee [Redmine: #181343]

	Param's Expanation:
*/
BEGIN
	SET NOCOUNT ON
	
	--parameters
	DECLARE 
		@totalEstimatedTicket INT = 0
		,@totalTransferTicket INT = 0
		,@endOfPreviousMonth DATE
		,@currentDate DATETIME
		,@listFromCustSuper VARCHAR(MAX) = ''
		,@listToCust VARCHAR(MAX) = ''
		,@forexUsername VARCHAR(50) = 'MYS-Forex G/(L)' --hard code from Acc_LicenseeTransfer_Job
		,@forexCustID VARCHAR(20) = '' -- using to create a custid list

	--set value for para
	SELECT 
		@currentDate = GETDATE(), 
		@endOfPreviousMonth = EOMONTH(DATEADD(MONTH, - 1, @currentDate))

	SELECT @forexCustID = CAST(c.custid AS VARCHAR(20))
	FROM bodb02.dbo.custInfo c WITH (NOLOCK)
	WHERE c.username = @forexUsername


	IF (ISNULL(@ScheduledDate, '') = '' ) 
	BEGIN
		SET @ScheduledDate = DATEADD(DAY, 5, @endOfPreviousMonth) ---5th of each month
	END

	--get total super in table LicenseeTransferPool from central DB
	SELECT 
		@totalEstimatedTicket = SUM
								(
									CASE 
										WHEN p.Fromcurrency = p.Tocurrency THEN 2 
										WHEN p.Fromcurrency <> p.Tocurrency THEN 4 
										ELSE 0 END
								)
	FROM DBCTG.bodb02.dbo.LicenseeTransferPool p WITH (NOLOCK)
	WHERE MonthDate = @endOfPreviousMonth AND p.Status <> 'Skipped'

	--get list custId
	SELECT 
		@listFromCustSuper = @listFromCustSuper + CAST(p.FromCustId AS VARCHAR(20)) + ',',
		@listToCust = @listToCust + CAST(p.ToCustId AS VARCHAR(20)) + ','
	FROM DBCTG.bodb02.dbo.LicenseeTransferPool p WITH (NOLOCK)
	WHERE MonthDate = @endOfPreviousMonth AND Status <> 'Skipped'

	--get total ticket from transfer table in siteDB
	;WITH rs AS
	(
		SELECT t.RefNo
		FROM bodb02.dbo.Transfer t WITH (NOLOCK)
		WHERE 
			t.WinlostDate = @ScheduledDate
			AND t.CustId IN (SELECT DISTINCT value FROM STRING_SPLIT(@listFromCustSuper, ',') WHERE ISNULL(value, '') <> '')
	)
	SELECT @totalTransferTicket = Count(1)
	FROM bodb02.dbo.Transfer t WITH (NOLOCK)
		INNER JOIN rs 
			ON rs.RefNo = t.RefNo
	WHERE 
		t.WinlostDate = @ScheduledDate
		AND t.CustId IN (SELECT DISTINCT value FROM STRING_SPLIT(@listFromCustSuper + @listToCust + @forexCustID, ',') WHERE ISNULL(value, '') <> '')

	--compare value
	IF (@totalEstimatedTicket <> @totalTransferTicket)
	BEGIN
		SELECT	 @ErrCode = 100
				,@ErrMsg = 'Automate transfer from Super Balance to Licensee Code: Compare estimated number of transfer tickets (from Super to Licensee Code) equal to actual number of transfer tickets.'
				,@SampleData =  'Number of estimated transfer tickets: ' + CAST(@totalEstimatedTicket AS VARCHAR(20)) + ' <> ' + 'Number of actual transfer tickets: ' + CAST(@totalTransferTicket AS VARCHAR(20))

		SELECT 'EstimatedTransferTickets' = @totalEstimatedTicket, 'ActualTransferTickets' = @totalTransferTicket
	END
	ELSE 
	BEGIN
		SELECT 'EstimatedTransferTickets' = t.TempC1, 'ActualTransferTickets' = t.TempC2
		FROM
			(
				VALUES (NULL, NULL)
			) AS t(TempC1, TempC2)
		WHERE t.TempC1 IS NOT NULL
	END

END
GO