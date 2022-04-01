USE Siebog;

DROP PROCEDURE IF EXISTS `API_CustVerificationReward_Get`;

DELIMITER //

CREATE DEFINER=`affiliate_api`@`%` PROCEDURE `API_CustVerificationReward_Get`(
  IN lastRewardTime DATETIME,
  IN conditionField VARCHAR(128),
  IN batchCount INT
  /*
    Created: 20220325@Percy
    DB: Siebog
    Task: Get CustVerificationReward data
    
    Revisions:
      - 20220325@Percy: Initialize SP

  */
)
BEGIN
	SET batchCount = IF(batchCount > 2000, 2000, batchCount);
    
    IF conditionField = 'PhoneRewardTime' THEN
		SELECT
			*
		FROM CustVerificationReward
        WHERE CustVerificationReward.PhoneRewardTime > lastRewardTime
        ORDER BY CustVerificationReward.PhoneRewardTime
        LIMIT batchCount;
	ELSEIF conditionField = 'EmailRewardTime' THEN
		SELECT
			*
		FROM CustVerificationReward
        WHERE CustVerificationReward.EmailRewardTime > lastRewardTime
        ORDER BY CustVerificationReward.EmailRewardTime
        LIMIT batchCount;
	END IF;
END

//
DELIMITER ;

GRANT EXECUTE ON PROCEDURE `API_CustVerificationReward_Get` TO 'affiliate_api'@'%';