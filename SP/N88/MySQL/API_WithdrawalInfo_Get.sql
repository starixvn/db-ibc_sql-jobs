USE Siebog;

DROP PROCEDURE IF EXISTS `API_WithdrawalInfo_Get`;

DELIMITER //

CREATE DEFINER=`affiliate_api`@`%` PROCEDURE `API_WithdrawalInfo_Get`(
  IN UpdateTime DATETIME,
  IN BatchCount SMALLINT
  /*
    Created: 20200714@Percy
    DB: Slave DB/Siebog
    Task: Get DepositInfo data
    
    Revisions:
      - 20200714@Percy: Initialize SP
      - 20230412@Evan: Pull by updatetime [RedmineID: #186791]

  */
)
BEGIN
	SET BatchCount = IF(BatchCount > 2000, 2000, BatchCount);

	SELECT 
		*
	FROM
		WithdrawalInfo
	WHERE
		WithdrawalInfo.UpdateTime >= UpdateTime
	ORDER BY WithdrawalInfo.UpdateTime
	LIMIT BatchCount;
END

//
DELIMITER ;

GRANT EXECUTE ON PROCEDURE `API_WithdrawalInfo_Get` TO 'affiliate_api'@'%';