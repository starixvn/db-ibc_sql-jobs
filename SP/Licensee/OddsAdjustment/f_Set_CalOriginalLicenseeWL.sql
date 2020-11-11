/*<info serverAlias="DBTXN-bodb02" isFunction="1" isNested="0"></info>*/
ALTER FUNCTION f_Set_CalOriginalLicenseeWL
(  
	@oriOdds MONEY,
	@adjOdds MONEY,
	@oriWinlost MONEY,
	@adjWinlost MONEY,
	@actualStake MONEY,
	@statusId TINYINT,
	@statusWinlost TINYINT,
	@aPositionTaking SMALLMONEY,
	@mPositionTaking SMALLMONEY,
	@sPositionTaking SMALLMONEY,
	@roleId TINYINT,
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
			WHEN @statusId IN (112, 113) THEN
				CASE 
					WHEN (@isDecimalOnly = 1 OR (AdjOdds > 0 AND tbl.OriOdds > 0)) THEN 
						CASE
							WHEN @statusWinlost IN (1, 2) THEN (@adjWinlost * OriOdds) / AdjOdds -- won, half won
							ELSE @adjWinlost
						END
					WHEN (AdjOdds < 0 AND tbl.OriOdds < 0) THEN 
						CASE
							WHEN @statusWinlost IN (3, 4) THEN (@adjWinlost * OriOdds) / AdjOdds -- lose, half lose
							ELSE @adjWinlost
						END
					WHEN (tbl.OriOdds < 0 AND tbl.AdjOdds > 0) THEN
						CASE WHEN @roleId = 1 THEN
								CASE
									WHEN @statusWinlost = 2 THEN @actualStake -- won
									WHEN @statusWinlost = 1 THEN @actualStake * 0.5-- half won
									WHEN @statusWinlost = 4 THEN -1 * (@adjWinlost * tbl.OriOdds) -- lose
									WHEN @statusWinlost = 3 THEN -1 * (@adjWinlost * tbl.OriOdds * 0.5) -- half lose
									ELSE 0
								END
							WHEN @roleId = 2 THEN @oriWinlost * @aPositionTaking
							WHEN @roleId = 3 THEN @oriWinlost * @mPositionTaking
							WHEN @roleId = 4 THEN @oriWinlost * @sPositionTaking
						END
					WHEN (tbl.OriOdds > 0 AND tbl.AdjOdds < 0) THEN
						CASE WHEN @roleId = 1 THEN
								CASE
									WHEN @statusWinlost = 2 THEN @actualStake -- won
									WHEN @statusWinlost = 1 THEN @actualStake * 0.5-- half won
									WHEN @statusWinlost = 4 THEN -1 * (@adjWinlost / tbl.AdjOdds) -- lose
									WHEN @statusWinlost = 3 THEN -1 * ((@adjWinlost / tbl.AdjOdds) * 0.5) -- half lose
									ELSE 0
								END
							WHEN @roleId = 2 THEN @oriWinlost * @aPositionTaking
							WHEN @roleId = 3 THEN @oriWinlost * @mPositionTaking
							WHEN @roleId = 4 THEN @oriWinlost * @sPositionTaking
						END
				END
			ELSE 0
		END AS oriWL
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