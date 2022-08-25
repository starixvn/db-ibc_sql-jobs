/*<info serverAlias="DBTXN-bodb02"></info>*/

/*
	Created: 20220726@Lukas
	DB: DBTXN.bodb02
	Task: 158293 - Scale out bettrans phase 1
*/

-- add constraint default for bet tables
ALTER TABLE bettrans ADD CONSTRAINT DF_bettrans_transid DEFAULT(dbo.f_get_bettrans_transid()) FOR transid
ALTER TABLE translog ADD CONSTRAINT DF_translog_transid DEFAULT(dbo.f_get_bettrans_transid()) FOR transid
ALTER TABLE Transfer ADD CONSTRAINT DF_Transfer_transid DEFAULT(dbo.f_get_bettrans_transid()) FOR transid
ALTER TABLE bettransm ADD CONSTRAINT DF_bettransm_transid DEFAULT(dbo.f_get_bettrans_transid()) FOR transid
 

ALTER TABLE bettransG ADD CONSTRAINT DF_bettransG_transid DEFAULT(dbo.f_get_bettransX_transid()) FOR transid
ALTER TABLE bettransRnG ADD CONSTRAINT DF_bettransRnG_transid DEFAULT(dbo.f_get_bettransX_transid()) FOR transid 
ALTER TABLE bettransLC ADD CONSTRAINT DF_bettransLC_transid DEFAULT(dbo.f_get_bettransX_transid()) FOR transid 