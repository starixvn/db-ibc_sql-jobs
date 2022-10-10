/*<info serverAlias="DBB2C" databaseType="2" executers="affiliate_api" isFunction="0" isNested="0"></info>*/
USE Siebog;

DROP PROCEDURE IF EXISTS `N88_Get_TpBetRecord_Dynamic`;

DELIMITER //

CREATE DEFINER=`affiliate_api`@`%` PROCEDURE `N88_Get_TpBetRecord_Dynamic`(
  IN fromDate DATETIME,
  IN toDate DATETIME,
  IN pageIndex INT,
  IN pageSize INT

  /*
    Created: 20220922@Sol
    DB: Siebog
    Task: Get data from TpBetRecord and archive tables
    
    Revisions:
		- 20220922@Sol: Initialize SP
		        
	Param's Explanation
		fromDate, toDate: every 30 mins
		pageSize: max is 2000
  */
)
BEGIN
	DECLARE _offSet INT;
    DECLARE	currDate datetime;
    
    -- statement
    SET @cmd = "";
    SET @state_select = "SELECT TpId,TransId,GameType,CustId,UserName,CurrencyId,SiteId,TpUserName,TransTime,SettledTime,Stake,WinlostAmount,SettlementType,TicketStatus,OriginalState,TicketKey,CreateTime,ValidBet,BonusId,Revenue,ProgressiveBet,ProgressiveWin";
	SET @state_from = " FROM TpBetRecord";
    SET @state_where = " WHERE SettledTime BETWEEN ";
    SET @state_AndOperator = " AND ";
    SET @state_Semicolon = ";";
    SET @state_UnionAll = " UNION All ";
    SET @isHasSelect = 0;
    
    -- variable
    SET @date14 = CAST(TIMESTAMPADD(DAY, -14, CURRENT_DATE) AS DATE);
    SET @monthFromDate = "";
    SET @monthToDate = "";
    
    -- size per call
    SET pageSize = IF(pageSize > 2000, 2000, pageSize); -- maximum is 2000
    SET _offSet = pageIndex * pageSize;
    
	IF (fromdate >= @date14) THEN
		BEGIN -- only get data from current TpBetRecord
			SET @cmd = CONCAT_WS('\n',@cmd,@state_select,@state_from,@state_where,CONCAT("'",fromdate, "'"),@state_AndOperator,CONCAT("'",todate, "'"));
            SET @isHasSelect = 1;
			-- select @cmd;
		END;
	ELSE -- data from multiple table
		BEGIN
			IF (todate >= @date14) THEN
				BEGIN
					-- get from main table - #1
					SET @cmd = CONCAT_WS('\n',@cmd,@state_select,@state_from,@state_where,CONCAT("'",@date14, "'"),@state_AndOperator,CONCAT("'",todate, "'"));
                    SET @isHasSelect = 1;
				END;
			END IF;
            
            -- get month of fromdate/(todate - 1)
			SET @monthFromDate = DATE_FORMAT(fromdate,"%Y%m");
			SET @monthToDate = DATE_FORMAT(TIMESTAMPADD(day, -1, @date14),"%Y%m");
			
			-- check month to get correct archive tables
			IF (@monthFromDate = @monthToDate) THEN
				BEGIN
					-- get from archive tables - #2
					SET @cmd = CONCAT_WS('\n',@cmd,IF(@isHasSelect = 1, @state_UnionAll, ""),@state_select,CONCAT(@state_from,"_",@monthFromDate),@state_where,CONCAT("'",fromdate, "'"),@state_AndOperator,CONCAT("'",todate, "'"));
				END;
			ELSE
				BEGIN
					-- get from archive tables - #3
					SET @cmd = CONCAT_WS('\n',@cmd,IF(@isHasSelect = 1, @state_UnionAll, ""),@state_select,CONCAT(@state_from,"_",@monthFromDate),@state_where,CONCAT("'",fromdate, "'"),@state_AndOperator,CONCAT("'",todate, "'"));
					SET @cmd = CONCAT_WS('\n',@cmd,@state_UnionAll,@state_select,CONCAT(@state_from,"_",@monthToDate),@state_where,CONCAT("'",fromdate, "'"),@state_AndOperator,CONCAT("'",todate, "'"));
				END;
			END IF;
			
		END;
	END IF;
    
	SET @cmd = CONCAT_WS('\n', @cmd, 'ORDER BY TpID, TransId, GameType  LIMIT', _offSet, ',',pageSize, @state_Semicolon);
    
    -- return result to caller
	PREPARE stmt FROM @cmd;
	EXECUTE stmt;
	DEALLOCATE PREPARE stmt;
END

//
DELIMITER ;

-- GRANT EXECUTE ON PROCEDURE `N88_Get_TpBetRecord_Dynamic` TO 'affiliate_api'@'%';