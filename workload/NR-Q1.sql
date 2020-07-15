set graph_path=unibench_graph;

-- Q101: No MM feature
select count(*) as NumberofOrders, to_char(to_date((o.infoorder->>'OrderDate')::text,'YYYY-MM-DD'),'MM') as month
from nr_fact_order o
group by to_char(to_date((o.infoorder->>'OrderDate')::text,'YYYY-MM-DD'),'MM');

-- Q102: JSON unnesting
select count(distinct o.ctid) as NumberofOrders, op->>'asin'
from nr_fact_order o,
	jsonb_array_elements(o.infoorder->'Orderline') as op
group by op->>'asin';

-- Q103: JSON indexing
select count(distinct o.ctid) as NumberofOrders, op->>'asin'
from nr_fact_order o,
	jsonb_array_elements(o.infoorder->'Orderline') as op
where o.infoorder->'Orderline' @> '[{"asin":"B0000224UE"}]'
	and op->>'asin' = 'B0000224UE'
group by op->>'asin';

-- Q104: Access to XML
select count(distinct o.ctid) as NumberofOrders, (xpath('//infoproduct/vendor/text()',p.infoproduct))[1]::varchar
from nr_fact_order o, nr_dim_product p, 
	jsonb_array_elements(o.infoorder->'Orderline') as op
where op->>'asin' = (xpath('//infoproduct/asin/text()',p.infoproduct))[1]::varchar
group by (xpath('//infoproduct/vendor/text()',p.infoproduct))[1]::varchar;

-- Q105: Indexing on XML
select count(distinct o.ctid) as NumberofOrders, (xpath('//infoproduct/vendor/text()',p.infoproduct))[1]::varchar
from nr_fact_order o, nr_dim_product p, 
	jsonb_array_elements(o.infoorder->'Orderline') as op
where op->>'asin' = (xpath('//infoproduct/asin/text()',p.infoproduct))[1]::varchar
	and (xpath('//infoproduct/vendorcountry/text()',p.infoproduct))[1]::varchar = 'China'
group by (xpath('//infoproduct/vendor/text()',p.infoproduct))[1]::varchar;

-- Q106: Access to KV (whole content)
select count(distinct o.ctid) as NumberofOrders, f.v
from nr_fact_order o, nr_bt_feedback f,
	jsonb_array_elements(o.infoorder->'Orderline') as op
where concat(op->>'asin',',',o.infoorder->>'idcust') = f.k 
group by f.v;

-- Q107: Access to KV (selection on one side)
select count(distinct o.ctid) as NumberofOrders, f.v
from nr_fact_order o, nr_bt_feedback f, nr_dim_product p,
	jsonb_array_elements(o.infoorder->'Orderline') as op
where concat(op->>'asin',',',o.infoorder->>'idcust') = f.k 
	and op->>'asin' = (xpath('//infoproduct/asin/text()',p.infoproduct))[1]::varchar
	and (xpath('//infoproduct/vendorcountry/text()',p.infoproduct))[1]::varchar = 'China'
group by f.v;

-- Q108: Access to KV (selection on both sides)
select count(distinct o.ctid) as NumberofOrders, f.v
from nr_fact_order o, nr_bt_feedback f, nr_dim_product p,
	(MATCH (c:customer {lastname: 'Thompson'}) RETURN c.idcust) c,
	jsonb_array_elements(o.infoorder->'Orderline') as op
where concat(op->>'asin',',',o.infoorder->>'idcust') = f.k 
	and o.infoorder->>'idcust' = c.idcust::varchar
	and op->>'asin' = (xpath('//infoproduct/asin/text()',p.infoproduct))[1]::varchar
	and (xpath('//infoproduct/vendorcountry/text()',p.infoproduct))[1]::varchar = 'China'
group by f.v;

-- Q109: Graph navigation (wide)
select count(distinct o.ctid) as NumberofOrders, c.browserUsed
from nr_fact_order o,
	(MATCH (:Customer {gender: 'female'})-[:KNOWS]->(c:Customer) RETURN c.idcust, c.browserUsed) c
where o.infoorder->>'idcust' = c.idcust::varchar
group by c.browserUsed;

-- Q110: Graph navigation (deep)
select count(distinct o.ctid) as NumberofOrders, c.browserUsed
from nr_fact_order o,
	(MATCH (:Customer {locationIp: '1.0.10.131'})-[:KNOWS]->(:Customer)-[:KNOWS]->(c:Customer) RETURN c.idcust, c.browserUsed) c
where o.infoorder->>'idcust' = c.idcust::varchar 
group by c.browserUsed;

-- Q111: Missing attributes
select count(distinct o.ctid) as NumberofOrders, (xpath('//infoproduct/eu/text()',p.infoproduct))[1]::varchar
from nr_fact_order o, nr_dim_product p,
	jsonb_array_elements(o.infoorder->'Orderline') as op
where op->>'asin' = (xpath('//infoproduct/asin/text()',p.infoproduct))[1]::varchar
	and (xpath('//infoproduct/vendorcountry/text()',p.infoproduct))[1]::varchar = 'China'
group by (xpath('//infoproduct/eu/text()',p.infoproduct))[1]::varchar;

-- Q112: Missing attributes 2
select count(distinct o.ctid) as NumberofOrders, (xpath('//infoproduct/eu/text()',p.infoproduct))[1]::varchar, c.gold
from nr_fact_order o, nr_dim_product p,
	(MATCH (c:customer) RETURN c.idcust, c.gold) c,
	jsonb_array_elements(o.infoorder->'Orderline') as op
where op->>'asin' = (xpath('//infoproduct/asin/text()',p.infoproduct))[1]::varchar 
	and o.infoorder->>'idcust' = c.idcust::varchar
	and (xpath('//infoproduct/vendorcountry/text()',p.infoproduct))[1]::varchar = 'China'
group by (xpath('//infoproduct/eu/text()',p.infoproduct))[1]::varchar, c.gold;