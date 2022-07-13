DROP PROCEDURE IF EXISTS Admin_CustNotes_Ins;
DELIMITER $$
CREATE  PROCEDURE `Admin_CustNotes_Ins`(
	IN CustId INT,
    IN `Note` VARCHAR(500),
    IN Operator VARCHAR(30)
)
BEGIN
	
		INSERT INTO `CustNotes`
		(`CustId`,
		`Note`,
		`Operator`)
		VALUES
		(CustId,
		Note,
		Operator);

END $$ 
DELIMITER ; 

GRANT EXECUTE ON PROCEDURE `API_AdjustmentInfo_Get` TO 'affiliate_api'@'%';