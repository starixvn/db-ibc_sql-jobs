/*<info serverAlias="DBTXN-bodb02" executers="Dot_Member,Dot_Intg,Dot_Bonus,bodbAdminNet,bodbDownlineNet" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE [dbo].[Get_Refno_Transid] 
(
	@refno bigint OUTPUT,
	@sourceID BIGINT = NULL
)
AS
/*
	Created: 20220726@Lukas
	DB: DBTXN.bodb02
	Task: 158293 - Scale out bettrans phase 1

	Revisions:
		- 20220726@Lukas: Create [RedmineID: #158293]
		- 20220912@Tina: add more sitedb2 [RedmineID: #158293]
		- 20220926@Tina: re-set value for param @sourceID [RedmineID: #178213]
						As the beginning, we use @SourceID as input parameter, but after releasing scaleout for phase 1 
						we got some issue related to pass wrong value for this @SourceID. 
						This SP is using for many functions on member site, it's quite risk if we remove this param. 
						So, we keep param as it is and reset this param basing on server name.
*/
BEGIN
	 
	DECLARE @nextseq BIGINT

	--IF @sourceID IS NULL -> Please help double check with Lukas or Vivi if you want to uncomment
	--BEGIN
		SELECT @sourceID =  
			CASE	
				WHEN @@SERVERNAME in ('DBTRANS','SITDBTRANS','TESTDBTRANS','db-60\devdbtrans') THEN 0
				WHEN @@SERVERNAME IN ('DBGRP01N1','DBGRP01N2','SITDBGRP01N1','SITDBGRP01N2','db62\DEVSITEDB','testdb053\TESTSITEDB') THEN 1
				WHEN @@SERVERNAME IN ('DBGRP02N1','DBGRP02N2','SITDBGRP02N1','SITDBGRP02N2') THEN 2
			ELSE 1023 END
	--END 
 
	SELECT	@refno = DATEDIFF_BIG(SECOND, '2022-07-01 00:00:00', GETUTCDATE())
	
	     IF @refno % 10 = 0 	set @nextseq = next value for dbo.seq_ref00
	ELSE IF @refno % 10 = 1		set @nextseq = next value for dbo.seq_ref01
	ELSE IF @refno % 10 = 2		set @nextseq = next value for dbo.seq_ref02
	ELSE IF @refno % 10 = 3		set @nextseq = next value for dbo.seq_ref03
	ELSE IF @refno % 10 = 4		set @nextseq = next value for dbo.seq_ref04
	ELSE IF @refno % 10 = 5		set @nextseq = next value for dbo.seq_ref05
	ELSE IF @refno % 10 = 6		set @nextseq = next value for dbo.seq_ref06
	ELSE IF @refno % 10 = 7		set @nextseq = next value for dbo.seq_ref07
	ELSE IF @refno % 10 = 8		set @nextseq = next value for dbo.seq_ref08
	ELSE IF @refno % 10 = 9		set @nextseq = next value for dbo.seq_ref09

	-- 1 + 31 + 10 + 22
	-- shift <time> left by 32 for site + sequence
	-- shift <site> left by 22 for sequence
	--SELECT @transid = (@transid * 0x0000000100000000) | (@siteGroupID * 4194304) | @nextseq

	-- 5 + 31 + 10 + 18 
	SELECT @refno = (@refno * 0x000000010000000) | (@sourceID * 262144) | @nextseq
END
GO