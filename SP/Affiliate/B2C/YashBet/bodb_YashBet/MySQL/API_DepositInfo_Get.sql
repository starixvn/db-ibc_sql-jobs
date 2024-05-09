/*<info serverAlias="DBB2C-YashBet databaseType="2" executers="affiliate_api" isFunction="0" isNested="0" </info>*/
USE Siebog;

DROP PROCEDURE IF EXISTS `API_DepositInfo_Get`;

DELIMITER //

CREATE DEFINER=`affiliate_api`@`%` PROCEDURE `API_DepositInfo_Get`(
  IN fromDate DATETIME,
  IN toDate DATETIME,
  IN pageIndex INT,
  IN pageSize INT
/*
    Created: 20240115@Sally
    DB: YashBet DB/Siebog
    Task: Get DepositInfo data
    
	Revisions:
		- 20240115@Sally: Initialize SP
        - 20240304@Sally: Pull data base on FromDate, ToDate and get by PageIndex [Redmine: #201835]
        
	Param's Explanation
		fromDate, toDate: 1 day
		pageSize: max is 2000
 */
)
BEGIN
    DECLARE _offSet INT;	
	-- size per call
    SET pageSize = IF(pageSize > 2000, 2000, pageSize); -- maximum is 2000
    SET _offSet = pageIndex * pageSize;
    
	SELECT d.*
    FROM `DepositInfo` d
    WHERE d.UpdateTime between fromDate AND toDate
	ORDER BY d.UpdateTime ASC, d.DepositId ASC
    LIMIT _offSet, pageSize;	
END

//
DELIMITER ;

GRANT EXECUTE ON PROCEDURE `API_DepositInfo_Get` TO 'affiliate_api'@'%';