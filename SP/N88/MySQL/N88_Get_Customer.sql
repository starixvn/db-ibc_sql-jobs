USE Siebog;

DROP PROCEDURE IF EXISTS `N88_Get_Customer`;

DELIMITER //

CREATE DEFINER=`affiliate_api`@`%` PROCEDURE `N88_Get_Customer`(
  IN fromDate DATETIME,
  IN batchCount INT
  /*
    Created: 20200520@Percy
    DB: Slave DB/Siebog
    Task: Get all players which registered time from fromDate
    
    Revisions:
      - 20200520@Percy: Initialize SP
	  - 20230704@Sally: Get data column MemberType [RedmineId: #189299]
	  - 20230817@Sally: Repull data customer with a new updated MemberType [RedmineId: #192859]

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
        UNION (
			SELECT cw.CustId
			FROM `CustTaskTime` ct
			WHERE ct.TaskTime >= fromDate
				AND TaskId IN (2, 5)
			ORDER BY ct.TaskTime
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

GRANT EXECUTE ON PROCEDURE `N88_Get_Customer` TO 'affiliate_api'@'%';