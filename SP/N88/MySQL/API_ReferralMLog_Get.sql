USE Siebog;

DROP PROCEDURE IF EXISTS `API_ReferralMLog_Get`;

DELIMITER //

CREATE DEFINER=`affiliate_api`@`%` PROCEDURE `API_ReferralMLog_Get`(
	IN Id INT,
	IN batchCount SMALLINT
	/*
		Created: 20220412@Percy
		DB: Slave DB/Siebog
		Task: Get ReferralMLog data
    
		Revisions:
			- 20220412@Percy: Initialize SP

	*/
)
BEGIN
	SET batchCount = IF(batchCount > 2000, 2000, batchCount);

	SELECT 
		*
	FROM
		ReferralMLog
	WHERE
		ReferralMLog.Id > Id
	LIMIT batchCount;
END

//
DELIMITER ;

GRANT EXECUTE ON PROCEDURE `API_ReferralMLog_Get` TO 'affiliate_api'@'%';