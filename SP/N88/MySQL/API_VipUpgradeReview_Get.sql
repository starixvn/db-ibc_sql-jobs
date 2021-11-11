USE Siebog;

DROP PROCEDURE IF EXISTS `API_VipUpgradeReview_Get`;

DELIMITER //

CREATE DEFINER=`affiliate_api`@`%` PROCEDURE `API_VipUpgradeReview_Get`(
	IN MonthDate CHAR(6),
	IN pageIndex INT,
	IN pageSize INT
	/*
		Created: 20211010@Percy
		DB: Siebog
		Task: Get VipUpgradeReview data
		
		Revisions:
		  - 20211010@Percy: Initialize SP
	*/
)
BEGIN
	DECLARE _offSet INT;
	
    SET pageSize = IF(pageSize > 2000, 2000, pageSize);
    SET _offSet = pageIndex * pageSize;
    
	SELECT 
		* 
	FROM
		VipUpgradeReview
	WHERE
		VipUpgradeReview.CalculateMonth COLLATE utf8mb4_general_ci = MonthDate
	LIMIT _offSet, pageSize;
END

//
DELIMITER ;

GRANT EXECUTE ON PROCEDURE `API_VipUpgradeReview_Get` TO 'affiliate_api'@'%';