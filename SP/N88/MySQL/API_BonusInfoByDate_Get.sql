USE Siebog;

DROP PROCEDURE IF EXISTS `API_BonusInfoByDate_Get`;

DELIMITER //

CREATE DEFINER=`affiliate_api`@`%` PROCEDURE `API_BonusInfoByDate_Get`(
  IN CalledTime DATETIME,
  IN pageIndex INT,
  IN pageSize INT
  /*
    Created: 20230321@Malcolm
    DB: Slave DB/Siebog
    Task: Get BonusInfo data Weekly
    
    Revisions:
      - 20230321@Malcolm: Initialize SP

  */
)
BEGIN
	DECLARE _offSet INT;
    
	SET pageSize = IF(pageSize > 2000, 2000, pageSize);
	SET _offSet = pageIndex * pageSize;
	
	SELECT 
		* 
	FROM
		BonusInfo
	WHERE
		BonusInfo.CreateTime >= CalledTime AND BonusInfo.CreateTime < DATE_ADD(CalledTime, INTERVAL +1 DAY) 
	ORDER BY BonusInfo.CreateTime ASC
	LIMIT _offSet, pageSize;
	
END

//
DELIMITER ;

GRANT EXECUTE ON PROCEDURE `API_BonusInfoByDate_Get` TO 'affiliate_api'@'%';