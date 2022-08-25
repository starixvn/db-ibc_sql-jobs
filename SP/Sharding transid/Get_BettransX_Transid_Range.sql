/*<info serverAlias="DBTXN-bodb02" executers="Dot_Member,Dot_Intg,Dot_Bonus,bodbAdminNet,bodbDownlineNet" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE [dbo].[Get_BettransX_Transid_Range]
(
	@total_transid int,
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
	 
	DECLARE @first_seq sql_variant, @nextseq BIGINT,
			@transid BIGINT

	IF @sourceID IS NULL
	BEGIN
		SELECT @sourceID =  
			CASE	
				WHEN @@SERVERNAME in ('DBTRANS','SITDBTRANS','TESTDBTRANS','db-60\devdbtrans') THEN 0
				WHEN @@SERVERNAME IN ('DBGRP01N1','DBGRP01N2','SITDBGRP01N1','SITDBGRP01N2','db62\DEVSITEDB','testdb053\TESTSITEDB') THEN 1
			ELSE 1023 END
	END 
 
	SELECT	@transid = DATEDIFF_BIG(SECOND, '2022-07-01 00:00:00', GETUTCDATE()) 
	
	     IF @transid % 10 = 0 		EXEC sys.sp_sequence_get_range @sequence_name = N'seq_betX00', @range_size = @total_transid, @range_first_value = @first_seq OUTPUT
	ELSE IF @transid % 10 = 1		EXEC sys.sp_sequence_get_range @sequence_name = N'seq_betX01', @range_size = @total_transid, @range_first_value = @first_seq OUTPUT
	ELSE IF @transid % 10 = 2		EXEC sys.sp_sequence_get_range @sequence_name = N'seq_betX02', @range_size = @total_transid, @range_first_value = @first_seq OUTPUT
	ELSE IF @transid % 10 = 3		EXEC sys.sp_sequence_get_range @sequence_name = N'seq_betX03', @range_size = @total_transid, @range_first_value = @first_seq OUTPUT
	ELSE IF @transid % 10 = 4		EXEC sys.sp_sequence_get_range @sequence_name = N'seq_betX04', @range_size = @total_transid, @range_first_value = @first_seq OUTPUT
	ELSE IF @transid % 10 = 5		EXEC sys.sp_sequence_get_range @sequence_name = N'seq_betX05', @range_size = @total_transid, @range_first_value = @first_seq OUTPUT
	ELSE IF @transid % 10 = 6		EXEC sys.sp_sequence_get_range @sequence_name = N'seq_betX06', @range_size = @total_transid, @range_first_value = @first_seq OUTPUT
	ELSE IF @transid % 10 = 7		EXEC sys.sp_sequence_get_range @sequence_name = N'seq_betX07', @range_size = @total_transid, @range_first_value = @first_seq OUTPUT
	ELSE IF @transid % 10 = 8		EXEC sys.sp_sequence_get_range @sequence_name = N'seq_betX08', @range_size = @total_transid, @range_first_value = @first_seq OUTPUT
	ELSE IF @transid % 10 = 9		EXEC sys.sp_sequence_get_range @sequence_name = N'seq_betX09', @range_size = @total_transid, @range_first_value = @first_seq OUTPUT

	SET @nextseq = CONVERT(bigint, @first_seq)
	
	-- 1 + 31 + 10 + 22
	-- shift <time> left by 32 for site + sequence
	-- shift <site> left by 22 for sequence
	SELECT @transid = (@transid * 0x0000000100000000) | (@sourceID * 4194304) --| @nextseq

--	SELECT CAST(@transid as binary(8)) base, @nextseq, CAST(@nextseq as binary(6)) SEQ
--	;WITH A AS (
	SELECT seq, (@transid | @nextseq) + seq - 1 AS transid
	FROM dbo.Numbers_255 WHERE seq <= @total_transid
--	)SELECT *, CAST(transid as binary(8)) HEX from A

END
GO
