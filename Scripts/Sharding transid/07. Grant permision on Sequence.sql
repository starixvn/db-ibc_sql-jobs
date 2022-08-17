/*<info serverAlias="DBTXN-bodb02"></info>*/

/*
	Created: 20220726@Lukas
	DB: DBTXN.bodb02
	Task: 158293 - Scale out bettrans phase 1
*/

--Get_Bettrans_Transid
GO
GRANT UPDATE ON [dbo].[seq_bet00] TO [bodbAdminNet],[Dot_Intg],[Dot_Member],[bodbdownlineNet],[Dot_Bonus]
GO																							
GRANT UPDATE ON [dbo].[seq_bet01] TO [bodbAdminNet],[Dot_Intg],[Dot_Member],[bodbdownlineNet],[Dot_Bonus]
GO																							
GRANT UPDATE ON [dbo].[seq_bet02] TO [bodbAdminNet],[Dot_Intg],[Dot_Member],[bodbdownlineNet],[Dot_Bonus]
GO																							
GRANT UPDATE ON [dbo].[seq_bet03] TO [bodbAdminNet],[Dot_Intg],[Dot_Member],[bodbdownlineNet],[Dot_Bonus]
GO																							
GRANT UPDATE ON [dbo].[seq_bet04] TO [bodbAdminNet],[Dot_Intg],[Dot_Member],[bodbdownlineNet],[Dot_Bonus]
GO																							
GRANT UPDATE ON [dbo].[seq_bet05] TO [bodbAdminNet],[Dot_Intg],[Dot_Member],[bodbdownlineNet],[Dot_Bonus]
GO																							
GRANT UPDATE ON [dbo].[seq_bet06] TO [bodbAdminNet],[Dot_Intg],[Dot_Member],[bodbdownlineNet],[Dot_Bonus]
GO																							
GRANT UPDATE ON [dbo].[seq_bet07] TO [bodbAdminNet],[Dot_Intg],[Dot_Member],[bodbdownlineNet],[Dot_Bonus]
GO																							
GRANT UPDATE ON [dbo].[seq_bet08] TO [bodbAdminNet],[Dot_Intg],[Dot_Member],[bodbdownlineNet],[Dot_Bonus]
GO																							
GRANT UPDATE ON [dbo].[seq_bet09] TO [bodbAdminNet],[Dot_Intg],[Dot_Member],[bodbdownlineNet],[Dot_Bonus]
GO 
--Get_BettransX_Transid 
GO
GO
GRANT UPDATE ON [dbo].[seq_betX00] TO [bodbAdminNet],[Dot_Intg],[Dot_Member],[bodbdownlineNet],[Dot_Bonus]
GO																			
GRANT UPDATE ON [dbo].[seq_betX01] TO [bodbAdminNet],[Dot_Intg],[Dot_Member],[bodbdownlineNet],[Dot_Bonus]
GO																			
GRANT UPDATE ON [dbo].[seq_betX02] TO [bodbAdminNet],[Dot_Intg],[Dot_Member],[bodbdownlineNet],[Dot_Bonus]
GO																			
GRANT UPDATE ON [dbo].[seq_betX03] TO [bodbAdminNet],[Dot_Intg],[Dot_Member],[bodbdownlineNet],[Dot_Bonus]
GO																			
GRANT UPDATE ON [dbo].[seq_betX04] TO [bodbAdminNet],[Dot_Intg],[Dot_Member],[bodbdownlineNet],[Dot_Bonus]
GO																			
GRANT UPDATE ON [dbo].[seq_betX05] TO [bodbAdminNet],[Dot_Intg],[Dot_Member],[bodbdownlineNet],[Dot_Bonus]
GO																			
GRANT UPDATE ON [dbo].[seq_betX06] TO [bodbAdminNet],[Dot_Intg],[Dot_Member],[bodbdownlineNet],[Dot_Bonus]
GO																			
GRANT UPDATE ON [dbo].[seq_betX07] TO [bodbAdminNet],[Dot_Intg],[Dot_Member],[bodbdownlineNet],[Dot_Bonus]
GO																			
GRANT UPDATE ON [dbo].[seq_betX08] TO [bodbAdminNet],[Dot_Intg],[Dot_Member],[bodbdownlineNet],[Dot_Bonus]
GO																			
GRANT UPDATE ON [dbo].[seq_betX09] TO [bodbAdminNet],[Dot_Intg],[Dot_Member],[bodbdownlineNet],[Dot_Bonus]
  
GO
---Get_Refno_Transid
GO
GRANT UPDATE ON [dbo].[seq_ref00] TO [bodbAdminNet],[Dot_Intg],[Dot_Member],[bodbdownlineNet],[Dot_Bonus]
GO															
GRANT UPDATE ON [dbo].[seq_ref01] TO [bodbAdminNet],[Dot_Intg],[Dot_Member],[bodbdownlineNet],[Dot_Bonus]
GO															
GRANT UPDATE ON [dbo].[seq_ref02] TO [bodbAdminNet],[Dot_Intg],[Dot_Member],[bodbdownlineNet],[Dot_Bonus]
GO															
GRANT UPDATE ON [dbo].[seq_ref03] TO [bodbAdminNet],[Dot_Intg],[Dot_Member],[bodbdownlineNet],[Dot_Bonus]
GO															
GRANT UPDATE ON [dbo].[seq_ref04] TO [bodbAdminNet],[Dot_Intg],[Dot_Member],[bodbdownlineNet],[Dot_Bonus]
GO															
GRANT UPDATE ON [dbo].[seq_ref05] TO [bodbAdminNet],[Dot_Intg],[Dot_Member],[bodbdownlineNet],[Dot_Bonus]
GO															
GRANT UPDATE ON [dbo].[seq_ref06] TO [bodbAdminNet],[Dot_Intg],[Dot_Member],[bodbdownlineNet],[Dot_Bonus]
GO															
GRANT UPDATE ON [dbo].[seq_ref07] TO [bodbAdminNet],[Dot_Intg],[Dot_Member],[bodbdownlineNet],[Dot_Bonus]
GO															
GRANT UPDATE ON [dbo].[seq_ref08] TO [bodbAdminNet],[Dot_Intg],[Dot_Member],[bodbdownlineNet],[Dot_Bonus]
GO															
GRANT UPDATE ON [dbo].[seq_ref09] TO [bodbAdminNet],[Dot_Intg],[Dot_Member],[bodbdownlineNet],[Dot_Bonus]
GO
