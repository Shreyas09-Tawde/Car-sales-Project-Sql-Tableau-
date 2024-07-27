--INSPECTING DATA
select * from sales_data_sample; 

select max(ORDERDATE)
from sales_data_sample;

--CHECKING UNIQUE VALUES

select distinct status  -- to plot
from sales_data_sample;

select distinct YEAR_ID  
from sales_data_sample;

select distinct PRODUCTLINE  --to plot
from sales_data_sample;

select distinct PRODUCTLINE  -- to plot
from sales_data_sample;

select distinct country  -- to plot
from sales_data_sample;

select distinct country  -- to plot
from sales_data_sample;

select distinct DEALSIZE  -- to plot
from sales_data_sample;

select distinct TERRITORY  -- to plot
from sales_data_sample;

select distinct month_id 
from sales_data_sample
where YEAR_ID = 2005;

--ANALYSIS
---grouping sales by productline

select productline , sum(sales) as revenue
from sales_data_sample
group by productline
order by 2 desc;

select YEAR_ID , sum(sales) as revenue
from sales_data_sample
group by YEAR_ID
order by 2 desc;

select MONTH_ID, avg(sales) 
from sales_data_sample
where YEAR_ID = 2005 
group by MONTH_ID
order by 2 desc;

select DEALSIZE , sum(sales) as revenue
from sales_data_sample
group by DEALSIZE
order by 2 desc;

---what is the best month for sales in a specific year? how much was earned in that month?

select MONTH_ID , sum(sales) as revenue , count(ORDERNUMBER) as frequency
from sales_data_sample
where YEAR_ID = 2004
group by MONTH_ID
order by 2 desc;

--November is the best selling month, what product do they sell in november?

select month_id , productline ,sum(sales) as revenue , count(ORDERNUMBER) as frequency
from sales_data_sample
where YEAR_ID = 2004 and MONTH_ID = 11
group by month_id , productline
order by 3 desc;

-- who is our best customer? --(using RFM)

IF OBJECT_ID('tempdb..#rfm') IS NOT NULL
    DROP TABLE #rfm;

;with rfm as
(
	select 
		customername,
		sum(sales) as Monetary_value,
		avg(sales) as avg_monetary_value,
		count(ordernumber) as frequency,
		max(orderdate) as last_order_date,
		(select max(orderdate) from sales_data_sample) as max_order_date,
		datediff(dd,max(orderdate),(select max(orderdate) from sales_data_sample)) as Recency
	from sales_data_sample
	group by CUSTOMERNAME
),
rfm_calc as
(
	select r.*,
		NTILE(4) over (order by recency desc) as rfm_recency,
		NTILE(4) over (order by frequency) as rfm_frequency,
		NTILE(4) over (order by monetary_value) as rfm_monetary
	from rfm r
)
select 
	c.*,rfm_recency + rfm_frequency + rfm_monetary as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary as varchar) as rfm_cell_string
into #rfm
from rfm_calc as c

select CUSTOMERNAME ,rfm_recency , rfm_frequency , rfm_monetary,
	case
		when rfm_cell_string in (111,112,121,122,123,132,211,212,114,141) then 'lost customer' --lost customers
		when rfm_cell_string in (133,134,143,244,334,343,344,144) then 'slipping away, cannot loose' --Big spenders who havent purchased lately, slipping away
		when rfm_cell_string in (311,411,331) then 'new customers'
		when rfm_cell_string in (222,223,233,322) then 'potential churners' 
		when rfm_cell_string in (323,333,321,422,332,432) then 'active' --customers who buy often & recently, but at a low prize points
		when rfm_cell_string in (433,434,443,444) then 'loyal customers'
	end rfm_segment		
from #rfm;


-- what products are often sold together?
---select * from sales_data_sample where ordernumber = 10411;

select distinct ordernumber,  stuff(
	(
	select ','+ productcode
	from sales_data_sample as p	
	where ordernumber in 
		(
			select ordernumber
			from (
				select ordernumber , count(*) as rn
				from sales_data_sample
				where status = 'Shipped'
				group by ordernumber
			)as m
			where rn = 3
		)
		and p.ORDERNUMBER = s.ORDERNUMBER
		for xml path ('')),
		
		1,1,'') as productcodes

from sales_data_sample as s
order by 2 desc;