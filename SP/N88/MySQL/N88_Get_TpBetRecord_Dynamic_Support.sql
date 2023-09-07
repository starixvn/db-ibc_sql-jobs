USE Siebog;

DROP PROCEDURE IF EXISTS `N88_Get_TpBetRecord_Dynamic_Support`;

DELIMITER //

CREATE DEFINER=`afc_api`@`%` PROCEDURE `N88_Get_TpBetRecord_Dynamic_Support`(
  IN fromDate DATETIME,
  IN toDate DATETIME,
  IN siteId INT,
  IN gameType VARCHAR(1000), 
  IN custId VARCHAR(45),
  IN currency VARCHAR(1000),
  IN getDataType TINYINT,
  IN IsCheckedDiffDate BIT,
  IN pageIndex INT,
  IN pageSize INT
  /*
    Created: 20230821@Sally
    DB: Siebog
    Task: Get data from TpBetRecord and archive tables with more supported parameters
    
    Revisions:
		- 20230821@Sally: Initialize SP
		        
	Param's Explanation
		siteId: NULL: no filter 
        custId: NULL: no filter
        gameType: 
			. array list gametype '1,2,3,5'
            . NULL: no filter
		currency:
			. array list currency '1,2,3,5'
            . NULL: no filter
        getDataType: 
			. 1 : Just get summary data 
			. 2 : get data with paging
		IsCheckedDiffDate 
			. 0 : no filter
			. 1 : get data with differency between CreateTime and SettledTime
  */
)
BEGIN
	DECLARE _offSet INT;
    DECLARE	currDate DATETIME;

	N88_Get_TpBetRecord_Dynamic_Support_Validate: 
    BEGIN	
		-- Validate Parameters
		IF(fromDate IS NULL OR toDate IS NULL OR getDataType IS NULL) THEN
			LEAVE N88_Get_TpBetRecord_Dynamic_Support_Validate;
		END IF;
		IF(getDataType = 2 AND (pageIndex IS NULL OR pageSize IS NULL)) THEN
			LEAVE N88_Get_TpBetRecord_Dynamic_Support_Validate;
		END IF;
		
		-- statement
		SET @cmd = "";
		SET @state_Sum = "SELECT SUM(TotalRows) AS TotalRows, SUM(Stake) AS Stake, SUM(WinlostAmount) AS WinlostAmount, SUM(ValidBet) AS ValidBet, SUM(Revenue) AS Revenue, SUM(ProgressiveBet) AS ProgressiveBet, SUM(ProgressiveWin) AS ProgressiveWin" ;
		SET @state_select = CASE WHEN getDataType = 1 THEN "SELECT COUNT(1) AS TotalRows, SUM(Stake) AS Stake, SUM(WinlostAmount) AS WinlostAmount, SUM(ValidBet) AS ValidBet, SUM(Revenue) AS Revenue, SUM(ProgressiveBet) AS ProgressiveBet, SUM(ProgressiveWin) AS ProgressiveWin" 
								ELSE "SELECT TpId,TransId,GameType,CustId,UserName,CurrencyId,SiteId,TpUserName,TransTime,SettledTime,Stake,WinlostAmount,SettlementType,TicketStatus,OriginalState,TicketKey,CreateTime,ValidBet,BonusId,Revenue,ProgressiveBet,ProgressiveWin" 
							END;
		SET @state_from = " FROM TpBetRecord";
		SET @state_where = " WHERE SettledTime BETWEEN ";
		SET @state_AndOperator = " AND ";
		SET @state_Semicolon = ";";
		SET @state_UnionAll = " UNION All ";
		SET @isHasSelect = 0;
		SET @Parentheses_start = "(";
		SET @Parentheses_end = ")";
		SET @state_OrOperator = " OR ";
		SET @state_CustId = " CustId = ";
		SET @state_SiteId = " SiteId = ";
		SET @state_gameType = " GameType IN ";
		SET @state_currency = " CurrencyId IN ";
        SET @state_Comparision = " CAST(SettledTime AS DATE)<> CAST(CreateTime AS DATE) ";

		-- variable
		SET @date14 = CAST(TIMESTAMPADD(day, -14, CURRENT_DATE) AS DATE);
		SET @monthFromDate = "";
		SET @monthToDate = "";
		SET @custId = CONCAT("'",custId,"'") ;
		SET @SiteId = siteId;
		SET @gameType = gameType;
		SET @currency = Currency;
		
		-- size per call
		SET pageSize = IF(pageSize > 5000, 5000, pageSize); -- maximum is 5000
		SET _offSet = pageIndex * pageSize;
        
		-- set default Value
		SET IsCheckedDiffDate = CASE WHEN IsCheckedDiffDate IS NULL THEN 0 ELSE IsCheckedDiffDate END;
        
		IF (fromdate >= @date14) THEN
			BEGIN -- only get data from current TpBetRecord
				SET @cmd = CONCAT_WS('\n'
						,@cmd
						,@state_select
						,@state_from
						,@state_where
						,CONCAT("'",fromdate, "'")
						,@state_AndOperator
						,CONCAT("'",todate, "'")
						,(CASE WHEN @custId IS NOT NULL THEN CONCAT(@state_AndOperator, @state_CustId,@custId) ELSE NULL END)
						,(CASE WHEN @siteId IS NOT NULL THEN CONCAT(@state_AndOperator, @state_SiteId,@siteId) ELSE NULL END)
						,(CASE WHEN @currency IS NOT NULL THEN CONCAT(@state_AndOperator, @state_currency, @Parentheses_start, @currency, @Parentheses_end) ELSE NULL END)
						,(CASE WHEN @gameType IS NOT NULL THEN CONCAT(@state_AndOperator, @state_gameType, @Parentheses_start, @gameType, @Parentheses_end) ELSE NULL END)
                        ,(CASE WHEN IsCheckedDiffDate = 1 THEN CONCAT(@state_AndOperator, @state_Comparision) ELSE NULL END)
					);
				SET @isHasSelect = 1;
				-- select @cmd;
			END;
		ELSE -- data from multiple table
			BEGIN
				IF (todate >= @date14) THEN
					BEGIN
						-- get from main table - #1
						SET @cmd = CONCAT_WS('\n'
								,@cmd
								,@state_select
								,@state_from
								,@state_where
								,CONCAT("'",@date14, "'")
								,@state_AndOperator
								,CONCAT("'",todate, "'")
								,(CASE WHEN @custId IS NOT NULL THEN CONCAT(@state_AndOperator, @state_CustId,@custId) ELSE NULL END)
								,(CASE WHEN @siteId IS NOT NULL THEN CONCAT(@state_AndOperator, @state_SiteId,@siteId) ELSE NULL END)
								,(CASE WHEN @currency IS NOT NULL THEN CONCAT(@state_AndOperator, @state_currency, @Parentheses_start, @currency, @Parentheses_end) ELSE NULL END)
								,(CASE WHEN @gameType IS NOT NULL THEN CONCAT(@state_AndOperator, @state_gameType, @Parentheses_start, @gameType, @Parentheses_end) ELSE NULL END)
                                ,(CASE WHEN IsCheckedDiffDate = 1 THEN CONCAT(@state_AndOperator, @state_Comparision) ELSE NULL END)
							);
						SET @isHasSelect = 1;
					END;
				END IF;
				
				-- get month of fromdate/(todate - 1)
				SET @monthFromDate = DATE_FORMAT(fromdate,"%Y%m");
				SET @monthToDate = DATE_FORMAT(TIMESTAMPADD(day, -1, @date14),"%Y%m");
				
				-- check month to get correct archive tables
				-- get from archive tables - #2
				SET @cmd = CONCAT_WS('\n'
						,@cmd
						,IF(@isHasSelect = 1, @state_UnionAll, "")
						,@state_select
						,CONCAT(@state_from,"_",@monthFromDate)
						,@state_where
						,CONCAT("'",fromdate, "'")
						,@state_AndOperator
						,CONCAT("'",todate, "'")
						,(CASE WHEN @custId IS NOT NULL THEN CONCAT(@state_AndOperator, @state_CustId,@custId) ELSE NULL END)
						,(CASE WHEN @siteId IS NOT NULL THEN CONCAT(@state_AndOperator, @state_SiteId,@siteId) ELSE NULL END)
						,(CASE WHEN @currency IS NOT NULL THEN CONCAT(@state_AndOperator, @state_currency, @Parentheses_start, @currency, @Parentheses_end) ELSE NULL END)
						,(CASE WHEN @gameType IS NOT NULL THEN CONCAT(@state_AndOperator, @state_gameType, @Parentheses_start, @gameType, @Parentheses_end) ELSE NULL END)
                        ,(CASE WHEN IsCheckedDiffDate = 1 THEN CONCAT(@state_AndOperator, @state_Comparision) ELSE NULL END)
					);

				IF (@monthFromDate <> @monthToDate) THEN
					BEGIN
						SET @cmd = CONCAT_WS('\n'
								,@cmd
								,@state_UnionAll
								,@state_select
								,CONCAT(@state_from,"_",@monthToDate)
								,@state_where
								,CONCAT("'",fromdate, "'")
								,@state_AndOperator
								,CONCAT("'",todate, "'")
								,(CASE WHEN @custId IS NOT NULL THEN CONCAT(@state_AndOperator, @state_CustId,@custId) ELSE NULL END)
								,(CASE WHEN @siteId IS NOT NULL THEN CONCAT(@state_AndOperator, @state_SiteId,@siteId) ELSE NULL END)
								,(CASE WHEN @currency IS NOT NULL THEN CONCAT(@state_AndOperator, @state_currency, @Parentheses_start, @currency, @Parentheses_end) ELSE NULL END)
								,(CASE WHEN @gameType IS NOT NULL THEN CONCAT(@state_AndOperator, @state_gameType, @Parentheses_start, @gameType, @Parentheses_end) ELSE NULL END)
                                ,(CASE WHEN IsCheckedDiffDate = 1 THEN CONCAT(@state_AndOperator, @state_Comparision) ELSE NULL END)
							);
					END;
				END IF;
			END;
		END IF;
		IF (getDataType = 1) THEN
		BEGIN
			SET @cmd = CONCAT_WS('\n'
					,@state_Sum
					,"FROM ("
					,@cmd
					,CONCAT(@Parentheses_end,'AS s')
					, @state_Semicolon
				);
		 END;    
		 ELSE
			 BEGIN
					SET @cmd = CONCAT_WS('\n'
					,@cmd
					,'ORDER BY TpID, TransId, GameType  LIMIT'
					,_offSet, ','
					,pageSize
					, @state_Semicolon
				);
			 END;
		 END IF;
		-- select @cmd;
		-- return result to caller
		PREPARE stmt FROM @cmd;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;
	END;
END
//
DELIMITER ;
		
GRANT EXECUTE ON PROCEDURE `N88_Get_TpBetRecord_Dynamic_Support` TO 'affiliate_api'@'%';
GRANT EXECUTE ON PROCEDURE `N88_Get_TpBetRecord_Dynamic_Support` TO 'afc_api'@'%';