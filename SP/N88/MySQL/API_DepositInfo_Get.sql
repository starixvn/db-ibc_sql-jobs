USE Siebog;

DROP PROCEDURE IF EXISTS `API_DepositInfo_Get`;

DELIMITER //

CREATE DEFINER=`aff_user`@`%` PROCEDURE `API_DepositInfo_Get`(
  IN Id INT,
  IN batchCount INT
  /*
    Created: 20200714@Percy
    DB: Slave DB/Siebog
    Task: Get DepositInfo data
    
    Revisions:
      - 20200714@Percy: Initialize SP
	  - 20200818@Percy: Get all columns

  */
)
BEGIN
  SELECT *
    FROM `DepositInfo`
    WHERE DepositId > Id
    LIMIT batchCount;
END

//
DELIMITER ;

GRANT EXECUTE ON PROCEDURE `API_DepositInfo_Get` TO 'affiliate_api'@'%';