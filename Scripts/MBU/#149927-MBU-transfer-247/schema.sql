/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb02]
GO

--add more columns
alter table bettranssum
add username varchar(50) null
	, CurrencyName varchar(50) null

--create table
CREATE TABLE Task_Movebet_RecommendList(
	RowId INT IDENTITY(1,1),
	Recommend INT NOT NULL,
	StatusId TINYINT CONSTRAINT DF_Task_Movebet_RecommendList_StatusId DEFAULT(0)
)

CREATE CLUSTERED INDEX CIX_Task_Movebet_RecommendList ON Task_Movebet_RecommendList(RowId) ON [Others_table] 
