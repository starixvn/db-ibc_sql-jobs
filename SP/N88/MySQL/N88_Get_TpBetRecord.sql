USE Siebog;

DROP PROCEDURE IF EXISTS `N88_Get_TpBetRecord`;

DELIMITER //

CREATE DEFINER=`affiliate_api`@`%` PROCEDURE `N88_Get_TpBetRecord`(
  IN fromDate DATETIME,
  IN toDate DATETIME
  /*
    Created: 20200220@Percy
    DB: Slave DB/Siebog
    Task: Get data from TpBetRecord table
    
    Revisions:
    - 20200220@Percy: Initialize SP

  */
)
BEGIN
  SELECT *
    FROM `TpBetRecord` t
    WHERE t.SettledTime BETWEEN fromDate AND toDate;
END

//
DELIMITER ;

GRANT EXECUTE ON PROCEDURE `N88_Get_TpBetRecord` TO 'affiliate_api'@'%';