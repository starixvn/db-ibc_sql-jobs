USE BetDetail;
DROP PROCEDURE IF EXISTS `API_TpReport9W_Get`;
DELIMITER //
CREATE DEFINER=`affiliate_api`@`%` PROCEDURE `API_TpReport9W_Get`(
	IN fromDate DATETIME,
	IN toDate DATETIME,
	IN pageIndex INT,
	IN pageSize INT
/*
    Created: 20220325@Percy
    DB: Siebog
    Task: Get TpReport9W data
    
    Revisions:
      - 20220325@Percy: Initialize SP
*/
)
BEGIN
	DECLARE _offSet INT;
    
	SET pageSize = IF(pageSize > 2000, 2000, pageSize); -- maximum is 2000
    SET _offSet = pageIndex * pageSize;
    
    SELECT
		t.SQ, t.userId, t.agentId, t.eventId, t.marketId, t.settledDate, t.resettledDate,
        t.profitLoss, t.marketTotal, t.commission, t.agentCommission, t.stakeTotal, t.CreateTime, t.UpdateTime,
        c.CustId
    FROM TpReport9W t
		INNER JOIN Siebog.TpCustInfo c ON t.userId = c.TpUserName AND c.TpId = 31
    WHERE t.UpdateTime BETWEEN fromDate AND toDate
    LIMIT _offSet, pageSize;
END
//
DELIMITER ;
GRANT EXECUTE ON PROCEDURE `API_TpReport9W_Get` TO 'affiliate_api'@'%';