USE Siebog;

DROP PROCEDURE IF EXISTS `API_EventDraw_Get`;

DELIMITER //

CREATE DEFINER=`affiliate_api`@`%` PROCEDURE `API_EventDraw_Get`(
  IN Id INT,
  IN batchCount INT
  /*
    Created: 20211010@Percy
    DB: Siebog
    Task: Get EventDraw data
    
    Revisions:
      - 20211010@Percy: Initialize SP

  */
)
BEGIN
	SET batchCount = IF(batchCount > 2000, 2000, batchCount);
    
	SELECT 
		* 
	FROM
		EventDraw
	WHERE
		EventDraw.EventId > Id
	LIMIT batchCount;
END

//
DELIMITER ;

GRANT EXECUTE ON PROCEDURE `API_EventDraw_Get` TO 'affiliate_api'@'%';