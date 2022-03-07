USE Siebog;
DROP PROCEDURE IF EXISTS `API_FinancialLog_Get`;
DELIMITER //
CREATE DEFINER=`affiliate_api`@`%` PROCEDURE `API_FinancialLog_Get`(
	IN TransIdList JSON
    /*
		Created: 20211010@Percy
		DB: Siebog
		Task: Get data from FinancialLog table
		
		Revisions:
		  - 20211010@Percy: Initialize SP
	*/
)
BEGIN
	SELECT f.Id, f.CustId, f.UserName, f.SiteId, f.ChangeAmount
    FROM FinancialLog f
    WHERE f.RefTransId IN (SELECT List.TransId COLLATE ascii_general_ci FROM JSON_TABLE(TransIdList, '$[*]' COLUMNS (`TransId` INT PATH "$")) AS List);
END
//
DELIMITER ;
GRANT EXECUTE ON PROCEDURE `API_FinancialLog_Get` TO 'affiliate_api'@'%';
