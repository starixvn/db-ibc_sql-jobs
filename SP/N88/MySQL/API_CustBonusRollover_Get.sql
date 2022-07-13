DROP PROCEDURE IF EXISTS API_CustBonusRollover_Get;
DELIMITER $$
CREATE  PROCEDURE `API_CustBonusRollover_Get`(
  IN Id INT,
  IN batchCount INT
  
)
BEGIN
  SET batchCount = IF(batchCount > 2000, 2000, batchCount);
    
  SELECT 
    * 
  FROM
    CustBonusRollover
  WHERE
    CustBonusRollover.BonusId > Id
  LIMIT batchCount;
END $$ 
DELIMITER ; 

GRANT EXECUTE ON PROCEDURE `API_AdjustmentInfo_Get` TO 'affiliate_api'@'%';