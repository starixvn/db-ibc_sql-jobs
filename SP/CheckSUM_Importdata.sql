USE [bodb_staging]
GO

/****** Object:  StoredProcedure [dbo].[CheckSUM_Importdata]    Script Date: 02/01/2015 22:39:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CheckSUM_Importdata]
	@checkID int,
	@servername nvarchar(128),
	@checktype varchar(20),
	@str varchar(MAX)
AS
/*
	Created : 
	Task : get checksum data to compare with other servers.
	DB : DBTrans.bodb02, DB052.bodb02, DB053.bodb02, DB054.bodb02, DB06.bodb02

	Revisions :	
	
	XML template : <r m="matchid"><z b="bettype" s="sum"/></r>	
*/
SET NOCOUNT ON
	declare @_xml XML
	SET @_xml = CONVERT(XML, @str)	
	
	IF @checktype in ('match', 'outright')
	BEGIN		
		IF @servername = 'DBTrans'
		BEGIN
			INSERT INTO dbo.Checksum_match(matchid, bettype, s_dbtrans)
			SELECT T.C.value('./@m', 'int'), T.C.value('./@b', 'smallint'), T.C.value('./@s', 'bigint')
			FROM @_xml.nodes('/r') as [T](C)
		END
		ELSE IF @servername = 'DB052'
		BEGIN
			;WITH S as (
				SELECT T.C.value('./@m', 'int') matchid, T.C.value('./@b', 'smallint') bettype, T.C.value('./@s', 'bigint') cs
				FROM @_xml.nodes('/r') as [T](C)
			)
			UPDATE dbo.Checksum_match
			SET s_db052 = s.cs
			FROM S 
			WHERE s.matchid = Checksum_match.matchid and s.bettype = Checksum_match.bettype
		END
		ELSE IF @servername = 'DB053'
		BEGIN
			;WITH S as (
				SELECT T.C.value('./@m', 'int') matchid, T.C.value('./@b', 'smallint') bettype, T.C.value('./@s', 'bigint') cs
				FROM @_xml.nodes('/r') as [T](C)
			)
			UPDATE dbo.Checksum_match
			SET s_db053 = s.cs
			FROM S 
			WHERE s.matchid = Checksum_match.matchid and s.bettype = Checksum_match.bettype
		END
		ELSE IF @servername = 'DB054'
		BEGIN
			;WITH S as (
				SELECT T.C.value('./@m', 'int') matchid, T.C.value('./@b', 'smallint') bettype, T.C.value('./@s', 'bigint') cs
				FROM @_xml.nodes('/r') as [T](C)
			)
			UPDATE dbo.Checksum_match
			SET s_db054 = s.cs
			FROM S 
			WHERE s.matchid = Checksum_match.matchid and s.bettype = Checksum_match.bettype
		END
		ELSE IF @servername = 'DB06'
		BEGIN
			;WITH S as (
				SELECT T.C.value('./@m', 'int') matchid, T.C.value('./@b', 'smallint') bettype, T.C.value('./@s', 'bigint') cs
				FROM @_xml.nodes('/r') as [T](C)
			)
			UPDATE dbo.Checksum_match
			SET s_db06 = s.cs
			FROM S 
			WHERE s.matchid = Checksum_match.matchid and s.bettype = Checksum_match.bettype
		END
	END
	ELSE IF @checktype in ('parlay', 'transfer')
	BEGIN
		IF @servername = 'DBTrans'
		BEGIN 
			INSERT INTO dbo.Checksum_ticket(transid, bettype, s_dbtrans)
			SELECT T.C.value('./@t', 'bigint') --transid
				,T.C.value('./@b', 'smallint') --bettype
				,T.C.value('./@s', 'bigint') --sum
			FROM @_xml.nodes('/r') as [T](C)
		END
		ELSE IF @servername = 'DB052'
		BEGIN
			;WITH S as (
				SELECT T.C.value('./@t', 'bigint') transid
					,T.C.value('./@b', 'smallint') bettype
					,T.C.value('./@s', 'bigint') cs
				FROM @_xml.nodes('/r') as [T](C)
			)
			UPDATE dbo.Checksum_ticket
			SET s_db052 = s.cs
			FROM S 
			WHERE s.transid = Checksum_ticket.transid
		END
		ELSE IF @servername = 'DB053'
		BEGIN
			;WITH S as (
				SELECT T.C.value('./@t', 'bigint') transid
					,T.C.value('./@b', 'smallint') bettype
					,T.C.value('./@s', 'bigint') cs
				FROM @_xml.nodes('/r') as [T](C)
			)
			UPDATE dbo.Checksum_ticket
			SET s_db053 = s.cs
			FROM S 
			WHERE s.transid = Checksum_ticket.transid
		END
		ELSE IF @servername = 'DB054'
		BEGIN
			;WITH S as (
				SELECT T.C.value('./@t', 'bigint') transid
					,T.C.value('./@b', 'smallint') bettype
					,T.C.value('./@s', 'bigint') cs
				FROM @_xml.nodes('/r') as [T](C)
			)
			UPDATE dbo.Checksum_ticket
			SET s_db054 = s.cs
			FROM S 
			WHERE s.transid = Checksum_ticket.transid
		END
		ELSE IF @servername = 'DB06'
		BEGIN
			;WITH S as (
				SELECT T.C.value('./@t', 'bigint') transid
					,T.C.value('./@b', 'smallint') bettype
					,T.C.value('./@s', 'bigint') cs
				FROM @_xml.nodes('/r') as [T](C)
			)
			UPDATE dbo.Checksum_ticket
			SET s_db06 = s.cs
			FROM S 
			WHERE s.transid = Checksum_ticket.transid
		END
	END		

GO


