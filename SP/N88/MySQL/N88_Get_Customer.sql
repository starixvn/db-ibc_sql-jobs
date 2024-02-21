USE Siebog;

DROP PROCEDURE IF EXISTS `N88_Get_Customer`;

DELIMITER //

CREATE DEFINER=`affiliate_api`@`%` PROCEDURE `N88_Get_Customer`(
  IN fromDate DATETIME,
  IN toDate DATETIME,
  IN pageIndex INT,
  IN pageSize INT
  /*
    Created: 20200520@Percy
    DB: Slave DB/Siebog
    Task: Get all players which registered time from fromDate
    
    Revisions:
      - 20200520@Percy: Initialize SP
	  - 20230704@Sally: Get data column MemberType [RedmineId: #189299]
	  - 20230817@Sally: Repull data customer with a new updated MemberType [RedmineId: #192859]
	  - 20230817@Sally: Repull data customer with a new updated MemberType [RedmineId: #192859]
	  - 20240312@Sally: Enhance get data by range date and pageIndex [RedmineId: #202199]

  */
)
BEGIN

	DECLARE _offSet INT;
    SET pageSize = IF(pageSize > 2000, 2000, pageSize); -- maximum is 2000
    SET _offSet = pageIndex * pageSize;

	WITH CTE_Customer AS (
		(
			SELECT c.CustId
			FROM `Customer` c
			WHERE c.RegTime BETWEEN fromDate AND toDate
		)
		UNION (
			SELECT cw.CustId
			FROM `CustWallet` cw
			WHERE cw.FirstDepositTime BETWEEN fromDate AND toDate
		)
        UNION (
			SELECT ct.CustId
			FROM `CustTaskTime` ct
			WHERE ct.TaskTime BETWEEN fromDate AND toDate
				AND TaskId IN (2, 5)
		)
	)
	SELECT t.CustId, t.SiteId, t.UserName, t.CurrencyId, t.UserLang, t.ActStatus, t.AgentId, t.AllAgentId, t.UserLevel, t.RegTime, t.IsTest, t.Status, t.MemberType
	FROM CTE_Customer c
		INNER JOIN  `Customer` t on c.CustId = t.CustId
	ORDER BY t.RegTime ASC, CustId ASC
	LIMIT _offSet, pageSize;

END

//
DELIMITER ;

GRANT EXECUTE ON PROCEDURE `N88_Get_Customer` TO 'affiliate_api'@'%';