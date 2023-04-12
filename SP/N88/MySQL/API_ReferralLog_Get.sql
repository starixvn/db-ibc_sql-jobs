DROP PROCEDURE IF EXISTS API_ReferralLog_Get;
DELIMITER $$
CREATE  PROCEDURE `API_ReferralLog_Get`(
	IN Id INT,
	IN batchCount SMALLINT
  /*
		Created: 20230302@Malcolm
		DB: Slave DB/Siebog
		Task: Get ReferralLog data
    
		Revisions:
			- 20230302@Malcolm: Initialize SP

	*/
  
)
BEGIN
  
  SET batchCount = IF(batchCount > 2000, 2000, batchCount);
  
  SELECT
    *
  FROM
    ReferralLog
  WHERE
    ReferralLog.SQ > Id
  LIMIT batchCount;
	
END $$ 
DELIMITER ; 

GRANT EXECUTE ON PROCEDURE `API_ReferralLog_Get` TO 'affiliate_api'@'%';