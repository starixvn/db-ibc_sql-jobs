DROP PROCEDURE IF EXISTS Aff_CustomerSel;
DELIMITER $$
CREATE  PROCEDURE `Aff_CustomerSel`(
  IN fromDate DATETIME
)
BEGIN
    SELECT c.CustId, c.SiteId, s.SiteName, a.AffId, c.UserName, c.Userpwd, c.CurrencyId, c.UserLang, c.ActStatus, c.UserLevel, c.LastLoginTime, c.RegTime, cw.FirstDepositTime, c.IsTest, c.IsKyc, c.IsRisk, c.`Status`, a.AffCode
      FROM `Customer` c
        INNER JOIN `Affiliate_VN` a ON a.CustId = c.CustId
        INNER JOIN `CustWallet` cw ON cw.CustId = c.CustId
        INNER JOIN `ServerInfo` s ON c.SiteId = s.SiteId
      WHERE cw.FirstDepositTime >= fromDate 
    UNION
    SELECT c.CustId, c.SiteId, s.SiteName, a.AffId, c.UserName, c.Userpwd, c.CurrencyId, c.UserLang, c.ActStatus, c.UserLevel, c.LastLoginTime, c.RegTime, cw.FirstDepositTime, c.IsTest, c.IsKyc, c.IsRisk, c.`Status`, a.AffCode
      FROM `Customer` c
        INNER JOIN `Affiliate_VN` a ON a.CustId = c.CustId
        LEFT JOIN `CustWallet` cw ON cw.CustId = c.CustId
        INNER JOIN `ServerInfo` s ON c.SiteId = s.SiteId
      WHERE c.RegTime >= fromDate
    ORDER BY SiteId, SiteName;
END
 $$ 
DELIMITER ; 

GRANT EXECUTE ON PROCEDURE `API_AdjustmentInfo_Get` TO 'affiliate_api'@'%';