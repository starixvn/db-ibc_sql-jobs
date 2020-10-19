/*<info serverAlias="DBTXN-bodb02" isFunction="1" isNested="0"></info>*/
CREATE FUNCTION f_Set_CalOriginalLicenseeWL
(  
	@oriOdds MONEY,
	@adjOdds MONEY,
	@aWinlost MONEY,
	@statusWinlost TINYINT,
	@isDecimalOnly BIT
)
RETURNS TABLE
AS
/*
	Created: 20201001@Sol
	Task: Cal original licensee winlost
	DB: DBTXN/bodb02

	Revisions:
		- 20201001@Sol: LAP - Licensee Spread Setting - calculate original licensee winlost - [Redmine #142532]

*/
RETURN 
(
	SELECT
		CASE
			WHEN (@isDecimalOnly = 1 OR AdjOdds > 0) THEN 
				CASE
					WHEN @statusWinlost IN (1, 2) THEN (@aWinlost * OriOdds) / AdjOdds -- won, half won
					ELSE @aWinlost
				END
			ELSE CASE
					WHEN @statusWinlost IN (3, 4) THEN (@aWinlost * OriOdds) / AdjOdds -- lose, half lose
					ELSE @aWinlost
				END
		END AS oriAgentWinlost -- licensee winlost
	FROM 
	(
		SELECT OriOdds, AdjOdds
		FROM 
		(
			VALUES
			(
				CASE
					WHEN @isDecimalOnly = 1 THEN @oriOdds - 1
					ELSE @oriOdds
				END,
				CASE
					WHEN @isDecimalOnly = 1 THEN @adjOdds - 1
					ELSE @adjOdds
				END
			)
		) t (OriOdds, AdjOdds)) tbl)
GO