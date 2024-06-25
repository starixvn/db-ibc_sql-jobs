/*<info serverAlias="DBTXN-bodb02" isNested="0"></info>*/

use bodb02
go

/*
	revise index on bettranssum
	curr: CIX_winlostdate_recommend on bettranssum(winlostdate, recommend)
	new: CIX_winlostdate_recommend on bettranssum(winlostdate, recommend, custid)
*/

drop index CIX_winlostdate_recommend on bettranssum
create clustered index CIX_winlostdate_recommend on bettranssum(winlostdate, recommend, custid)
