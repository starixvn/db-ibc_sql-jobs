USE [bodb_LCC]
GO

/****** Object:  StoredProcedure [dbo].[Task_BettransDelete]    Script Date: 01/19/2015 02:51:13 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[Task_BettransDelete]
as
begin
	declare @rc int=1
	while (@rc>0)
	begin
	delete top(5000) from bodb_LCC.dbo.bettrans where matchid not in(select matchid from bodb_LCC.dbo.match_queue (nolock))
		set @rc=@@ROWCOUNT
		waitfor delay '00:00:03'
	end
end
GO


