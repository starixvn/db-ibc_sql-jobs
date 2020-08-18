USE Siebog;

DROP PROCEDURE IF EXISTS `API_WithdrawalInfo_Get`;

DELIMITER //

CREATE DEFINER=`affiliate_api`@`%` PROCEDURE `API_WithdrawalInfo_Get`(
  IN Id INT,
  IN batchCount SMALLINT
  /*
    Created: 20200714@Percy
    DB: Slave DB/Siebog
    Task: Get DepositInfo data
    
    Revisions:
      - 20200714@Percy: Initialize SP

  */
)
BEGIN
	SET batchCount = IF(batchCount > 2000, 2000, batchCount);

	SELECT 
		*
	FROM
		WithdrawalInfo
	WHERE
		WithdrawalInfo.WithdrawalId > Id
	LIMIT batchCount;
END

//
DELIMITER ;

GRANT EXECUTE ON PROCEDURE `API_WithdrawalInfo_Get` TO 'affiliate_api'@'%';