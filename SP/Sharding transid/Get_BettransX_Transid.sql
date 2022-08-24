/*<info serverAlias="DBTXN-bodb02" executers="Dot_Member,Dot_Intg,Dot_Bonus,bodbAdminNet,bodbDownlineNet" isFunction="0" isNested="0"></info>*/

create PROCEDURE [dbo].[Get_BettransX_Transid] 
(
	@transid bigint OUTPUT,
	@sourceID bigint = NULL
)
AS
/*
	Created: 20220726@Lukas
	DB: DBTXN.bodb02
	Task: 158293 - Scale out bettrans phase 1

	Revisions:
		- 20220726@Lukas: Create [RedmineID: #158293]
*/
BEGIN
	 
	DECLARE @nextseq BIGINT

	IF @sourceID IS NULL
	BEGIN
		SELECT @sourceID =  
			CASE	
				WHEN @@SERVERNAME in ('DBTRANS','SITDBTRANS','TESTDBTRANS','db-60\devdbtrans') THEN 0
				WHEN @@SERVERNAME IN ('DBGRP01N1','DBGRP01N2','SITDBGRP01N1','SITDBGRP01N2','db62\DEVSITEDB','testdb053\TESTSITEDB') THEN 1
			ELSE 1023 END
	END 
 
	SELECT	@transid = DATEDIFF_BIG(SECOND, '2022-07-01 00:00:00', GETUTCDATE())
	
	     IF @transid % 10 = 0 		set @nextseq = next value for dbo.seq_betX00
	ELSE IF @transid % 10 = 1		set @nextseq = next value for dbo.seq_betX01
	ELSE IF @transid % 10 = 2		set @nextseq = next value for dbo.seq_betX02
	ELSE IF @transid % 10 = 3		set @nextseq = next value for dbo.seq_betX03
	ELSE IF @transid % 10 = 4		set @nextseq = next value for dbo.seq_betX04
	ELSE IF @transid % 10 = 5		set @nextseq = next value for dbo.seq_betX05
	ELSE IF @transid % 10 = 6		set @nextseq = next value for dbo.seq_betX06
	ELSE IF @transid % 10 = 7		set @nextseq = next value for dbo.seq_betX07
	ELSE IF @transid % 10 = 8		set @nextseq = next value for dbo.seq_betX08
	ELSE IF @transid % 10 = 9		set @nextseq = next value for dbo.seq_betX09

	-- 1 + 31 + 10 + 22
	-- shift <time> left by 32 for site + sequence
	-- shift <site> left by 22 for sequence
	SELECT @transid = (@transid * 0x0000000100000000) | (@sourceID * 4194304) | @nextseq

END
GO