USE Siebog;

DROP PROCEDURE IF EXISTS `API_Customer_Unlock`;

DELIMITER //

CREATE DEFINER=`affiliate_api`@`%` PROCEDURE `API_Customer_Unlock`(
	IN CustIdList JSON
	/*
		Created: 20210803@Percy
		DB: Slave DB/Siebog
		Task: Unlock affiliate payment accounts
    
		Revisions:
			- 20210803@Percy: Initialize SP
  */
)
BEGIN
    DECLARE CURSOR_CustID INT;
	DECLARE done INT DEFAULT FALSE;
	DECLARE cursor_CustEnroll CURSOR FOR
	    SELECT C.CustId
        FROM Customer AS C
        WHERE C.CustId IN (SELECT List.CustId FROM JSON_TABLE(CustIdList, '$[*]' COLUMNS (`CustId` INT PATH "$")) AS List)
            AND C.Status = 4; -- locked
            
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    OPEN cursor_CustEnroll;
    
    loop_through_rows: LOOP
		FETCH cursor_CustEnroll INTO CURSOR_CustID;
		IF done THEN
			LEAVE loop_through_rows;
            END IF;
            
		-- unlock player
        UPDATE Customer AS C
        SET C.Status = 1 -- running
            ,C.ActStatus = 2 -- deposited
        WHERE C.CustId = CURSOR_CustID;
        
        -- add notes
        CALL Admin_CustNotes_Ins(CURSOR_CustID, 'Aff player account for withdrawal', 'AFF System');
        END LOOP;
        
	CLOSE cursor_CustEnroll;
END

//
DELIMITER ;

GRANT EXECUTE ON PROCEDURE `API_Customer_Unlock` TO 'affiliate_api'@'%';