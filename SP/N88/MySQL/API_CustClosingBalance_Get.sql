USE Siebog;

DROP PROCEDURE IF EXISTS `API_CustClosingBalance_Get`;

DELIMITER //

CREATE DEFINER=`affiliate_api`@`%` PROCEDURE `API_CustClosingBalance_Get`(
  IN lastGetTime DATETIME,
  IN pageIndex INT,
  IN pageSize INT
  /*
    Created: 20210525@Percy
    DB: Slave DB/Siebog
    Task: Get CustClosingBalance data
    
    Revisions:
      - 20210525@Percy: Initialize SP

  */
)
BEGIN
	DECLARE _offSet INT;
	
    SET pageSize = IF(pageSize > 2000, 2000, pageSize);
    SET _offSet = pageIndex * pageSize;
	
    SELECT 
		*
	FROM
		CustClosingBalance
	WHERE
		CustClosingBalance.Time >= lastGetTime
	LIMIT _offSet, pageSize;
END

//
DELIMITER ;

GRANT EXECUTE ON PROCEDURE `API_CustClosingBalance_Get` TO 'affiliate_api'@'%';