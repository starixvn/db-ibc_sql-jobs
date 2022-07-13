DROP PROCEDURE IF EXISTS API_PromotionSpecific_Get;
DELIMITER $$
CREATE  PROCEDURE `API_PromotionSpecific_Get`(
  IN fromDate DATETIME,
  IN toDate DATETIME
  
)
BEGIN
    SELECT
        *
    FROM
        PromotionSpecific
    WHERE
        PromotionSpecific.CreateTime BETWEEN fromDate AND toDate
    UNION
    SELECT
        *
    FROM
        PromotionSpecific
    WHERE
        PromotionSpecific.UpdateTime BETWEEN fromDate AND toDate;
END $$ 
DELIMITER ; 

GRANT EXECUTE ON PROCEDURE `API_AdjustmentInfo_Get` TO 'affiliate_api'@'%';