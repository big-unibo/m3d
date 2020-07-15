set graph_path=unibench_graph;

-- Q101: No MM feature
select count(*) as NumberofOrders, d.monthofyear
from m3d_fact_order o, m3d_dim_date d
where o.iddate = d.iddate
group by d.monthofyear;

-- Q102: JSON unnesting
select count(distinct o.ctid) as NumberofOrders, op->>'asin'
from m3d_fact_order o,
	jsonb_array_elements(o.infoorder->'Orderline') as op
group by op->>'asin';

-- Q103: JSON indexing
select count(distinct o.ctid) as NumberofOrders, op->>'asin'
from m3d_fact_order o,
	jsonb_array_elements(o.infoorder->'Orderline') as op
where o.infoorder->'Orderline' @> '[{"asin":"B0000224UE"}]'
	and op->>'asin' = 'B0000224UE'
group by op->>'asin';

-- Q104: Access to XML
select count(distinct o.ctid) as NumberofOrders, (xpath('//infoproduct/vendor/text()',p.infoproduct))[1]::varchar
from m3d_fact_order o, m3d_dim_product p, 
	jsonb_array_elements(o.infoorder->'Orderline') as op
where op->>'asin' = p.asin
group by (xpath('//infoproduct/vendor/text()',p.infoproduct))[1]::varchar;

-- Q105: Indexing on XML
select count(distinct o.ctid) as NumberofOrders, (xpath('//infoproduct/vendor/text()',p.infoproduct))[1]::varchar
from m3d_fact_order o, m3d_dim_product p, 
	jsonb_array_elements(o.infoorder->'Orderline') as op
where op->>'asin' = p.asin
	and (xpath('//infoproduct/vendorcountry/text()',p.infoproduct))[1]::varchar = 'China'
group by (xpath('//infoproduct/vendor/text()',p.infoproduct))[1]::varchar;

-- Q106: Access to KV (whole content)
select count(distinct o.ctid) as NumberofOrders, cp.rating
from m3d_fact_order o,
	jsonb_array_elements(o.infoorder->'Orderline') as op,
	(
		select skeys(p.feedback) idcust, asin, svals(p.feedback) rating 
		from m3d_dim_product p
	) as cp
where op->>'asin' = cp.asin and cp.idcust::bigint = o.idcust 
group by cp.rating;

-- Q107: Access to KV (selection on one side)
select count(distinct o.ctid) as NumberofOrders, cp.rating
from m3d_fact_order o,
	jsonb_array_elements(o.infoorder->'Orderline') as op,
	(
		select skeys(p.feedback) idcust, asin, svals(p.feedback) rating 
		from m3d_dim_product p
		where (xpath('//infoproduct/vendorcountry/text()',p.infoproduct))[1]::varchar = 'China'
	) as cp
where op->>'asin' = cp.asin and cp.idcust::bigint = o.idcust 
group by cp.rating;

-- Q108: Access to KV (selection on both sides)
select count(distinct o.ctid) as NumberofOrders, cp.rating
from m3d_fact_order o,
	(MATCH (c:customer {lastname: 'Thompson'}) RETURN c.idcust) c,
	jsonb_array_elements(o.infoorder->'Orderline') as op,
	(
		select skeys(p.feedback) idcust, asin, svals(p.feedback) rating 
		from m3d_dim_product p
		where (xpath('//infoproduct/vendorcountry/text()',p.infoproduct))[1]::varchar = 'China'
	) as cp
where op->>'asin' = cp.asin and cp.idcust::bigint = o.idcust and o.idcust = c.idcust::varchar::bigint
group by cp.rating;

-- Q109: Graph navigation (wide)
select count(distinct o.ctid) as NumberofOrders, c.browserUsed
from m3d_fact_order o,
	(MATCH (:Customer {gender: 'female'})-[:KNOWS]->(c:Customer) RETURN c.idcust, c.browserUsed) c
where o.idcust = c.idcust::varchar::bigint
group by c.browserUsed;

-- Q110: Graph navigation (deep)
select count(distinct o.ctid) as NumberofOrders, c.browserUsed
from m3d_fact_order o,
	(MATCH (:Customer {locationIp: '1.0.10.131'})-[:KNOWS]->(:Customer)-[:KNOWS]->(c:Customer) RETURN c.idcust, c.browserUsed) c
where o.idcust = c.idcust::varchar::bigint 
group by c.browserUsed;

-- Q111: Missing attributes
select count(distinct o.ctid) as NumberofOrders, (xpath('//infoproduct/eu/text()',p.infoproduct))[1]::varchar
from m3d_fact_order o, m3d_dim_product p,
	jsonb_array_elements(o.infoorder->'Orderline') as op
where op->>'asin' = p.asin and (xpath('//infoproduct/vendorcountry/text()',p.infoproduct))[1]::varchar = 'China'
group by (xpath('//infoproduct/eu/text()',p.infoproduct))[1]::varchar;

-- Q112: Missing attributes 2
select count(distinct o.ctid) as NumberofOrders, (xpath('//infoproduct/eu/text()',p.infoproduct))[1]::varchar, c.gold
from m3d_fact_order o, m3d_dim_product p,
	(MATCH (c:customer) RETURN c.idcust, c.gold) c,
	jsonb_array_elements(o.infoorder->'Orderline') as op
where op->>'asin' = p.asin and o.idcust = c.idcust::varchar::bigint 
	 and (xpath('//infoproduct/vendorcountry/text()',p.infoproduct))[1]::varchar = 'China'
group by (xpath('//infoproduct/eu/text()',p.infoproduct))[1]::varchar, c.gold;