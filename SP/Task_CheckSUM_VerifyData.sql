USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Task_CheckSUM_VerifyData]    Script Date: 01/27/2015 01:41:58 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_CheckSUM_VerifyData] 
	@checkID int,
	@mode varchar(20), --match / outright / parlay / transfer
	@list varchar(max)
AS
/*
	Created: 
	Task : get checksum data to compare with other servers.
	DB: DBTrans.bodb02, DB052.bodb02, DB053.bodb02, DB054.bodb02, DB06.bodb02

	Revisions:		
	
	XML template: <r m="matchid"><z b="bettype" s="sum"/></r>	
*/
SET NOCOUNT ON	

	DECLARE @_xml XML, @str varchar(max)
	SET @_xml = N'<root><r>' + REPLACE(@list, ',', '</r><r>') + '</r></root>'
	DECLARE @temp as TABLE(ID int, done bit)
	DECLARE @ID int
		
	IF @mode in ('match','outright')
	BEGIN 		
		SET @_xml = (
			SELECT matchid '@m', bettype as '@b'
				,SUM(CAST(CHECKSUM(bettype, stake, winlost, actual_stake, ruben, statuswinlost, status, statusid, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, currency, transid) as bigint)) as '@s'
			FROM bettrans b with(nolock)
			WHERE matchid IN (
					SELECT r.value('.','int') as matchid
					FROM @_xml.nodes('//root/r') AS RECORDS(r)
				)				
			GROUP BY matchid, bettype
			FOR XML PATH('r'), TYPE
		)			
			
		SET @str = CONVERT(varchar(max), @_xml)
		--SELECT @str
		EXEC DB054.bodb_staging.dbo.CheckSUM_Importdata 
			@checkID = @checkID, @servername = @@SERVERNAME, @checktype = @mode, @str = @str			
	END	
	ELSE IF @mode in ('parlay', 'transfer')
	BEGIN 			
		SET @_xml = (
			SELECT transid as '@t'
				,bettype as '@b'
				,SUM(CAST(CHECKSUM(bettype, stake, winlost, actual_stake, ruben, statuswinlost, status, statusid, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, currency, transid) as bigint)) as '@s'
			FROM bettrans b with(nolock)
			WHERE transid in (
				SELECT r.value('.', 'bigint') as transid
				FROM @_xml.nodes('//root/r') AS RECORDS(r)		
			)
			GROUP BY transid, bettype					
			FOR XML PATH('r'), TYPE	
		)			
	
		SET @str = CONVERT(varchar(max), @_xml)
		--SELECT @str
		EXEC DB054.bodb_staging.dbo.CheckSUM_Importdata 
			@checkID = @checkID, @servername = @@SERVERNAME, @checktype = @mode, @str = @str	
	END
GO


