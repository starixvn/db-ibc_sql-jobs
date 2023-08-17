USE Siebog;

DROP PROCEDURE IF EXISTS `Affiliate_AffiliateInfo_Set`;

DELIMITER //
CREATE DEFINER=`affiliate_api`@`%` PROCEDURE `Affiliate_AffiliateInfo_Set`(
    IN CustId INT,
    IN SiteId INT,
    IN AffiliateName VARCHAR(30),
    IN ParentAffiliate VARCHAR(30),
    IN AffiliateCode VARCHAR(20),
    IN UserName VARCHAR(30)
)
BEGIN

   IF NOT EXISTS (
        SELECT 1 
        FROM `AffiliateInfo` a
        WHERE a.CustId = CustId
    )
    THEN
        INSERT INTO `Siebog`.`AffiliateInfo` (`CustId`, `SiteId`, `AffiliateName`, `ParentAffiliate`, `AffiliateCode`, `UserName`) 
        VALUES (CustId, SiteId, AffiliateName, ParentAffiliate, AffiliateCode, UserName);
    END IF;
    
    UPDATE `Customer` C
    SET C.MemberType = 2
    WHERE C.CustId = CustId;
            
    INSERT INTO `CustTaskTime` (CustId, TaskId, TaskTime) 
    VALUES (CustId, 5, CURRENT_TIMESTAMP)
    ON DUPLICATE KEY
    UPDATE TaskTime = CURRENT_TIMESTAMP;
    
END
//
DELIMITER ;
GRANT EXECUTE ON PROCEDURE `Affiliate_AffiliateInfo_Set` TO 'affiliate_api'@'%';
