USE Siebog;
DROP PROCEDURE IF EXISTS `API_BalanceInfo_Get`;
DELIMITER //
CREATE DEFINER=`affiliate_api`@`%` PROCEDURE `API_BalanceInfo_Get`(
	IN CustIdList JSON
    /*
		Created: 20211010@Percy
		DB: Siebog
		Task: Get Cust Balance data
		
		Revisions:
		  - 20211010@Percy: Initialize SP
	*/
)
BEGIN
	SELECT c.CustId, c.UserName, c.CurrencyId, c.Status, c.ActStatus, cw.Balance
    FROM Customer c
		LEFT JOIN CustWallet cw ON c.CustId = cw.CustId
    WHERE c.CustId IN (SELECT List.CustId FROM JSON_TABLE(CustIdList, '$[*]' COLUMNS (`CustId` INT PATH "$")) AS List);
END
//
DELIMITER ;
GRANT EXECUTE ON PROCEDURE `API_BalanceInfo_Get` TO 'affiliate_api'@'%';
