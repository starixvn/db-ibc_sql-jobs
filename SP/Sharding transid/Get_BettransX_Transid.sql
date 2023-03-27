/*<info serverAlias="DBTXN-bodb02" executers="Dot_Member,Dot_Intg,Dot_Bonus,bodbAdminNet,bodbDownlineNet" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Get_BettransX_Transid] 
(
	@transid bigint OUTPUT,
	@sourceID BIGINT = NULL
)
AS
/*
	Created: 20220726@Lukas
	DB: DBTXN.bodb02
	Task: 158293 - Scale out bettrans phase 1

	Revisions:
		- 20220726@Lukas: Create [RedmineID: #158293]
		- 20220829@Tina: Using same sequence object with SP Get_Bettrans_Transid
		- 20220912@Tina: add more sitedb2 [RedmineID: #158293]
		- 20220926@Tina: re-set value for param @sourceID [RedmineID: #178213]
						As the beginning, we use @SourceID as input parameter, but after releasing scaleout for phase 1 
						we got some issue related to pass wrong value for this @SourceID. 
						This SP is using for many functions on member site, it's quite risk if we remove this param. 
						So, we keep param as it is and reset this param basing on server name.
		- 20230327@Tina: built up the AlwaysOn Availability Group (AG) feature for sitedb1 (DB66 and DB67)
*/
BEGIN
	 
	DECLARE @nextseq BIGINT

	--IF @sourceID IS NULL -> Please help double check with Lukas or Vivi if you want to uncomment
	--BEGIN
		SELECT @sourceID =  
			CASE	
				WHEN @@SERVERNAME in ('DBTRANS','SITDBTRANS','TESTDBTRANS','db-60\devdbtrans') THEN 0
				WHEN @@SERVERNAME IN ('DBGRP01N1','DBGRP01N2','SITDBGRP01N1','SITDBGRP01N2','db62\DEVSITEDB','testdb053\TESTSITEDB','DB66','DB67') THEN 1
				WHEN @@SERVERNAME IN ('DBGRP02N1','DBGRP02N2','SITDBGRP02N1','SITDBGRP02N2') THEN 2
			ELSE 1023 END
	--END 
 
	SELECT	@transid = DATEDIFF_BIG(SECOND, '2022-07-01 00:00:00', GETUTCDATE())

	     IF @transid % 10 = 0 		set @nextseq = next value for dbo.seq_bet00
	ELSE IF @transid % 10 = 1		set @nextseq = next value for dbo.seq_bet01
	ELSE IF @transid % 10 = 2		set @nextseq = next value for dbo.seq_bet02
	ELSE IF @transid % 10 = 3		set @nextseq = next value for dbo.seq_bet03
	ELSE IF @transid % 10 = 4		set @nextseq = next value for dbo.seq_bet04
	ELSE IF @transid % 10 = 5		set @nextseq = next value for dbo.seq_bet05
	ELSE IF @transid % 10 = 6		set @nextseq = next value for dbo.seq_bet06
	ELSE IF @transid % 10 = 7		set @nextseq = next value for dbo.seq_bet07
	ELSE IF @transid % 10 = 8		set @nextseq = next value for dbo.seq_bet08
	ELSE IF @transid % 10 = 9		set @nextseq = next value for dbo.seq_bet09

	-- 1 + 31 + 10 + 22
	-- shift <time> left by 32 for site + sequence
	-- shift <site> left by 22 for sequence
	SELECT @transid = (@transid * 0x0000000100000000) | (@sourceID * 4194304) | @nextseq

END
GO