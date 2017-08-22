select distinct ProductID,SportType from SportBettypeMatrix (nolock)
where SportType in (44,
50,
206,
211,
211,
212,
213,
219)

select * from Sports 
where SportType  in (44,
50,
206,
211,
211,
212,
213,
219)
/*
"
Macau Games ( credit/deposit, Productid = 22) : dcs
Microgaming - Live Casino (deposit, product id = 13 (in bodb02), productid= 14 (in bodb_Licensee) ) : no dcs
   
Microgaming - RNG Casino (deposit, productid = 17): No dcs
OneRNG (credit/deposit, product id = 6): no dcs
Virtual Sport (credit/deposit, product id = 5): no dcs
Number Game (credit/deposit, product id = 3): no dcs
Keno (credit/deposit, product id = 8): no dcs
Allbet (credit/deposit, product id = 21): dcs
Gold Deluxe (credit, product id = 12): no dcs
SLI Live Casino (credit/deposit, product id = 4): no dcs
GG Fishing World (credit/deposit, Productid = 24): dcs
   
*/
select distinct ProductID,SportType from SportBettypeMatrix (nolock)
where SportType in (151,152,153)
select * from Products where ProductID  = 2

select  --distinct ci.srecommend
ag.HideGoldDeluxe 'Member', ag.DisableGoldDeluxe  'Mbember disable', ci.HideGoldDeluxe,ag.DisableLiveCasino, ci.SyncLiveCasino, ci.DisableGoldDeluxe,ag.SyncLiveCasino, 
ci.DisableLiveCasino,
ag.username, ci.username,ct.site,ct1.creatdate,ct.creatdate,  * 
from custinfo ag with (nolock) 
inner join custinfo ci with (nolock) on ag.custid = ci.recommend 
inner join customer ct with(nolock) on ct.custid=ag.custid
inner join customer ct1 with(nolock) on ct1.custid=ag.custid
where --custid in (1059373, 838201, 838779, 1059116)
ag.DisableGoldDeluxe = 1
and ci.DisableGoldDeluxe = 0
AND ci.srecommend NOT IN (SELECT custid FROM Dep_CustSuper WITH(NOLOCK))
and ag.Enabled=1
and ci.enabled=1


select top 1 * from custinfo (nolock)

select * from productstatusprofile

select * from dep_productstatusprofile