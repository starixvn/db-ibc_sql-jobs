/*<info serverAlias="DBB2C-YashBet databaseType="2" executers="affiliate_api" isFunction="0" isNested="0" </info>*/
USE Siebog;

DROP PROCEDURE IF EXISTS `API_Get_Customer`;

DELIMITER //

CREATE DEFINER=`affiliate_api`@`%` PROCEDURE `API_Get_Customer`(
  IN fromDate DATETIME,
  IN batchCount INT
  /*
    Created: 20240115@Sally
    DB: YashBet DB/Siebog
    Task: Get all players which registered time from fromDate
    
	Revisions:
		- 20240115@Sally: Initialize SP

  */
)
BEGIN
	SET batchCount = IF(batchCount > 2000, 2000, batchCount);
    
	WITH CTE_Customer AS (
		(
			SELECT c.CustId
			FROM `Customer` c
			WHERE c.RegTime >= fromDate	
			ORDER BY c.RegTime
			LIMIT batchCount
		)
		UNION (
			SELECT cw.CustId
			FROM `CustWallet` cw
			WHERE cw.FirstDepositTime >= fromDate
			ORDER BY cw.FirstDepositTime
			LIMIT batchCount
		)
	)
	SELECT t.CustId, t.SiteId, t.UserName, t.CurrencyId, t.UserLang, t.ActStatus, t.AgentId, t.AllAgentId, t.UserLevel, t.RegTime, t.IsTest, t.Status, t.MemberType
	FROM CTE_Customer c
		INNER JOIN  `Customer` t on c.CustId = t.CustId
	ORDER BY t.RegTime
	LIMIT batchCount;

END

//
DELIMITER ;

GRANT EXECUTE ON PROCEDURE `API_Get_Customer` TO 'affiliate_api'@'%';