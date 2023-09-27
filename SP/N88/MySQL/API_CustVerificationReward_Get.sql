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
	  - 20230413@Malcolm: Get rows with PhoneRewardTime = lastRewardTime
      - 20230911@Sally: Enhance get data CustVerificationReward [RedmineID: #186979]

  */
)
BEGIN
	SET batchCount = IF(batchCount > 2000, 2000, batchCount);
    
	IF conditionField = 'PhoneRewardTime' THEN
		SELECT c.CustId
			,c.SiteId
			,c.PhoneReward
			,c.PhoneRewardTime
			,c.EmailReward
			,c.EmailRewardTime
            ,ct.CurrencyId
		FROM CustVerificationReward c
			INNER JOIN Customer ct ON c.CustId = ct.CustId
        WHERE c.PhoneRewardTime >= lastRewardTime
        ORDER BY c.PhoneRewardTime
        LIMIT batchCount;
	ELSEIF conditionField = 'EmailRewardTime' THEN
		SELECT c.CustId
			,c.SiteId
			,c.PhoneReward
			,c.PhoneRewardTime
			,c.EmailReward
			,c.EmailRewardTime
			,ct.CurrencyId
		FROM CustVerificationReward c
			INNER JOIN Customer ct ON c.CustId = ct.CustId
        WHERE c.EmailRewardTime >= lastRewardTime
        ORDER BY c.EmailRewardTime
        LIMIT batchCount;
	END IF;
END

//
DELIMITER ;

GRANT EXECUTE ON PROCEDURE `API_CustVerificationReward_Get` TO 'affiliate_api'@'%';
