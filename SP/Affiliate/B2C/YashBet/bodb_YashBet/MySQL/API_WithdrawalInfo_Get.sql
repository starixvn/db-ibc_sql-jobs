/*<info serverAlias="DBB2C-YashBet databaseType="2" executers="affiliate_api" isFunction="0" isNested="0" </info>*/
USE Siebog;

DROP PROCEDURE IF EXISTS `API_WithdrawalInfo_Get`;

DELIMITER //

CREATE DEFINER=`affiliate_api`@`%` PROCEDURE `API_WithdrawalInfo_Get`(
  IN UpdateTime DATETIME,
  IN BatchCount SMALLINT
  /*
    Created: 20240115@Sally
    DB: YashBet DB/Siebog
    Task: Get DepositInfo data
    
	Revisions:
		- 20240115@Sally: Initialize SP

  */
)
BEGIN
	SET BatchCount = IF(BatchCount > 2000, 2000, BatchCount);

	SELECT *
	FROM WithdrawalInfo
	WHERE WithdrawalInfo.UpdateTime >= UpdateTime
	ORDER BY WithdrawalInfo.UpdateTime
	LIMIT BatchCount;
END

//
DELIMITER ;

GRANT EXECUTE ON PROCEDURE `API_WithdrawalInfo_Get` TO 'affiliate_api'@'%';