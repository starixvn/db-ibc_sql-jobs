/*<info serverAlias="DBTP-bodb02,DBACC-bodb02" executers="repl_ap" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE [dbo].[Repl_PutDomainManagement]
    @tvp_param TVP_ReplDomainManagement READONLY
AS
/*
    Created: 20231023@Tacy
	Task : In-House
	DB: DBTP-bodb02,DBACC-bodb02
	
	Revisions:
		- 20231023@Tacy: Create SP [Redmine:#194024]
*/
BEGIN
    SET NOCOUNT ON;

	SET IDENTITY_INSERT [dbo].[DomainManagement] ON;

    MERGE [dbo].[DomainManagement] [t]
    USING @tvp_param [tvp] ON [t].[DomainID] = [tvp].[DomainID]
    WHEN MATCHED THEN
        UPDATE SET
			[Domain]			=[tvp].[Domain]
			,[System]			=[tvp].[System]
			,[Site]				=[tvp].[Site]
			,[BrandName]		=[tvp].[BrandName]
			,[Status]			=[tvp].[Status]
			,[ExpiredDate]		=[tvp].[ExpiredDate]
			,[LastUpdateTime]	=[tvp].[LastUpdateTime]
			,[RestrictedCountries]=[tvp].[RestrictedCountries]
			,[Remark]			=[tvp].[Remark]
			,[isDeleted]        = [tvp].[isDeleted]
            ,[RepUpdateTime]	= CASE WHEN [tvp].[RepUpdateTime] > [t].[RepUpdateTime] THEN [tvp].[RepUpdateTime] ELSE [t].[RepUpdateTime] END
    WHEN NOT MATCHED THEN
        INSERT (
             [Domain]
			,[DomainID]
			,[System]
			,[Site]
			,[BrandName]
			,[Status]
			,[ExpiredDate]
			,[LastUpdateTime]
			,[RestrictedCountries]
			,[Remark]
			,[isDeleted]
			,[RepUpdateTime]
        ) VALUES (
             [tvp].[Domain]
			,[tvp].[DomainID]
			,[tvp].[System]
			,[tvp].[Site]
			,[tvp].[BrandName]
			,[tvp].[Status]
			,[tvp].[ExpiredDate]
			,[tvp].[LastUpdateTime]
			,[tvp].[RestrictedCountries]
			,[tvp].[Remark]
			,[tvp].[isDeleted]
			,[tvp].[RepUpdateTime]
        );

	SET IDENTITY_INSERT [dbo].[DomainManagement] OFF;
END
GO