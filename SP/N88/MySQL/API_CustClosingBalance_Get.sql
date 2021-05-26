USE Siebog;

DROP PROCEDURE IF EXISTS `API_CustClosingBalance_Get`;

DELIMITER //

CREATE DEFINER=`affiliate_api`@`%` PROCEDURE `API_CustClosingBalance_Get`(
  IN Time INT,
  IN batchCount INT
  /*
    Created: 20210525@Percy
    DB: Slave DB/Siebog
    Task: Get CustClosingBalance data
    
    Revisions:
      - 20210525@Percy: Initialize SP

  */
)
BEGIN
	SET batchCount = IF(batchCount > 2000, 2000, batchCount);
    
	SELECT 
		* 
	FROM
		CustClosingBalance
	WHERE
		CustClosingBalance.Time >= Time
	LIMIT batchCount;
END

//
DELIMITER ;

GRANT EXECUTE ON PROCEDURE `API_CustClosingBalance_Get` TO 'affiliate_api'@'%';