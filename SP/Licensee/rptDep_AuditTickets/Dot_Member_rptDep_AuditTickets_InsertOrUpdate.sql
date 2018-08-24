/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="" viewers="vnteam" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE [dbo].[Dot_Member_rptDep_AuditTickets_InsertOrUpdate]
	     @Playerno INT,
		@Playername  VARCHAR(100),
		@Playertype VARCHAR(10),
		@Transactiondate datetime,
		@Transactionid BIGINT,
		@Settlementdate  datetime,
		@Brand VARCHAR(50),
		@Brandurl  VARCHAR(100),
		@Gamecode VARCHAR(10),
		@Gamename VARCHAR(100),
		@Gametype VARCHAR(50),
		@Currencycode  VARCHAR(10),
		@Bettype VARCHAR(100),
		@Betamount money,
		@Debitamount money,
		@Creditamount money,
		@Netamount money
AS
/*  Created: 20180816@TW
    Description: Insert Or Update rptDepatTickets
    DB: DBLIC.bodb_LicenseeReport
   
    Revisions:  
		- 20180816@TW: Created SP to Insert/Update rptDepatTickets [RedmineID: #99777]
*/
     BEGIN
         SET NOCOUNT ON;
		  BEGIN
                 IF EXISTS
                 (
                     SELECT Transactionid
                     FROM dbo.rptDep_AuditTickets WITH (NOLOCK)
                     WHERE Transactionid = @Transactionid 
                 )
                     BEGIN
						UPDATE [dbo].[rptDep_AuditTickets]
						   SET [Playerno] = @Playerno
							  ,[Playername] = @Playername
							  ,[Playertype] = @Playertype
							  ,[Transactiondate] =  @Transactiondate
							  ,[Settlementdate] = @Settlementdate
							  ,[Brand] = @Brand
							  ,[Brandurl] = @Brandurl
							  ,[Gamecode] = @Gamecode
							  ,[Gamename] = @Gamename
							  ,[Gametype] = @Gametype
							  ,[Currencycode] = @Currencycode
							  ,[Bettype] = @Bettype
							  ,[Betamount] = @Betamount
							  ,[Debitamount] = @Debitamount
							  ,[Creditamount] = @Creditamount
							  ,[Netamount] = @Netamount
						 WHERE Transactionid = @Transactionid 

                 END;
                ELSE
                     BEGIN
						 INSERT INTO [dbo].[rptDep_AuditTickets]
							   ([Playerno]
							   ,[Playername]
							   ,[Playertype]
							   ,[Transactiondate]
							   ,[Transactionid]
							   ,[Settlementdate]
							   ,[Brand]
							   ,[Brandurl]
							   ,[Gamecode]
							   ,[Gamename]
							   ,[Gametype]
							   ,[Currencycode]
							   ,[Bettype]
							   ,[Betamount]
							   ,[Debitamount]
							   ,[Creditamount]
							   ,[Netamount])
						 VALUES
								(@Playerno
							   ,@Playername
							   ,@Playertype
							   ,@Transactiondate
							   ,@Transactionid
							   ,@Settlementdate
							   ,@Brand
							   ,@Brandurl
							   ,@Gamecode
							   ,@Gamename
							   ,@Gametype
							   ,@Currencycode
							   ,@Bettype
							   ,@Betamount
							   ,@Debitamount
							   ,@Creditamount
							   ,@Netamount)
                 END;
         END;
     END;



GO


