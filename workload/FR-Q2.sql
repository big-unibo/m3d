-- Q201 total price by vendor, rating for the customers known by a given customer, for a given month
select sum(totalprice) as totalPrice, p.vendorname, cp.rating		
from fr_fact_order o, fr_dim_date d, fr_dim_product p, fr_bt_customer_knows_customer ckc, 
	fr_bt_feedback cp, fr_bt_order_product op
where op.asin = p.asin and op.idgroup = o.idgroup and o.iddate = d.iddate 
	and o.idcust = cp.idcust and cp.asin = p.asin and ckc.idcust_to = o.idcust
	and d.monthofyear=10 and ckc.idcust_from = 132991 
group by p.vendorname, cp.rating;

-- Q202 number of orders by industry, rating for the customers known by a given customer, for a given month
select count(distinct o.ctid) as NumberofOrders, p.vendorindustry, cp.rating		
from fr_fact_order o, fr_dim_date d, fr_dim_product p, fr_bt_customer_knows_customer ckc, 
	fr_bt_feedback cp, fr_bt_order_product op
where op.asin = p.asin and op.idgroup = o.idgroup and o.iddate = d.iddate 
	and o.idcust = cp.idcust and cp.asin = p.asin and ckc.idcust_to = o.idcust
	and d.monthofyear=10 and ckc.idcust_from = 132991 
group by p.vendorindustry, cp.rating;

-- Q203 total price by customers for a given product and a given period
select sum(totalprice) as totalPrice, o.idcust		
from fr_fact_order o, fr_dim_date d, fr_bt_order_product op
where op.idgroup = o.idgroup and o.iddate = d.iddate
	and d.year=2020 and op.asin = 'B0000224UE'
group by o.idcust;

-- Q204 number of orders by customers for a given product and a given period, for bad ratings
select sum(totalprice) as totalPrice, o.idcust		
from fr_fact_order o, fr_dim_date d, fr_bt_order_product op, fr_bt_feedback cp
where op.idgroup = o.idgroup and o.iddate = d.iddate
	and o.idcust = cp.idcust and cp.asin = op.asin
	and d.year=2020 and op.asin = 'B0000224UE' and cp.rating <= 3.0
group by o.idcust;

-- Q205 total price for 2 given customers and their friends (3-hop)
select sum(totalprice) as totalPrice
from fr_fact_order o
where o.idcust in (132991,140680) or o.idcust in (
	select distinct c1.idcust_to
	from fr_bt_customer_knows_customer c1
	where c1.idcust_from in (132991,140680)
	union
	select distinct c2.idcust_to
	from fr_bt_customer_knows_customer c1, fr_bt_customer_knows_customer c2
	where c1.idcust_from in (132991,140680)
		and c1.idcust_to = c2.idcust_from
	union
	select distinct c3.idcust_to
	from fr_bt_customer_knows_customer c1, fr_bt_customer_knows_customer c2, 
		fr_bt_customer_knows_customer c3
	where c1.idcust_from in (132991,140680)
		and c1.idcust_to = c2.idcust_from and c2.idcust_to = c3.idcust_from
);

-- Q206 total price by rating for 2 given customers and their friends (3-hop), for a given product and for high ratings
select sum(totalprice) as totalPrice, cp.rating	
from fr_fact_order o, fr_bt_feedback cp, fr_bt_order_product op	
where op.asin = op.asin and op.idgroup = o.idgroup
	and o.idcust = cp.idcust and cp.asin = op.asin
	and (
		o.idcust in (132991,140680) or o.idcust in (
			select distinct c1.idcust_to
			from fr_bt_customer_knows_customer c1
			where c1.idcust_from in (132991,140680)
			union
			select distinct c2.idcust_to
			from fr_bt_customer_knows_customer c1, fr_bt_customer_knows_customer c2
			where c1.idcust_from in (132991,140680)
				and c1.idcust_to = c2.idcust_from
			union
			select distinct c3.idcust_to
			from fr_bt_customer_knows_customer c1, fr_bt_customer_knows_customer c2, 
				fr_bt_customer_knows_customer c3
			where c1.idcust_from in (132991,140680)
				and c1.idcust_to = c2.idcust_from and c2.idcust_to = c3.idcust_from
		)
	)
	and cp.rating >= 4.0 and op.asin = 'B0000224UE'
group by cp.rating;

-- Q207 total price by customer, product for 2 given customers and the customers in the shortest path between them
with recursive t(idcust_from, idcust_to, dist) as (
	select idcust_from, idcust_to, 1 
	from fr_bt_customer_knows_customer
	union
	select t.idcust_from, g.idcust_to, dist+1 
	from fr_bt_customer_knows_customer g, t
	where t.idcust_to = g.idcust_from
	and t.idcust_from = 132991
), minpath(idcust_from, idcust_to, dist) as (
	select idcust_from, idcust_to, min(dist) as dist 
	from t 
	group by idcust_from, idcust_to
)
select sum(totalprice) as totalPrice, o.idcust
from fr_fact_order o
where o.idcust in (
	select distinct m1.idcust_to
	from minpath m1, minpath m2, minpath m3 
	where m1.idcust_from = 132991 and m1.idcust_to = m2.idcust_from	and m2.idcust_to = 140644
		and m3.idcust_from = 132991	and m3.idcust_to = 140644 and m3.dist=m1.dist+m2.dist
)
group by o.idcust;

-- Q208 total price by product, rating, connected customers for a given year, for a given vendor country, for a given gender, for some total price
select sum(totalprice) as totalPrice, o.idcust, cp.rating, op.asin		
from fr_fact_order o, fr_dim_date d, fr_dim_product p, fr_bt_customer_knows_customer ckc, 
	fr_dim_customer c, fr_bt_feedback cp, fr_bt_order_product op
where op.asin = p.asin and op.idgroup = o.idgroup and o.iddate = d.iddate 
	and o.idcust = cp.idcust and cp.asin = p.asin and ckc.idcust_to = o.idcust
	and ckc.idcust_from = c.idcust
	and c.gender = 'female' and d.year = 2019 and p.vendorcountry = 'China'
group by o.idcust, cp.rating, op.asin
having sum(totalprice) <= 100;

-- Q209 total price by industry, for a given country, order by total price
select sum(totalprice) as totalPrice, p.vendorindustry		
from fr_fact_order o, fr_dim_product p, fr_bt_order_product op
where op.asin = p.asin and op.idgroup = o.idgroup 
	and p.vendorcountry = 'China'
group by p.vendorindustry
order by totalprice;

-- Q210 total price by vendor country, order by vendor country for the top 3 customers
select sum(totalprice) as totalPrice, p.vendorcountry
from fr_fact_order o, fr_dim_product p, fr_bt_order_product op
where op.asin = p.asin and op.idgroup = o.idgroup
	and o.idcust in (
		select idcust
		from fr_fact_order
		group by idcust
		order by sum(totalprice) desc
		limit 3
	)
group by p.vendorcountry
order by p.vendorcountry;