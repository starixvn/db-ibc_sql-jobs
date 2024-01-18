/*<info serverAlias="DBB2C-YashBet databaseType="2" executers="affiliate_api" isFunction="0" isNested="0" </info>*/
USE Siebog;

DROP PROCEDURE IF EXISTS `API_BonusInfo_Get`;

DELIMITER //

CREATE DEFINER=`affiliate_api`@`%` PROCEDURE `API_BonusInfo_Get`(
  IN Id INT,
  IN batchCount INT
  /*
    Created: 20240115@Sally
    DB: YashBet DB/Siebog
    Task: Get BonusInfo data
    
	Revisions:
		- 20240115@Sally: Initialize SP

  */
)
BEGIN
	SET batchCount = IF(batchCount > 2000, 2000, batchCount);
    
	SELECT 
		* 
	FROM
		BonusInfo
	WHERE
		BonusInfo.BonusId > Id
	LIMIT batchCount;
END

//
DELIMITER ;

GRANT EXECUTE ON PROCEDURE `API_BonusInfo_Get` TO 'affiliate_api'@'%';