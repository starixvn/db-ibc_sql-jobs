/*<info serverAlias="DBB2C-YashBet databaseType="2" executers="affiliate_api" isFunction="0" isNested="0" </info>*/
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

GRANT EXECUTE ON PROCEDURE `Affiliate_LoginCustInfo_Get` TO 'affiliate_api'@'%';