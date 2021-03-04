USE Siebog;

DROP PROCEDURE IF EXISTS `N88_Get_Customer`;

DELIMITER //

CREATE DEFINER=`affiliate_api`@`%` PROCEDURE `N88_Get_Customer`(
  IN fromDate DATETIME
  /*
    Created: 20200520@Percy
    DB: Slave DB/Siebog
    Task: Get all players which registered time from fromDate
    
    Revisions:
      - 20200520@Percy: Initialize SP

  */
)
BEGIN
  SELECT c.CustId, c.SiteId, c.UserName, c.CurrencyId, c.UserLang, c.ActStatus, c.AgentId, c.AllAgentId, c.UserLevel, c.RegTime, c.IsTest, c.Status
    FROM `Customer` c
    WHERE c.RegTime >= fromDate
	
	UNION
  SELECT c.CustId, c.SiteId, c.UserName, c.CurrencyId, c.UserLang, c.ActStatus, c.AgentId, c.AllAgentId, c.UserLevel, c.RegTime, c.IsTest, c.Status
    FROM `Customer` c
      INNER JOIN `CustWallet` cw
    WHERE cw.FirstDepositTime >= fromDate;
END

//
DELIMITER ;

GRANT EXECUTE ON PROCEDURE `N88_Get_Customer` TO 'affiliate_api'@'%';