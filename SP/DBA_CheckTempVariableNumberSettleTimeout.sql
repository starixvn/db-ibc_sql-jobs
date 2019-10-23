/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_CheckTempVariableNumberSettleTimeout]
AS
/*
	Created by:20190306@Vicky
	Task: get code from PROD
	DB: DBTXN/bodb02 

	Revision
		- 20141012@Cooper(DBTrans): Create for check settle time out
		- 20160918@Victor(DBTrans): add KeyValue not in 19906162
		- 20161019@Cooper(DBTrans): add keyid Compare
		- 20170103@Vivi(DBTrans): re-write SP
		- 20170109@Vivi(DBTrans): change check by TempVariableNumberHistory.CreatedDateTime (temp solution)
		- 20190103@Vicky: Incorporate BetBuilder: add column KeyValue2 [Redmine:#106903]
		- 20191023@Patrick: Reduce interval time for checking temp variable number to 5 mins [Redmine: #122590]
*/
BEGIN
	SET NOCOUNT ON;

	declare @SubjectMessage varchar(300)='', @SendTo varchar(400), @TableHTML varchar(max)=''
	declare @QueuedTVN TABLE (KeyID int, KeyValue money, KeyValue2 VARCHAR(20), CreatedDateTime datetime, eventtype varchar(100))

	SET @SendTo = 'dbatw@onelab.tw;dbaadmin@starixsoft.com;'
	--SET @SendTo = 'vivi.kao@onelab.tw;'

	

	if not exists (select 1 from bodb02.dbo.TempVariableNumber with (nolock)) return
		
	;WITH CTE (keyid, keyvalue, keyvalue2, createddatetime) AS
	(
		select TVN.keyid, TVN.keyvalue, TVN.keyvalue2, max(h.createddatetime) as createddatetime
		from bodb02.dbo.TempVariableNumber TVN with (nolock) 
		inner join bodb02.dbo.TempVariableNumberHistory h with (nolock) 
			on TVN.KeyId = h.KeyId and TVN.KeyValue = h.KeyValue AND TVN.KeyValue2 = h.KeyValue2 and h.[action]='I'
		group by TVN.keyid, TVN.keyvalue, TVN.keyvalue2
	)
	insert into @QueuedTVN (keyid, keyvalue, keyvalue2, createddatetime, eventtype)
	select keyid, keyvalue, keyvalue2, createddatetime,
		case when keyid in (1,3) then 'match.matchid'
			 when keyid=2 then 'outright.orid'
			 when keyid=4 then 'vsOutright.eventid & vsRaceinfo.eventid'
			 when keyid=5 then 'match.matchid & smp_marketid.marketid'
		else 'others' end as EventType		 
	from CTE where createddatetime <= dateadd(mi,-5,getdate())

	
	if exists (select 1 from @QueuedTVN)
	BEGIN

		SET @SubjectMessage ='Please check [TempVariableNumber] have event stay in queue more than 10 minutes.'
		
		SET @TableHTML = @TableHTML + 
				N'<br><table border="1">' +
				N'<tr>' +
				N'<th>KeyID</th>' +
				N'<th>KeyValue</th>' +
				N'<th>KeyValue2</th>' +
				N'<th>CreatedDatetime</th>' +
				N'<th>EventType</th></tr>' +
					CAST ( ( SELECT td = KeyID, '',								
									td = KeyValue, '',
									td = KeyValue2, '',
									td = convert(char(19),createddatetime,120), '',
									td = EventType
								FROM @QueuedTVN
								FOR XML PATH('tr'), TYPE 
					) AS NVARCHAR(MAX) ) +
				N'</table>' +
				N'<H4> select * from bodb02.dbo.TempVariableNumber with (nolock) </H4>' ;

		EXEC msdb.dbo.sp_send_dbmail
			@recipients = @SendTo,
			@body = @TableHTML,
			@body_format = 'HTML',
			@subject = @SubjectMessage

		RAISERROR ('Failed: Please check [TempVariableNumber] have event stay in queue more than 10 minutes.', 16, 1)
		RETURN
	END
END

GO


