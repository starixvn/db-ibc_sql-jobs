
/*
    Created: 20230324@Louisa
	Task: Scaleout Credit - cleanup unuse objects related to LASDB [Redmine: #182677]
	DB: DB052/bodb02
*/

USE bodb02
GO

---trigger
EXEC sp_rename 'bettrans_after_insert4LAS'	,'bettrans_after_insert4LAS_deleted'		 

