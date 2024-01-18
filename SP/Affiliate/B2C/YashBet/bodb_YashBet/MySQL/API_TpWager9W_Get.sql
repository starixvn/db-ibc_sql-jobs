/*<info serverAlias="DBB2C-YashBet databaseType="2" executers="affiliate_api" isFunction="0" isNested="0" </info>*/
USE BetDetail;
DROP PROCEDURE IF EXISTS `API_TpWager9W_Get`;
DELIMITER //
CREATE DEFINER=`affiliate_api`@`%` PROCEDURE `API_TpWager9W_Get`(
	IN fromDate DATETIME,
	IN toDate DATETIME,
	IN pageIndex INT,
	IN pageSize INT
/*
    Created: 20240115@Sally
    DB: YashBet DB/Siebog
    Task: Get TpWager9W data
    
	Revisions:
		- 20240115@Sally: Initialize SP

*/
)
BEGIN
	DECLARE _offSet INT;
    
	SET pageSize = IF(pageSize > 2000, 2000, pageSize); -- maximum is 2000
    SET _offSet = pageIndex * pageSize;
    
    SELECT
		betId, userId, agentId, eventId, marketId, matchSettledDate, betStatus,
        matchStake, profitLoss, CreateTime, UpdateTime
    FROM `TpWager9W` t
    WHERE t.UpdateTime BETWEEN fromDate AND toDate
    LIMIT _offSet, pageSize;
END
//
DELIMITER ;
GRANT EXECUTE ON PROCEDURE `API_TpWager9W_Get` TO 'affiliate_api'@'%';