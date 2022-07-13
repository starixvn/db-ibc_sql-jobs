DROP PROCEDURE IF EXISTS Affiliate_LoginCustInfo_Get;
DELIMITER $$
CREATE  PROCEDURE `Affiliate_LoginCustInfo_Get`(
  IN UserName VARCHAR(30) CHARACTER SET ASCII,
    IN SiteId INT
)
BEGIN
  

  SELECT 
    Customer.CustId,
    Customer.SiteId,
    Customer.UserName,
    Customer.Userpwd,
    Customer.CurrencyId,
    Customer.UserLang,
    Customer.ActStatus,
    Customer.AgentId,
    Customer.AllAgentId,
    Customer.UserLevel,
    Customer.IsTest,
    Customer.`Status`
  FROM
    Customer
  WHERE
    Customer.UserName = UserName
      AND Customer.SiteId = SiteId;
END $$ 
DELIMITER ; 

GRANT EXECUTE ON PROCEDURE `API_AdjustmentInfo_Get` TO 'affiliate_api'@'%';