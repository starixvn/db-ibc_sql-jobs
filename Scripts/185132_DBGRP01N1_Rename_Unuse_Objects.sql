 
EXEC sp_rename 'Las_Dep_AgentUpdateMemberDiscount'		,'Las_Dep_AgentUpdateMemberDiscount_deleted'	---DBCUST
EXEC sp_rename 'LAS_Custsetting_00'						,'LAS_Custsetting_00_deleted'
EXEC sp_rename 'Las_Dep_AgentUpdateMemberDiscount3rd'	,'Las_Dep_AgentUpdateMemberDiscount3rd_deleted'
EXEC sp_rename 'Las_Custsetting_03'						,'Las_Custsetting_03_deleted'

EXEC sp_rename 'NAP_Admin_Calculate_22'			,'NAP_Admin_Calculate_22_deleted'		--DBGRP02N1
EXEC sp_rename 'NAP_Admin_Calculate_9'			,'NAP_Admin_Calculate_9_deleted'		--DBGRP02N1
EXEC sp_rename 'Admin_PreCalculate_1'			,'Admin_PreCalculate_1_deleted'			--DBGRP02N1
EXEC sp_rename 'Admin_PreCalculate_24'			,'Admin_PreCalculate_24_deleted'		--DBGRP02N1
EXEC sp_rename 'Admin_PreCalculate_3'			,'Admin_PreCalculate_3_deleted'			--DBGRP02N1
EXEC sp_rename 'Admin_PreCalculate_4'			,'Admin_PreCalculate_4_deleted'			--DBGRP02N1
EXEC sp_rename 'Admin_PreCalculate_5'			,'Admin_PreCalculate_5_deleted'			--DBGRP02N1
EXEC sp_rename 'Admin_PreCalculate_6'			,'Admin_PreCalculate_6_deleted'			--DBGRP02N1
EXEC sp_rename 'NAP_Admin_Settlement_Parlay'	,'NAP_Admin_Settlement_Parlay_deleted'	--DBGRP02N1
EXEC sp_rename 'NAP_Admin_Calculate_22'			,'NAP_Admin_Calculate_22_deleted'		--DBGRP01N1
EXEC sp_rename 'NAP_Admin_Calculate_9'			,'NAP_Admin_Calculate_9_deleted'		--DBGRP01N1
EXEC sp_rename 'Admin_PreCalculate_1'			,'Admin_PreCalculate_1_deleted'			--DBGRP01N1
EXEC sp_rename 'Admin_PreCalculate_24'			,'Admin_PreCalculate_24_deleted'		--DBGRP01N1
EXEC sp_rename 'Admin_PreCalculate_3'			,'Admin_PreCalculate_3_deleted'			--DBGRP01N1
EXEC sp_rename 'Admin_PreCalculate_4'			,'Admin_PreCalculate_4_deleted'			--DBGRP01N1
EXEC sp_rename 'Admin_PreCalculate_5'			,'Admin_PreCalculate_5_deleted'			--DBGRP01N1
EXEC sp_rename 'Admin_PreCalculate_6'			,'Admin_PreCalculate_6_deleted'			--DBGRP01N1
EXEC sp_rename 'NAP_Admin_Settlement_Parlay'	,'NAP_Admin_Settlement_Parlay_deleted'	--DBGRP01N1
EXEC sp_rename 'Admin_PreCalculate_1'			,'Admin_PreCalculate_1_deleted'			--DBTrans
EXEC sp_rename 'Admin_PreCalculate_24'			,'Admin_PreCalculate_24_deleted'		--DBTrans
EXEC sp_rename 'Admin_PreCalculate_3'			,'Admin_PreCalculate_3_deleted'			--DBTrans
EXEC sp_rename 'Admin_PreCalculate_4'			,'Admin_PreCalculate_4_deleted'			--DBTrans
EXEC sp_rename 'Admin_PreCalculate_5'			,'Admin_PreCalculate_5_deleted'			--DBTrans
EXEC sp_rename 'Admin_PreCalculate_6'			,'Admin_PreCalculate_6_deleted'			--DBTrans
EXEC sp_rename 'NAP_Admin_Settlement_Parlay'	,'NAP_Admin_Settlement_Parlay_deleted'	--DBTrans
EXEC sp_rename 'LAS_bettransUpdLiveTickets'		,'LAS_bettransUpdLiveTickets_deleted'	--DB053
EXEC sp_rename 'LAS_WriteLog_UserLog_RunSP'		,'LAS_WriteLog_UserLog_RunSP_deleted'	--DB054
EXEC sp_rename 'LAS_WriteLog_UserLog_RunSP'		,'LAS_WriteLog_UserLog_RunSP_deleted'	--DB055
EXEC sp_rename 'LAS_WriteLog_UserLog_RunSP'		,'LAS_WriteLog_UserLog_RunSP_deleted'	--DBTrans
EXEC sp_rename 'LAS_WriteLog_UserLog_RunSP'		,'LAS_WriteLog_UserLog_RunSP_deleted'	--DBCust
EXEC sp_rename 'LAS_WriteLog_UserLog_RunSP'		,'LAS_WriteLog_UserLog_RunSP_deleted'	--DBGRP01L
EXEC sp_rename 'LAS_WriteLog_UserLog_RunSP'		,'LAS_WriteLog_UserLog_RunSP_deleted'	--DBGRP02L

---trigger
bettrans_after_insert4LAS				DB052
bettrans_after_insert4LAS				DB053

----table
UserLog_RunSP_LAS					DB054
UserLog_RunSP_LAS					DB055