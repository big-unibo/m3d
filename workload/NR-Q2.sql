set graph_path=unibench_graph;

-- Q201 total price by vendor, rating for the customers known by a given customer, for a given month
select sum((o.infoorder->>'TotalPrice')::float) as totalPrice, 
	(xpath('//infoproduct/vendor/text()',p.infoproduct))[1]::varchar as vendor, f.v
from nr_fact_order o, nr_bt_feedback f, nr_dim_product p,
	(MATCH (:customer {idcust: 132991})-[:KNOWS]->(c:Customer) RETURN c.idcust) c,
	jsonb_array_elements(o.infoorder->'Orderline') as op
where op->>'asin' = (xpath('//infoproduct/asin/text()',p.infoproduct))[1]::varchar
	and concat(op->>'asin',',',o.infoorder->>'idcust') = f.k 
	and o.infoorder->>'idcust' = c.idcust::varchar
	and to_char(to_date((o.infoorder->>'OrderDate')::text,'YYYY-MM-DD'),'MM')::int = 10
group by (xpath('//infoproduct/vendor/text()',p.infoproduct))[1]::varchar, f.v;

-- Q202 number of orders by industry, rating for the customers known by a given customer, for a given month
select count(distinct o.ctid) as NumberofOrders, 
	(xpath('//infoproduct/vendorindustry/text()',p.infoproduct))[1]::varchar as vendorindustry, f.v
from nr_fact_order o, nr_bt_feedback f, nr_dim_product p,
	(MATCH (:customer {idcust: 132991})-[:KNOWS]->(c:Customer) RETURN c.idcust) c,
	jsonb_array_elements(o.infoorder->'Orderline') as op
where op->>'asin' = (xpath('//infoproduct/asin/text()',p.infoproduct))[1]::varchar
	and concat(op->>'asin',',',o.infoorder->>'idcust') = f.k 
	and o.infoorder->>'idcust' = c.idcust::varchar
	and to_char(to_date((o.infoorder->>'OrderDate')::text,'YYYY-MM-DD'),'MM')::int = 10
group by (xpath('//infoproduct/vendorindustry/text()',p.infoproduct))[1]::varchar, f.v;

-- Q203 total price by customers for a given product and a given period
select sum((o.infoorder->>'TotalPrice')::float) as totalPrice, o.infoorder->>'idcust'
from nr_fact_order o,
	jsonb_array_elements(o.infoorder->'Orderline') as op
where op->>'asin' = 'B0000224UE'
	and to_char(to_date((o.infoorder->>'OrderDate')::text,'YYYY-MM-DD'),'YYYY')::int = 2020
group by o.infoorder->>'idcust';

-- Q204 number of orders by customers for a given product and a given period, for bad ratings
select sum((o.infoorder->>'TotalPrice')::float) as totalPrice, o.infoorder->>'idcust'
from nr_fact_order o, nr_bt_feedback f,
	jsonb_array_elements(o.infoorder->'Orderline') as op
where concat(op->>'asin',',',o.infoorder->>'idcust') = f.k 
	and op->>'asin' = 'B0000224UE' and f.v <= 3.0
	and to_char(to_date((o.infoorder->>'OrderDate')::text,'YYYY-MM-DD'),'YYYY')::int = 2020
group by o.infoorder->>'idcust';

-- Q205 total price for 2 given customers and their friends (3-hop)
select sum((o.infoorder->>'TotalPrice')::float) as totalPrice
from nr_fact_order o, 
	( MATCH (c1:Customer)-[:KNOWS*1..3]->(c:Customer) 
	  WHERE c1.idcust = 132991 or c1.idcust = 140680
	  RETURN c.idcust 
	  UNION
	  MATCH (c:Customer) 
	  WHERE c.idcust = 132991 or c.idcust = 140680
	  RETURN c.idcust ) c
where o.infoorder->>'idcust' = c.idcust::varchar;

