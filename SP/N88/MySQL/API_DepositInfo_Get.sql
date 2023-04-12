USE Siebog;

DROP PROCEDURE IF EXISTS `API_DepositInfo_Get`;

DELIMITER //

CREATE DEFINER=`affiliate_api`@`%` PROCEDURE `API_DepositInfo_Get`(
  IN Id INT,
  IN UpdatedTime DATETIME,
  IN batchCount INT
  /*
    Created: 20200714@Percy
    DB: Slave DB/Siebog
    Task: Get DepositInfo data
    
    Revisions:
      - 20200714@Percy: Initialize SP
	  - 20200818@Percy: Get all columns
	  - 20230203@Malcolm: Get data by updatetime and DepositId [RedmineId: #183319]

  */
)
BEGIN
	
	DECLARE CurrentTime DATETIME;
	SELECT DATE_ADD(UTC_TIMESTAMP(), INTERVAL -1 MINUTE) INTO CurrentTime;
	
	SELECT d.*
    FROM `DepositInfo` d
    WHERE ((d.UpdateTime = UpdatedTime AND d.DepositId > Id) OR d.UpdateTime > UpdatedTime) AND (d.UpdateTime < CurrentTime)
	ORDER BY d.UpdateTime ASC, d.DepositId ASC
    LIMIT batchCount;
	
END

//
DELIMITER ;

GRANT EXECUTE ON PROCEDURE `API_DepositInfo_Get` TO 'affiliate_api'@'%';