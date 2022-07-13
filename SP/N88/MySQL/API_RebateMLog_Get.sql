DROP PROCEDURE IF EXISTS API_RebateMLog_Get;
DELIMITER $$
CREATE  PROCEDURE `API_RebateMLog_Get`(
  IN fromDate DATETIME,
  IN toDate DATETIME
  
)
BEGIN
  SELECT
    *
  FROM
    RebateMLog
  WHERE
    RebateMLog.CreateTime BETWEEN fromDate AND toDate;
END $$ 
DELIMITER ; 

GRANT EXECUTE ON PROCEDURE `API_AdjustmentInfo_Get` TO 'affiliate_api'@'%';