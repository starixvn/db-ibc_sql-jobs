/*<info serverAlias="DBTXN-bodb02" executers="Dot_Member,Dot_Bonus,bodbAdminNet" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE [dbo].[Get_Refno_Transid_Range]
(
	@total_refno int,
	@sourceID BIGINT = NULL
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
	 
	DECLARE @first_seq sql_variant, @nextseq BIGINT,
			@refno BIGINT

	IF @sourceID IS NULL
	BEGIN
		SELECT @sourceID =  
			CASE	
				WHEN @@SERVERNAME in ('DBTRANS','SITDBTRANS','TESTDBTRANS','db-60\devdbtrans') THEN 0
				WHEN @@SERVERNAME IN ('DBGRP01N1','DBGRP01N2','SITDBGRP01N1','SITDBGRP01N2','db62\DEVSITEDB','testdb053\TESTSITEDB') THEN 1
			ELSE 1023 END
	END 
 
	SELECT	@refno = DATEDIFF_BIG(SECOND, '2022-07-01 00:00:00', GETUTCDATE()) 
	
	     IF @refno % 10 = 0 	EXEC sys.sp_sequence_get_range @sequence_name = N'seq_ref00', @range_size = @total_refno, @range_first_value = @first_seq OUTPUT
	ELSE IF @refno % 10 = 1		EXEC sys.sp_sequence_get_range @sequence_name = N'seq_ref01', @range_size = @total_refno, @range_first_value = @first_seq OUTPUT
	ELSE IF @refno % 10 = 2		EXEC sys.sp_sequence_get_range @sequence_name = N'seq_ref02', @range_size = @total_refno, @range_first_value = @first_seq OUTPUT
	ELSE IF @refno % 10 = 3		EXEC sys.sp_sequence_get_range @sequence_name = N'seq_ref03', @range_size = @total_refno, @range_first_value = @first_seq OUTPUT
	ELSE IF @refno % 10 = 4		EXEC sys.sp_sequence_get_range @sequence_name = N'seq_ref04', @range_size = @total_refno, @range_first_value = @first_seq OUTPUT
	ELSE IF @refno % 10 = 5		EXEC sys.sp_sequence_get_range @sequence_name = N'seq_ref05', @range_size = @total_refno, @range_first_value = @first_seq OUTPUT
	ELSE IF @refno % 10 = 6		EXEC sys.sp_sequence_get_range @sequence_name = N'seq_ref06', @range_size = @total_refno, @range_first_value = @first_seq OUTPUT
	ELSE IF @refno % 10 = 7		EXEC sys.sp_sequence_get_range @sequence_name = N'seq_ref07', @range_size = @total_refno, @range_first_value = @first_seq OUTPUT
	ELSE IF @refno % 10 = 8		EXEC sys.sp_sequence_get_range @sequence_name = N'seq_ref08', @range_size = @total_refno, @range_first_value = @first_seq OUTPUT
	ELSE IF @refno % 10 = 9		EXEC sys.sp_sequence_get_range @sequence_name = N'seq_ref09', @range_size = @total_refno, @range_first_value = @first_seq OUTPUT

	SET @nextseq = CONVERT(bigint, @first_seq)
	
	-- 1 + 31 + 10 + 22
	-- shift <time> left by 32 for site + sequence
	-- shift <site> left by 22 for sequence	
	-- 5 + 31 + 10 + 18 
	SELECT @refno = (@refno * 0x000000010000000) | (@sourceID * 262144) --| @nextseq

--	SELECT CAST(@transid as binary(8)) base, @nextseq, CAST(@nextseq as binary(6)) SEQ
--	;WITH A AS (
	SELECT seq, (@refno | @nextseq) + seq - 1 AS transid
	FROM dbo.Numbers_255 WHERE seq <= @total_refno
--	)SELECT *, CAST(transid as binary(8)) HEX from A

END
GO