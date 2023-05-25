/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_DailySummary_IP2Country]
(
	@winlostdate SMALLDATETIME,
	@target VARCHAR(20) = 'all',
	@isdebug BIT = 0
)
AS

/*
	Create By: Unknow
	Task: Archive bet data for IP country
	DB: DBTXN/bodb02
	Revisions:
		- 20190523@Patrick: Convert NULL IP value to empty [RedmineId: #113997]
		- 20211004@Helen:	Support IPv6 Phase 1 - change datatype first - [Redmine: #160390]
		- 20230524@Patrick: Enhance code to avoid log growth [Redmine: #188699]

	Para's explaination
*/
BEGIN
	SET NOCOUNT ON
	--bettrans14
	EXEC dbo.Task_DailySummary_IP2Country_Bettrans14 
		@winlostdate = @winlostdate,
		@isdebug = @isdebug

	--bettransRnG14
	EXEC dbo.Task_DailySummary_IP2Country_BettransRnG14 
		@winlostdate = @winlostdate,
		@isdebug = @isdebug

	--bettransLC14
	EXEC dbo.Task_DailySummary_IP2Country_BettransLC14 
		@winlostdate = @winlostdate,
		@isdebug = @isdebug
END
GO

