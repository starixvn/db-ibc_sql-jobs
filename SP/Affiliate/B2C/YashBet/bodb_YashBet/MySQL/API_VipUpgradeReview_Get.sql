/*<info serverAlias="DBB2C-YashBet databaseType="2" executers="affiliate_api" isFunction="0" isNested="0" </info>*/
USE Siebog;

DROP PROCEDURE IF EXISTS `API_VipUpgradeReview_Get`;

DELIMITER //

CREATE DEFINER=`affiliate_api`@`%` PROCEDURE `API_VipUpgradeReview_Get`(
	IN MonthDate CHAR(6),
	IN pageIndex INT,
	IN pageSize INT
/*
    Created: 20240115@Sally
    DB: YashBet DB/Siebog
	Task: Get VipUpgradeReview data
		
	Revisions:
		- 20240115@Sally: Initialize SP

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