-- Q206 total price by rating for 2 given customers and their friends (3-hop), for a given product and for high ratings
select sum((o.infoorder->>'TotalPrice')::float) as totalPrice, f.v
from nr_fact_order o, nr_bt_feedback f,
	jsonb_array_elements(o.infoorder->'Orderline') as op,
	( MATCH (c1:Customer)-[:KNOWS*1..3]->(c:Customer) 
	  WHERE c1.idcust = 132991 or c1.idcust = 140680
	  RETURN c.idcust 
	  UNION
	  MATCH (c:Customer) 
	  WHERE c.idcust = 132991 or c.idcust = 140680
	  RETURN c.idcust ) c
where o.infoorder->>'idcust' = c.idcust::varchar and concat(op->>'asin',',',o.infoorder->>'idcust') = f.k 
	and f.v >= 4.0
group by f.v;

-- Q207 total price by customer, product for 2 given customers and the customers in the shortest path between them
select sum((o.infoorder->>'TotalPrice')::float) as totalPrice, o.infoorder->>'idcust'
from nr_fact_order o, 
	( MATCH p=allShortestPaths((a:Customer {idcust: 132991})-[:KNOWS*]->(b:Customer {idcust: 140644}))
	  UNWIND nodes(p) AS c
	  RETURN c.idcust ) c
where o.infoorder->>'idcust' = c.idcust::varchar
group by o.infoorder->>'idcust';

-- Q208 total price by product, rating, connected customers for a given year, for a given vendor country, for a given gender, for some total price
select sum((o.infoorder->>'TotalPrice')::float) as totalPrice, 
	op->>'asin', c.idcust, f.v
from nr_fact_order o, nr_bt_feedback f, nr_dim_product p,
	(MATCH (:customer {gender: 'female'})-[:KNOWS]->(c:Customer) RETURN c.idcust) c,
	jsonb_array_elements(o.infoorder->'Orderline') as op
where op->>'asin' = (xpath('//infoproduct/asin/text()',p.infoproduct))[1]::varchar
	and concat(op->>'asin',',',o.infoorder->>'idcust') = f.k 
	and o.infoorder->>'idcust' = c.idcust::varchar
	and to_char(to_date((o.infoorder->>'OrderDate')::text,'YYYY-MM-DD'),'YYYY')::int = 2019
	and (xpath('//infoproduct/vendorcountry/text()',p.infoproduct))[1]::varchar = 'China'
group by op->>'asin', c.idcust, f.v
having sum((o.infoorder->>'TotalPrice')::float) <= 100;

-- Q209 total price by industry, for a given country, order by total price
select sum((o.infoorder->>'TotalPrice')::float) as totalPrice, 
	(xpath('//infoproduct/vendorindustry/text()',p.infoproduct))[1]::varchar as vendorindustry
from nr_fact_order o, nr_dim_product p,
	jsonb_array_elements(o.infoorder->'Orderline') as op
where op->>'asin' = (xpath('//infoproduct/asin/text()',p.infoproduct))[1]::varchar
	and (xpath('//infoproduct/vendorcountry/text()',p.infoproduct))[1]::varchar = 'China'
group by (xpath('//infoproduct/vendorindustry/text()',p.infoproduct))[1]::varchar
order by totalPrice;

-- Q210 total price by vendor country, order by vendor country for the top 3 customers
select sum((o.infoorder->>'TotalPrice')::float) as totalPrice, 
	(xpath('//infoproduct/vendorcountry/text()',p.infoproduct))[1]::varchar as vendorcountry 
from nr_fact_order o, nr_dim_product p, 
	jsonb_array_elements(o.infoorder->'Orderline') as op
where op->>'asin' = (xpath('//infoproduct/asin/text()',p.infoproduct))[1]::varchar
	and o.infoorder->>'idcust' in ( 
		select infoorder->>'idcust' idcust
		from nr_fact_order
		group by infoorder->>'idcust'
		order by sum((infoorder->>'TotalPrice')::float) desc 
		limit 3 )
group by (xpath('//infoproduct/vendorcountry/text()',p.infoproduct))[1]::varchar
order by (xpath('//infoproduct/vendorcountry/text()',p.infoproduct))[1]::varchar;