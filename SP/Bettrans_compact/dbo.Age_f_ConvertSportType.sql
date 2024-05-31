/*<info serverAlias="DBAGE-bodb_AGE" isFunction="1" isNested="0"></info>*/
ALTER FUNCTION [dbo].[Age_f_ConvertSportType]
(
	@SportType INT,
	@Bettype INT,
	@LeagueGroupId INT,
	@TicketType TINYINT
)
RETURNS INT
/*
	Created by: 20231201@Bobby
	Task: 153357 - Alpha - CDC bettrans_compact
	DB: DBAGE.bodb_AGE
	Revisions:
		- 20231201@Bobby:  Implement bettrans_compact Redmine: [#153357]
		- 20240119@Lewis: Add VS4 [RedmineID: #198621]
		- 20240306@Lewis: Add Virtual Ice Hockey [RedmineID: #201129]
		- 20240305@Lewis: Add UU Slot [RedmineID: #192595]
		- 20240408@Lewis: Add SABA xD [RedmineID: #202706]
		- 20240515@Lewis: Add SABA Kabaddi [RedmineID: #203763]
*/
BEGIN 
	RETURN (
		SELECT 
			CASE WHEN ( 
						(b.LeagueGroupID IN (42,74,108,113) AND b.sporttype = 1 ) 
							OR (b.LeagueGroupID IN (122, 42) AND b.sporttype = 2 )
							OR (b.LeagueGroupID = 42 AND b.sporttype = 50)
							OR (b.LeagueGroupID = 42 AND b.sporttype = 5) --SabaTennis
							OR (b.LeagueGroupID = 42 AND b.sporttype = 4) --Virtual Ice Hockey
							OR (b.LeagueGroupID = 42 AND b.sporttype = 47) --SABA Kabaddi
							OR (b.LeagueGroupID = 151 AND b.sporttype = 43)
						) THEN b.sporttype
					WHEN b.bettype BETWEEN 81 AND 120 OR -- Number Game 
						b.bettype BETWEEN 8101 AND 8120 OR -- Happy 5 
						b.bettype BETWEEN 3601 AND 3610 THEN 161 -- Happy 5 Linked Games
					WHEN b.bettype BETWEEN 1201 AND 1299 THEN 180 -- Virtual Sport
					WHEN b.bettype BETWEEN 2700 AND 2899 THEN 190 -- Betradar Virtual Sport
					WHEN b.bettype IN (71, 72) THEN 251
					WHEN b.bettype BETWEEN 1501 AND 1599 THEN 202 -- Keno
					WHEN b.bettype BETWEEN 1021 AND 1099 THEN 220 -- Keno Lottery
					WHEN b.bettype BETWEEN 1700 AND 1799 THEN 255 -- Gold Deluxe
					WHEN b.bettype BETWEEN 1800 AND 1899 THEN 250 --- AG Casino 
					WHEN b.bettype = 1900 THEN 249 --- Vegas Games 
					WHEN b.bettype BETWEEN 18000 AND 18099 THEN 204 --- Colossus Bets
					WHEN b.bettype BETWEEN 2101 AND 2199 THEN 208
					WHEN b.bettype BETWEEN 2201 AND 2299 THEN 209
					WHEN b.bettype BETWEEN 2301 AND 2399 OR
						b.bettype BETWEEN 2901 AND 2999 THEN 210
					WHEN b.bettype BETWEEN 2401 AND 2499 THEN 211 --- Allbet
					WHEN b.bettype BETWEEN 4001 AND 4100 OR 
						b.bettype BETWEEN 5800 AND 5999 THEN 212 -- Voidbridge
					WHEN b.bettype BETWEEN 4101 AND 4300 OR 
						b.bettype BETWEEN 6701 AND 7000 THEN 248 -- Pragmatic
					WHEN b.bettype BETWEEN 2501 AND 2699 THEN 213 --NG2 -
					WHEN b.bettype BETWEEN 1011 AND 1020 THEN 219 --Fishing World -
					WHEN b.bettype BETWEEN 8000 AND 8099 THEN 221 -- Exchange
					WHEN b.bettype BETWEEN 1901 AND 1999 THEN 165 -- Card Club
					WHEN b.bettype BETWEEN 4301 AND 4600 THEN 247 -- Spadegaming
					WHEN b.bettype BETWEEN 4601 AND 4900 THEN 245 -- Virtual Games
					WHEN b.bettype BETWEEN 1611 AND 1699 THEN 200 -- Saba.Club
					WHEN b.bettype BETWEEN 3001 AND 3099 THEN 244 -- SA Gaming
					WHEN b.bettype BETWEEN 3101 AND 3150 THEN 243 -- AE Casino
					WHEN b.bettype BETWEEN 5001 AND 5099 THEN 223 -- Indo 4D
					WHEN b.bettype BETWEEN 4901 AND 5000 THEN 222 -- Table Games	
					WHEN b.bettype BETWEEN 3300 AND 3399 THEN 241 -- BBIN	
					WHEN b.bettype BETWEEN 3201 AND 3299 THEN 242 -- IBCBet Live Casino		
					WHEN b.bettype BETWEEN 5601 AND 5699 THEN 225 -- ION					
					WHEN b.bettype BETWEEN 5500 AND 5599 THEN 224 -- RNG War		
					WHEN b.bettype BETWEEN 6001 AND 6300 THEN 232 -- PG Soft
					WHEN b.bettype BETWEEN 6401 AND 6700 THEN 234-- Joker
					WHEN b.bettype BETWEEN 3401 AND 3499 THEN 233 -- WM
					WHEN b.bettype BETWEEN 5701 AND 5799 THEN 236 -- GDG
					WHEN b.bettype = 5301 THEN 231 -- Virtual Sports 3
					WHEN b.bettype BETWEEN 3501 AND 3599 THEN 239 -- BG
					WHEN b.bettype BETWEEN 5401 AND 5499 THEN 237 -- MaxGame
					WHEN b.bettype BETWEEN 17000 AND 17030 THEN 246 -- Saba promotion
					WHEN b.bettype BETWEEN 3611 AND 3620 THEN 169 -- Sports Lottery
					WHEN b.bettype BETWEEN 3701 AND 3799 THEN 170 -- PP Live Casino
					WHEN b.bettype BETWEEN 7001 AND 7300 THEN 238 -- Habanero
					WHEN b.bettype BETWEEN 7301 AND 7600 THEN 167 -- Creative Gaming
					WHEN b.bettype BETWEEN 3801 AND 3899 THEN 171 -- VGaming 
					WHEN b.bettype BETWEEN 7801 AND 7899 THEN 174 -- AdvantPlay Mini
					WHEN b.bettype BETWEEN 7701 AND 7799 THEN 172 -- AdvantPlay Product
					WHEN b.bettype BETWEEN 7901 AND 7999 THEN 175 -- Bitcoin Product
					WHEN b.bettype BETWEEN 8201 AND 8299 THEN 176 -- FGG Product
					WHEN b.bettype BETWEEN 8900 AND 8999 THEN 156 -- SEAL Entertainment
					WHEN b.bettype BETWEEN 8400 AND 8699 THEN 155 -- Microgaming
					WHEN b.bettype BETWEEN 5100 AND 5299 THEN 158 -- Jili
					WHEN b.bettype BETWEEN 3151 AND 3200 THEN 159 -- YeeBet
					WHEN b.bettype BETWEEN 5302 AND 5399 THEN 178 -- VS3-LeapGaming(New)
					WHEN b.bettype BETWEEN 10300 AND 10399 THEN 228 -- WE Live Casino
					WHEN b.bettype BETWEEN 7601 AND 7700 THEN 227 -- Live22
					WHEN b.bettype BETWEEN 10400 AND 10449 THEN 188 -- VS4-Virtual Cock Fighting
					WHEN b.bettype BETWEEN 10000 AND 10299 THEN 216 -- UU Slots
					WHEN b.bettype BETWEEN 10801 AND 11000 THEN 240 -- SABAxD
					ELSE 0
				END AS sporttype
		FROM (
			 VALUES(@SportType, @Bettype, @LeagueGroupId,@TicketType)
		) AS b (SportType, Bettype, LeagueGroupId, TicketType)
	)
END
GO
