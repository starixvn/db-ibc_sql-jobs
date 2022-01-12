DROP PROCEDURE IF EXISTS `API_CustomerExtraInfo_Get`;
DELIMITER $$
CREATE DEFINER=`afc_api`@`%` PROCEDURE `API_CustomerExtraInfo_Get`(
	IN CustIdList JSON
	/*
		Created: 20211130@Percy
		DB: Siebog
		Task: Get extra customer information
    
		Revisions:
			- 20211130@Percy: Initialize SP
  */
)
BEGIN
	SELECT c.CustId, cb.AccountNum, cb.AccountName
		,REPLACE(json_extract(cp.Profile, '$.CountryCode'), '"', '') 	AS CountryCode
        ,REPLACE(json_extract(cp.Profile, '$.PhoneNo'), '"', '') 		AS PhoneNo
        ,REPLACE(json_extract(cp.Profile, '$.Email') , '"', '')			AS Email
        ,REPLACE(json_extract(cp.Profile, '$.AccountName'), '"', '')	AS FullName
	FROM Customer c
		LEFT JOIN CustProfile cp ON c.CustId = cp.CustId
        LEFT JOIN CustBankInfoLog cb ON c.CustId = cb.CustId
	WHERE c.CustId IN (SELECT List.CustId FROM JSON_TABLE(CustIdList, '$[*]' COLUMNS (`CustId` INT PATH "$")) AS List);
END$$
DELIMITER ;
GRANT EXECUTE ON PROCEDURE `API_CustomerExtraInfo_Get` TO `afc_api`@`%`;
