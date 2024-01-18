/*<info serverAlias="DBB2C-YashBet databaseType="2" executers="affiliate_api" isFunction="0" isNested="0" </info>*/
USE Siebog;

DROP PROCEDURE IF EXISTS `API_DepositInfo_Get`;

DELIMITER //

CREATE DEFINER=`affiliate_api`@`%` PROCEDURE `API_DepositInfo_Get`(
  IN Id INT,
  IN UpdatedTime DATETIME,
  IN batchCount INT
/*
    Created: 20240115@Sally
    DB: YashBet DB/Siebog
    Task: Get DepositInfo data
    
	Revisions:
		- 20240115@Sally: Initialize SP

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