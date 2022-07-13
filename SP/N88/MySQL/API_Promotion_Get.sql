DROP PROCEDURE IF EXISTS API_Promotion_Get;
DELIMITER $$
CREATE  PROCEDURE `API_Promotion_Get`(
  IN fromDate DATETIME,
  IN toDate DATETIME
  
)
BEGIN
  SELECT
    CONVERT_TZ(FROM_UNIXTIME(PeriodFrom), @@SESSION.time_zone, '+00:00') AS StartDate
    ,CONVERT_TZ(FROM_UNIXTIME(PeriodTo), @@SESSION.time_zone, '+00:00') AS EndDate
    ,Promotion.*
  FROM
    Promotion
  WHERE
    Promotion.CreateTime BETWEEN fromDate AND toDate
  UNION
    SELECT
    CONVERT_TZ(FROM_UNIXTIME(PeriodFrom), @@SESSION.time_zone, '+00:00') AS StartDate
    ,CONVERT_TZ(FROM_UNIXTIME(PeriodTo), @@SESSION.time_zone, '+00:00') AS EndDate
    ,Promotion.*
  FROM
    Promotion
  WHERE
    Promotion.LastUpdateTime BETWEEN fromDate AND toDate;
END $$ 
DELIMITER ;

GRANT EXECUTE ON PROCEDURE `API_AdjustmentInfo_Get` TO 'affiliate_api'@'%';