USE Siebog;

DROP PROCEDURE IF EXISTS `API_LogAdminAdjustWallet_Get`;

DELIMITER //

CREATE DEFINER=`affiliate_api`@`%` PROCEDURE `API_LogAdminAdjustWallet_Get`(
  IN Id INT,
  IN batchCount INT
  /*
    Created: 20211118@Percy
    DB: Siebog
    Task: Get LogAdminAdjustWallet data
    
    Revisions:
      - 20211118@Percy: Initialize SP

  */
)
BEGIN
	SET batchCount = IF(batchCount > 2000, 2000, batchCount);
    
	SELECT 
		* 
	FROM
		LogAdminAdjustWallet
	WHERE
		LogAdminAdjustWallet.TransferId BETWEEN Id + 1 AND Id + batchCount;
END

//
DELIMITER ;

GRANT EXECUTE ON PROCEDURE `API_LogAdminAdjustWallet_Get` TO 'affiliate_api'@'%';