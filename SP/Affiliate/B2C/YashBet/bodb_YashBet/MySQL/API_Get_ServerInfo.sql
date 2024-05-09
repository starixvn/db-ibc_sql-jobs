/*<info serverAlias="DBB2C-YashBet databaseType="2" executers="affiliate_api" isFunction="0" isNested="0" </info>*/
USE Siebog;

DROP PROCEDURE IF EXISTS `API_Get_ServerInfo`;

DELIMITER //

CREATE DEFINER=`affiliate_api`@`%` PROCEDURE `API_Get_ServerInfo`(
  /*
    Created: 20240115@Sally
    DB: YashBet DB/Siebog
    Task: Get ServerInfo table
    
	Revisions:
		- 20240115@Sally: Initialize SP

  */
)
BEGIN
  SELECT s.*
    FROM `ServerInfo` s;
END

//
DELIMITER ;

GRANT EXECUTE ON PROCEDURE `API_Get_ServerInfo` TO 'affiliate_api'@'%';