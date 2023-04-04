/*<info serverAlias="DB052-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
/*
    Created: 20230324@Louisa
	Task: Scaleout Credit - cleanup unuse objects related to LASDB [Redmine: #182677]
	DB: DB052/bodb02
*/

USE bodb02
GO

DROP TRIGGER bettrans_after_insert4LAS_deleted		 
GO

DROP PROCEDURE LAS_bettransUpdLiveTickets_deleted
GO
