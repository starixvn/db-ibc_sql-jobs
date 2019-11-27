/*<info serverAlias="DBTXN-bodb02" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_HeadlineBalance_Status_Job]
AS

/*
	Created by 20191121@Percy
    Task: Headline Balance Check & Correct Job has done yet?
    DB: DBTXN.bodb02

	Revisions:
		- 20191121@Percy: Initialize SP [RedmineID: #119289]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @StatusID TINYINT = 0

	EXEC dbo.Task_HeadlineBalance_Status @StatusID = @StatusID OUTPUT

	-- Headline Balance Check & Correct Job does not start yet or is running --> loop 15 minutes
	IF ISNULL(@StatusID, 0) <> 0
	BEGIN
		RAISERROR('* LOOP * Headline Balance Check & Correct Job is processing. Automatically retry after 15mins.', 16, 1)
		RETURN
	END
END
GO