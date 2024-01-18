USE Siebog;

DROP PROCEDURE IF EXISTS `API_Get_TpGameType`;

DELIMITER //

CREATE DEFINER=`affiliate_api`@`%` PROCEDURE `API_Get_TpGameType`(
  /*
	Created: 20240115@Sally
    DB: YashBet DB/Siebog
    Task: Get TpGameType table 

	Revisions:
		- 20240115@Sally: Initialize SP

  */
)
BEGIN
  SELECT t.*
    FROM `TpGameType` t;
END

//
DELIMITER ;

GRANT EXECUTE ON PROCEDURE `API_Get_TpGameType` TO 'affiliate_api'@'%';