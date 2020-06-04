DROP PROCEDURE IF EXISTS `N88_Get_TpGameType`;

DELIMITER //

CREATE DEFINER=`aff_user`@`%` PROCEDURE `N88_Get_TpGameType`(
  /*
    Created: 20200520@Percy
    DB: Slave DB/Siebog
    Task: Get TpGameType table
    
    Revisions:
      - 20200520@Percy: Initialize SP

  */
)
BEGIN
  SELECT t.*
    FROM `TpGameType` t;
END

//
DELIMITER ;

GRANT EXECUTE ON PROCEDURE `N88_Get_TpGameType` TO 'affiliate_api'@'%';