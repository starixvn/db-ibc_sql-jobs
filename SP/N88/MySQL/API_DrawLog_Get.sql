USE Siebog;

DROP PROCEDURE IF EXISTS `API_DrawLog_Get`;

DELIMITER //

CREATE DEFINER=`affiliate_api`@`%` PROCEDURE `API_DrawLog_Get`(
  IN Id INT,
  IN batchCount INT
  /*
    Created: 20211010@Percy
    DB: Siebog
    Task: Get DrawLog data
    
    Revisions:
      - 20211010@Percy: Initialize SP
	  - 20230911@Sally: Enhance get data DrawLog [RedmineID: #186979]
      
  */
)
BEGIN
	SET batchCount = IF(batchCount > 2000, 2000, batchCount);
    
	SELECT d.Id
		,d.EventId
		,d.CustId
        ,d.PrizeId
        ,d.PrizeName
        ,d.Amount
        ,d.DrawEventDate
        ,d.DrawTime
        ,c.SiteId
        ,c.CurrencyId
	FROM DrawLog d 
		INNER JOIN Customer c ON d.CustId = c.CustId
	WHERE d.Id > Id
	LIMIT batchCount;
END

//
DELIMITER ;


GRANT EXECUTE ON PROCEDURE `API_DrawLog_Get` TO 'affiliate_api'@'%';
