/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/
/*
	Created:	20210301@Max
	Task:		[TVS] Remove archived data [Redmine: #150524]
	Database:	DBTXN-bodb02
*/
BEGIN
	TRUNCATE TABLE dbo.zzzbettrans_Archived	

	DECLARE	@Query	NVARCHAR(MAX)
		,@MaxKeyId	BIGINT = 1008734020 --MAX KeyId of zzzbettrans in 2020 - PRO

	----FROM 2021-----
	BEGIN
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
		INSERT INTO	dbo.zzzbettrans_Archived (id)
		SELECT keyid
		FROM	OPENQUERY(DBARC, ''\
		DECLARE	@MaxKeyId	BIGINT = ''''' + CONVERT(NVARCHAR(MAX), @MaxKeyId) + ''''';

		SELECT	keyid
		FROM	bodb_Archive.dbo.zzzbettrans_bk AS t1 WITH (NOLOCK)
		WHERE t1.KeyId > @MaxKeyId
		;'');';

		EXECUTE	sys.sp_executesql @Query;
	END

END
GO

