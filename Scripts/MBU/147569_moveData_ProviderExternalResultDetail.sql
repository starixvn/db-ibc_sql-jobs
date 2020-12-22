select *
from bodb02.dbo.ProviderExternalResultDetail with(nolock)
where MatchId not in (select m.matchid from bodb02.dbo.match m with(nolock))

go

insert into dbo.ProviderExternalResultDetail_bk
	([ProviderExternalId],[MatchId3rd],[MatchId],[SourceId],[ResourceId],[HomeValue],[AwayValue],[OtherInfo],[CreateDate],[LastModifyDate],[CreateBy],[LastModifyBy])
select [ProviderExternalId],[MatchId3rd],[MatchId],[SourceId],[ResourceId],[HomeValue],[AwayValue],[OtherInfo],[CreateDate],[LastModifyDate],[CreateBy],[LastModifyBy]
from bodb02.dbo.ProviderExternalResultDetail with(nolock)
where MatchId not in (select m.matchid from bodb02.dbo.match m with(nolock))

go

select * from dbpro.bodb02.dbo.ProviderExternalResultDetail 
where ProviderExternalId in (select bk.ProviderExternalId from dbo.ProviderExternalResultDetail_bk bk)

go

delete from dbpro.bodb02.dbo.ProviderExternalResultDetail 
where ProviderExternalId in (select bk.ProviderExternalId from dbo.ProviderExternalResultDetail_bk bk)


/*<info serverAlias="DBARC-bodb_Archive" executers="" viewers="" isFunction="0" isNested="0"></info>*/