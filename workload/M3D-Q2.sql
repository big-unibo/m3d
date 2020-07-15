set graph_path=unibench_graph;

-- Q201 total price by vendor, rating for the customers known by a given customer, for a given month
select sum(totalPrice), vendorname, rating
from (
	select (o.infoorder->>'TotalPrice')::float as totalPrice, 
		(xpath('//infoproduct/vendor/text()',p.infoproduct))[1]::varchar as vendorname, 
		o.idcust idcust_o, skeys(p.feedback) idcust_f, svals(p.feedback) rating
	from m3d_fact_order o, m3d_dim_date d, m3d_dim_product p,
		(MATCH (:customer {idcust: 132991})-[:KNOWS]->(c:Customer) RETURN c.idcust) c,
		jsonb_array_elements(o.infoorder->'Orderline') as op
	where op->>'asin' = p.asin and o.iddate = d.iddate 
		and o.idcust = c.idcust::varchar::bigint
		and d.monthofyear = 10
) as x
where idcust_o = idcust_f::bigint
group by vendorname, rating;

-- Q202 number of orders by industry, rating for the customers known by a given customer, for a given month
select count(distinct oid) as NumberofOrders, vendorindustry, rating
from (
	select o.ctid oid, 
		(xpath('//infoproduct/vendorindustry/text()',p.infoproduct))[1]::varchar as vendorindustry, 
		o.idcust idcust_o, skeys(p.feedback) idcust_f, svals(p.feedback) rating
	from m3d_fact_order o, m3d_dim_date d, m3d_dim_product p,
		(MATCH (:customer {idcust: 132991})-[:KNOWS]->(c:Customer) RETURN c.idcust) c,
		jsonb_array_elements(o.infoorder->'Orderline') as op
	where op->>'asin' = p.asin and o.iddate = d.iddate 
		and o.idcust = c.idcust::varchar::bigint
		and d.monthofyear = 10
) as x
where idcust_o = idcust_f::bigint
group by vendorindustry, rating;

-- Q203 total price by customers for a given product and a given period
select sum((o.infoorder->>'TotalPrice')::float) as totalPrice, o.idcust
from m3d_fact_order o, m3d_dim_date d,
	jsonb_array_elements(o.infoorder->'Orderline') as op
where o.iddate = d.iddate 
	and d.year = 2020 and op->>'asin' = 'B0000224UE'
group by o.idcust;

-- Q204 number of orders by customers for a given product and a given period, for bad ratings
select sum((o.infoorder->>'TotalPrice')::float) as totalPrice, o.idcust
from m3d_fact_order o, m3d_dim_date d,
	jsonb_array_elements(o.infoorder->'Orderline') as op,
	(
		select skeys(p.feedback) idcust, asin, svals(p.feedback) rating 
		from m3d_dim_product p
		where p.asin = 'B0000224UE'
	) as cp
where o.iddate = d.iddate and op->>'asin' = cp.asin and cp.idcust::bigint = o.idcust
	and d.year = 2020 and op->>'asin' = 'B0000224UE' and cp.rating::float <= 3.0
group by o.idcust;

-- Q205 total price for 2 given customers and their friends (3-hop)
select sum((o.infoorder->>'TotalPrice')::float) as totalPrice
from m3d_fact_order o, 
	( MATCH (c1:Customer)-[:KNOWS*1..3]->(c:Customer) 
	  WHERE c1.idcust = 132991 or c1.idcust = 140680
	  RETURN c.idcust 
	  UNION
	  MATCH (c:Customer) 
	  WHERE c.idcust = 132991 or c.idcust = 140680
	  RETURN c.idcust ) c
where o.idcust = c.idcust::varchar::bigint;

-- Q206 total price by rating for 2 given customers and their friends (3-hop), for a given product and for high ratings
select sum((o.infoorder->>'TotalPrice')::float) as totalPrice, cp.rating
from m3d_fact_order o, 
	( MATCH (c1:Customer)-[:KNOWS*1..3]->(c:Customer) 
	  WHERE c1.idcust = 132991 or c1.idcust = 140680
	  RETURN c.idcust 
	  UNION
	  MATCH (c:Customer) 
	  WHERE c.idcust = 132991 or c.idcust = 140680
	  RETURN c.idcust ) c,
	jsonb_array_elements(o.infoorder->'Orderline') as op,
	(
		select skeys(p.feedback) idcust, asin, svals(p.feedback) rating 
		from m3d_dim_product p
	) as cp
where o.idcust = c.idcust::varchar::bigint and op->>'asin' = cp.asin
	and o.idcust = cp.idcust::bigint and cp.rating::float >= 4.0
group by cp.rating;

-- Q207 total price by customer, product for 2 given customers and the customers in the shortest path between them
select sum((o.infoorder->>'TotalPrice')::float) as totalPrice, o.idcust
from m3d_fact_order o, 
	( MATCH p=allShortestPaths((a:Customer {idcust: 132991})-[:KNOWS*]->(b:Customer {idcust: 140644}))
	  UNWIND nodes(p) AS c
	  RETURN c.idcust ) c
where o.idcust = c.idcust::varchar::bigint
group by o.idcust;

-- Q208 total price by product, rating, connected customers for a given year, for a given vendor country, for a given gender, for some total price
select sum((o.infoorder->>'TotalPrice')::float) as totalPrice, cp.asin, c.idcust, cp.rating
from m3d_fact_order o, m3d_dim_date d,
	(MATCH (:customer {gender: 'female'})-[:KNOWS]->(c:Customer) RETURN c.idcust) c,
	jsonb_array_elements(o.infoorder->'Orderline') as op,
	(
		select skeys(p.feedback) idcust, asin, svals(p.feedback) rating 
		from m3d_dim_product p
		where (xpath('//infoproduct/vendorcountry/text()',p.infoproduct))[1]::varchar = 'China'
	) as cp
where op->>'asin' = cp.asin and o.iddate = d.iddate 
	and o.idcust = c.idcust::varchar::bigint and cp.idcust::bigint = o.idcust
	and d.year = 2019
group by cp.asin, c.idcust, cp.rating
having sum((o.infoorder->>'TotalPrice')::float) <= 100;

-- Q209 total price by industry, for a given country, order by total price
select sum((o.infoorder->>'TotalPrice')::float) as totalPrice, cp.vendorindustry
from m3d_fact_order o,
	jsonb_array_elements(o.infoorder->'Orderline') as op,
	(
		select asin, (xpath('//infoproduct/vendorindustry/text()',p.infoproduct))[1]::varchar vendorindustry
		from m3d_dim_product p
		where (xpath('//infoproduct/vendorcountry/text()',p.infoproduct))[1]::varchar = 'China'
	) as cp
where op->>'asin' = cp.asin
group by cp.vendorindustry
order by totalPrice;

-- Q210 total price by vendor country, order by vendor country for the top 3 customers
select sum((o.infoorder->>'TotalPrice')::float) as totalPrice, 
	(xpath('//infoproduct/vendorcountry/text()',p.infoproduct))[1]::varchar as vendorcountry 
from m3d_fact_order o, m3d_dim_product p, 
	jsonb_array_elements(o.infoorder->'Orderline') as op
where op->>'asin' = p.asin
	and o.idcust in ( 
		select idcust
		from m3d_fact_order
		group by idcust
		order by sum((infoorder->>'TotalPrice')::float) desc 
		limit 3 )
group by (xpath('//infoproduct/vendorcountry/text()',p.infoproduct))[1]::varchar
order by (xpath('//infoproduct/vendorcountry/text()',p.infoproduct))[1]::varchar;