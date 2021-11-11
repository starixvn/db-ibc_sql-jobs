/*<info serverAlias="DBTrans-bodb02" executers="" selecters="" viewers="" isFunction="0" isNested="0"></info>*/
--Task- reset data on SIT @DBTrans
--Run on SITDBTrans.bodb02
use bodb02
go

select COUNT(1) from dbo.bettrans with(nolock) where winlostdate < '2021-10-29 00:00:00'
select COUNT(1) from dbo.bettransLC with(nolock) where winlostdate < '2021-10-29 00:00:00'
select COUNT(1) from dbo.bettransRnG with(nolock) where winlostdate < '2021-10-29 00:00:00'
select COUNT(1) from dbo.bettransG with(nolock) where winlostdate < '2021-10-29 00:00:00'
select COUNT(1) from dbo.bettransm with(nolock) where winlostdate < '2021-10-29 00:00:00'
select COUNT(1) from dbo.translog with(nolock) where winlostdate < '2021-10-29 00:00:00'

--active
while 1 = 1
begin
	delete top(2000) from dbo.bettrans with(rowlock) where winlostdate < '2021-10-29 00:00:00' and custid <> 3
	if @@rowcount = 0
		break
end
while 1 = 1
begin
	delete top(2000) from dbo.bettransLC with(rowlock) where winlostdate < '2021-10-29 00:00:00' and custid <> 3
	if @@rowcount = 0
		break
end
while 1 = 1
begin
	delete top(2000) from dbo.bettransRnG with(rowlock) where winlostdate < '2021-10-29 00:00:00' and custid <> 3
	if @@rowcount = 0
		break
end
while 1 = 1
begin
	delete top(2000) from dbo.bettransG with(rowlock) where winlostdate < '2021-10-29 00:00:00' and custid <> 3
	if @@rowcount = 0
		break
end
while 1 = 1
begin
	delete top(2000) from dbo.bettransm with(rowlock) where winlostdate < '2021-10-29 00:00:00' and custid <> 3
	if @@rowcount = 0
		break
end
while 1 = 1
begin
	delete top(2000) from dbo.translog with(rowlock) where winlostdate < '2021-10-29 00:00:00' and custid <> 3
	if @@rowcount = 0
		break
end

--14
select COUNT(1) from dbo.bettrans14 with(nolock) where winlostdate < '2021-10-29 00:00:00'
select COUNT(1) from dbo.bettransLC14 with(nolock) where winlostdate < '2021-10-29 00:00:00'
select COUNT(1) from dbo.bettransRnG14 with(nolock) where winlostdate < '2021-10-29 00:00:00'
select COUNT(1) from dbo.bettransG14 with(nolock) where winlostdate < '2021-10-29 00:00:00'
select COUNT(1) from dbo.bettransm14 with(nolock) where winlostdate < '2021-10-29 00:00:00'
select COUNT(1) from dbo.translog14 with(nolock) where winlostdate < '2021-10-29 00:00:00'

while 1 = 1
begin
	delete top(2000) from dbo.bettrans14 with(rowlock) where winlostdate < '2021-10-29 00:00:00' and custid <> 3
	if @@rowcount = 0
		break
end
while 1 = 1
begin
	delete top(2000) from dbo.bettransLC14 with(rowlock) where winlostdate < '2021-10-29 00:00:00' and custid <> 3
	if @@rowcount = 0
		break
end
while 1 = 1
begin
	delete top(2000) from dbo.bettransRnG14 with(rowlock) where winlostdate < '2021-10-29 00:00:00' and custid <> 3
	if @@rowcount = 0
		break
end
while 1 = 1
begin
	delete top(2000) from dbo.bettransG14 with(rowlock) where winlostdate < '2021-10-29 00:00:00' and custid <> 3
	if @@rowcount = 0
		break
end
while 1 = 1
begin
	delete top(2000) from dbo.bettransm14 with(rowlock) where winlostdate < '2021-10-29 00:00:00' and custid <> 3
	if @@rowcount = 0
		break
end
while 1 = 1
begin
	delete top(2000) from dbo.translog14 with(rowlock) where winlostdate < '2021-10-29 00:00:00' and custid <> 3
	if @@rowcount = 0
		break
end

--IP
select count(1) from dbo.Task_bettrans14_IP2Country where winlostdate < '2021-10-29 00:00:00'
select count(1) from dbo.Task_bettransLC14_IP2Country where winlostdate < '2021-10-29 00:00:00'
select count(1) from dbo.Task_bettransRNG14_IP2Country where winlostdate < '2021-10-29 00:00:00'

while 1 = 1
begin
	delete top(2000) from dbo.Task_bettrans14_IP2Country with(rowlock) where winlostdate < '2021-10-29 00:00:00' and custid <> 3
	if @@rowcount = 0
		break
end
while 1 = 1
begin
	delete top(2000) from dbo.Task_bettransLC14_IP2Country with(rowlock) where winlostdate < '2021-10-29 00:00:00' and custid <> 3
	if @@rowcount = 0
		break
end
while 1 = 1
begin
	delete top(2000) from dbo.Task_bettransRNG14_IP2Country with(rowlock) where winlostdate < '2021-10-29 00:00:00' and custid <> 3
	if @@rowcount = 0
		break
end

