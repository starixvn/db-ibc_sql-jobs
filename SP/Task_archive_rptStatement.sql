/*<info serverAlias="DBRPT-bodb_Report" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_archive_rptStatement]
AS
/*
	Creator:	20180829@Billy
	Task:		Move job content to SP - [Redmine: #99955]
	Database:	DBRPT.bodb_Report
	
	Revisions:
		- 20180829@Billy:	Initial - [Redmine: #99955]
		- 20191210@Percy:	Change condition check BU finish yet [RedmineID: #125272]
		- 20191216@Percy:	Fix issue delete data on Friday [RedmineID: #125476]
		
	Developer's Notes:
		- @Example:			NULL		- Explaination [DEFAULT]
		
*/
BEGIN;
	SET NOCOUNT ON

	DECLARE	@DateName VARCHAR(10)
	SELECT	@DateName = DATENAME(WEEKDAY, CONVERT(DATE, DATEADD(WEEK, -1, GETDATE())))

	IF @DateName NOT IN ('Thursday', 'Friday')
	BEGIN
		RAISERROR ('Invalid BalanceUp Date!!!!!', 16, 1) WITH NOWAIT
		RETURN
	END

	DECLARE	@BalanceUpDay	DATETIME
	DECLARE @MinArchiveDate	DATETIME
	DECLARE	@TempDate		DATETIME
	DECLARE	@Count			INT

	DECLARE	@MBUDay			AS TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)
	
	INSERT INTO @MBUDay (BalanceUpDay, MoveBetsDay)
	EXECUTE	bodb02.dbo.Age_SelBalanceUpDay

	SELECT	@BalanceUpDay	= BalanceUpDay		FROM @MBUDay
	SELECT  @MinArchiveDate = MIN(winlostdate)	FROM DBTXN.bodb02.dbo.Task_ArchiveDate WITH (NOLOCK)

	IF @DateName = 'Thursday' -- Copy data
	BEGIN
		IF @BalanceUpDay = @MinArchiveDate -- Old BU Date, BU is running
		BEGIN
			SELECT @BalanceUpDay = DATEADD(DAY, 7, @BalanceUpDay)
		END
		ELSE IF @BalanceUpDay = DATEADD(DAY, 7, @MinArchiveDate) -- New BU Date, BU is completed
		BEGIN
			DECLARE @custid INT
			SELECT  TOP 1 @custid = custid FROM dbo.rptStatement WITH (NOLOCK) WHERE winlostdate = @MinArchiveDate

			IF EXISTS (SELECT 1 FROM dbo.rptStatement_Old WITH (NOLOCK) WHERE custid = @custid AND winlostdate = @MinArchiveDate)
			BEGIN
				RAISERROR('Data on rptStatement_Old is already copied!!!!!', 16, 1) WITH NOWAIT
				RETURN
			END
		END
		ELSE
		BEGIN
			RAISERROR('BalanceUp is not run yet!!!!!', 16, 1) WITH NOWAIT
			RETURN
		END

		SELECT	@count = -7
		WHILE	@count < 0
		BEGIN
			SELECT	@TempDate = DATEADD(DAY, @Count, @BalanceUpDay);
			EXECUTE	dbo.Task_archive_rptStatement_Insert @TempDate;
			SELECT	@count = @count + 1;
		END
	END
	ELSE IF	@DateName = 'Friday' -- Delete data
	BEGIN
		IF @BalanceUpDay = @MinArchiveDate
		BEGIN
			RAISERROR('BalanceUp is not completed yet!!!!!', 16, 1) WITH NOWAIT
			RETURN
		END

		DECLARE	@VerifyData		AS TABLE (CustId INT, WinlostDate DATE)

		;WITH tally AS (
			SELECT	[rn] = ROW_NUMBER() OVER(ORDER BY (SELECT NULL))
			FROM	(VALUES (1), (2), (3), (4), (5), (6), (7)) AS a(x)
		)
		INSERT INTO	@VerifyData (CustId, WinlostDate)
		SELECT	r.CustId, r.WinlostDate
		FROM	tally AS tmp
			CROSS APPLY	(
				SELECT	TOP(1) r.CustId, r.WinlostDate
				FROM	dbo.rptStatement AS r WITH (NOLOCK)
				WHERE	r.WinlostDate = DATEADD(DAY, tmp.rn - 1, @MinArchiveDate)
			) AS r

		IF NOT EXISTS (
			SELECT 1
			FROM dbo.rptStatement_Old AS r WITH (NOLOCK)
				INNER JOIN	@VerifyData AS vd ON r.CustId = vd.CustId AND r.WinlostDate = vd.WinlostDate
			HAVING COUNT (1) = 7
		)
		BEGIN
			RAISERROR('Data on rptStatement_Old is not copied yet!!!!!', 16, 1) WITH NOWAIT
			RETURN
		END

		SELECT	@count = -7
		WHILE	@count < 0
		BEGIN
			SELECT	@TempDate = DATEADD(DAY, @Count, @BalanceUpDay)
			EXECUTE	dbo.Task_archive_rptStatement_Delete @TempDate;
			SELECT	@count = @count + 1;
		END
	END
END
GO