use bodb02
go  

EXEC sys.sp_cdc_enable_db  
GO  


exec sys.sp_cdc_enable_table   
  @source_schema = 'dbo',   
  @source_name = 'bettrans',
  @capture_instance = 'cdc_bettrans',  
  @supports_net_changes = 0,
  @role_name = 'sa',
  @captured_column_list = 'transid,custid,stake,status,winlost,awinlost,mwinlost,playercomm,comm,acomm,apositiontaking,mpositiontaking,spositiontaking,tpositiontaking,epositiontaking,playerdiscount,discount,sdiscount,adiscount,liveindicator,betteam,refno,winlostdate,actualrate,matchid,recommend,mrecommend,modds,bettype,betdaqid,actual_stake,currency,scomm,swinlost,srecommend,statusID,SettlementTime,odds,oddsspread,betid,transdate',
  @filegroup_name = 'cdc_bettrans_data',
  @allow_partition_switch = 1
  
--==

--update setting
exec sys.sp_cdc_change_job @job_type = 'capture'
    , @maxtrans = 1000
    , @maxscans = 10000
    , @continuous = 1 
    , @pollinginterval = 1 

--//capture
exec sys.sp_cdc_change_job @job_type = 'cleanup'
    , @retention = 4320
    , @threshold = 3000

exec sys.sp_cdc_stop_job @job_type = 'capture'
exec sys.sp_cdc_start_job @job_type = 'capture'
