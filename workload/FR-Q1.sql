-- Q101: No MM feature
select count(distinct o.ctid) as NumberofOrders, d.monthofyear
from fr_fact_order o, fr_dim_date d
where o.iddate = d.iddate
group by d.monthofyear;

-- Q102: JSON unnesting
select count(distinct o.ctid) as NumberofOrders, op.asin
from fr_fact_order o, fr_bt_order_product op
where o.idgroup = op.idgroup
group by op.asin;

-- Q103: JSON indexing
select count(distinct o.ctid) as NumberofOrders, op.asin
from fr_fact_order o, fr_bt_order_product op
where o.idgroup = op.idgroup 
	and op.asin = 'B0000224UE'
group by op.asin;

-- Q104: Access to XML
select count(distinct o.ctid) as NumberofOrders, p.vendorname
from fr_fact_order o, fr_bt_order_product op, fr_dim_product p
where o.idgroup = op.idgroup and op.asin = p.asin
group by p.vendorname;

-- Q105: Indexing on XML
select count(distinct o.ctid) as NumberofOrders, p.vendorname
from fr_fact_order o, fr_bt_order_product op, fr_dim_product p
where o.idgroup = op.idgroup and op.asin = p.asin
	and p.vendorcountry = 'China'
group by p.vendorname;

-- Q106: Access to KV (whole content)
select count(distinct o.ctid) as NumberofOrders, cp.rating
from fr_fact_order o, fr_bt_feedback cp, fr_bt_order_product op
where o.idgroup = op.idgroup and cp.idcust = o.idcust and op.asin = cp.asin 
group by cp.rating;

-- Q107: Access to KV (selection on one side)
select count(distinct o.ctid) as NumberofOrders, cp.rating
from fr_fact_order o, fr_bt_feedback cp, fr_bt_order_product op, fr_dim_product p
where o.idgroup = op.idgroup and cp.idcust = o.idcust and op.asin = cp.asin and op.asin = p.asin
	and p.vendorcountry = 'China'
group by cp.rating;

-- Q108: Access to KV (selection on both sides)
select count(distinct o.ctid) as NumberofOrders, cp.rating
from fr_fact_order o, fr_bt_feedback cp, fr_bt_order_product op, fr_dim_product p, fr_dim_customer c
where o.idgroup = op.idgroup and cp.idcust = o.idcust and op.asin = cp.asin and op.asin = p.asin and cp.idcust = c.idcust
	and p.vendorcountry = 'China' and c.lastname = 'Thompson'
group by cp.rating;

-- Q109: Graph navigation (wide)
select count(distinct o.ctid) as NumberofOrders, c.browserUsed
from fr_fact_order o, fr_dim_customer c, fr_bt_customer_knows_customer ckc,	fr_dim_customer c1
where o.idcust = c.idcust and ckc.idcust_to = c.idcust and ckc.idcust_from = c1.idcust
	and c1.gender = 'female'
group by c.browserUsed;

-- Q110: Graph navigation (deep)
select count(distinct o.ctid) as NumberofOrders, c.browserUsed
from fr_fact_order o, fr_dim_customer c, fr_bt_customer_knows_customer ckc, fr_bt_customer_knows_customer ckc1,	fr_dim_customer c2
where o.idcust = c.idcust and c.idcust = ckc.idcust_to and ckc.idcust_from = ckc1.idcust_to and ckc1.idcust_from = c2.idcust
	and c2.locationIp = '1.0.10.131'
group by c.browserUsed;