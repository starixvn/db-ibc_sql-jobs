/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="dot_member" viewers="vnteam" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE [dbo].[Dot_Member_rptDep_atTickets_InsertOrUpdate]
	    @player_no INT,
		@player_name  VARCHAR(100),
		@player_type VARCHAR(10),
		@transaction_date datetime,
		@transaction_id BIGINT,
		@settlement_date  datetime,
		@brand VARCHAR(50),
		@brand_url  VARCHAR(100),
		@game_code VARCHAR(10),
		@game_name VARCHAR(100),
		@game_type VARCHAR(50),
		@currency_code  VARCHAR(10),
		@bet_type VARCHAR(100),
		@bet_amount money,
		@debit_amount money,
		@credit_amount money,
		@net_amount money
AS
-- =============================================
-- Author: TW
-- Create date: 20180816
-- Description: Insert Or Update rptDep_atTickets 
-- =============================================
     BEGIN
         SET NOCOUNT ON;
		  BEGIN
                 IF EXISTS
                 (
                     SELECT transaction_id
                     FROM dbo.rptDep_atTickets WITH (NOLOCK)
                     WHERE transaction_id = @transaction_id 
                 )
                     BEGIN
						UPDATE [dbo].[rptDep_atTickets]
						   SET [player_no] = @player_no
							  ,[player_name] = @player_name
							  ,[player_type] = @player_type
							  ,[transaction_date] =  @transaction_date
							  ,[settlement_date] = @settlement_date
							  ,[brand] = @brand
							  ,[brand_url] = @brand_url
							  ,[game_code] = @game_code
							  ,[game_name] = @game_name
							  ,[game_type] = @game_type
							  ,[currency_code] = @currency_code
							  ,[bet_type] = @bet_type
							  ,[bet_amount] = @bet_amount
							  ,[debit_amount] = @debit_amount
							  ,[credit_amount] = @credit_amount
							  ,[net_amount] = @net_amount
						 WHERE transaction_id = @transaction_id 

                 END;
                ELSE
                     BEGIN
						 INSERT INTO [dbo].[rptDep_atTickets]
							   ([player_no]
							   ,[player_name]
							   ,[player_type]
							   ,[transaction_date]
							   ,[transaction_id]
							   ,[settlement_date]
							   ,[brand]
							   ,[brand_url]
							   ,[game_code]
							   ,[game_name]
							   ,[game_type]
							   ,[currency_code]
							   ,[bet_type]
							   ,[bet_amount]
							   ,[debit_amount]
							   ,[credit_amount]
							   ,[net_amount])
						 VALUES
								(@player_no
							   ,@player_name
							   ,@player_type
							   ,@transaction_date
							   ,@transaction_id
							   ,@settlement_date
							   ,@brand
							   ,@brand_url
							   ,@game_code
							   ,@game_name
							   ,@game_type
							   ,@currency_code
							   ,@bet_type
							   ,@bet_amount
							   ,@debit_amount
							   ,@credit_amount
							   ,@net_amount)
                 END;
         END;
     END;



GO


