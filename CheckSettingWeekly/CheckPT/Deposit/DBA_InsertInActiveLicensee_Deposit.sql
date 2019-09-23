/*
	Created: Winnie
	Task: CheckPT, Insert inactive licensees. RedmineID:#108062
	DB: DBCheck/CheckResultDB
	Date: 20190129
*/ 

DECLARE  @InactiveLicensees TABLE(LicenseeName VARCHAR(20))
 INSERT INTO @InactiveLicensees (LicenseeName)
 VALUES ('DELA'), ('Bezbet'), ('SG8'), ('Tycoon'), ('Ibobet'), ('VCasia'), ('Bwinning'), ('Livebet365'), ('yq355'), ('bcr999'), ('lebao8888'), ('i668bet'), ('i228bet')
  , ('hl5888'), ('ks5555'), ('fx9888'), ('hn555'), ('wx7777'), ('pg5688'), ('wsd666'), ('lj9888'), ('gj7777'), ('lwl8888'), ('eb6688'), ('wy6666'), ('fl5688')
  , ('gi6688'), ('wl5688'), ('wg5688'), ('cl668'), ('cx5888'), ('fg6666'), ('gp1688'), ('kh5688'), ('bvl8888'), ('bw6688'), ('gb688'), ('db5688'), ('Giant Winner')
  , ('mymbet'), ('Athenaqa'), ('alogeu'), ('67BET'), ('SLC88'), ('Bet2day'), ('Winner99'), ('XTD1'), ('XTD2'), ('LivebetIDR'), ('K8'), ('Sga88'), ('Hbobet'), ('Wawabet')
  , ('Mgm88'), ('Saloncs'), ('Royalebet'), ('UUSS'), ('Allbetclub'), ('BlueOcean'), ('THBET'), ('Lambo777'), ('28BET'), ('LivebetKR'), ('Tonybet'), ('MarvelDH')
  , ('DAYWIN'), ('KaiHao'), ('RYB95'), ('SHABAING'), ('Greenplay'), ('Deebet'), ('666VIP'), ('Inbet'), ('TS'), ('Mirabet'), ('Doctorgame'), ('YHY1980'), ('Empire555')
  , ('Citibet'), ('21Cash'), ('DUOLE'), ('Asianbet'), ('Baobet'), ('TooBet'), ('BE7TH'), ('Lexibet'), ('King10'), ('CQ11'), ('Uwin18'), ('12betco'), ('Platinum')
  , ('Emmyo'), ('GDC'), ('Aragon88'), ('Leon'), ('Kasking88'), ('LZYQ'), ('May-88'), ('Star99'), ('LongBao'), ('KGvip'), ('Wuming'), ('AK318'), ('Holey'), ('10BET'), ('WM8888')
  --add more
  ,('GooBet'),('sbcbet'),('TCL'),('Indowin'),('ABB688'),('May-88'),('BuyWin'),('K8sports'),('99UU'),('108bet'),('VGS'),('Wmuming'),('jinmangguo'),('Haoying'),('PCDD')
  ;