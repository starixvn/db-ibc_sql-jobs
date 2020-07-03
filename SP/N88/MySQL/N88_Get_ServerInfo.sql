DROP PROCEDURE IF EXISTS `N88_Get_ServerInfo`;

DELIMITER //

CREATE DEFINER=`aff_user`@`%` PROCEDURE `N88_Get_ServerInfo`(
  /*
    Created: 20200520@Percy
    DB: Slave DB/Siebog
    Task: Get ServerInfo table
    
    Revisions:
      - 20200520@Percy: Initialize SP

  */
)
BEGIN
  SELECT s.*
    FROM `ServerInfo` s;
END

//
DELIMITER ;

GRANT EXECUTE ON PROCEDURE `N88_Get_ServerInfo` TO 'affiliate_api'@'%';