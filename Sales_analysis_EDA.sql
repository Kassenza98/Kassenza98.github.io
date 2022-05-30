### We will perform a quick EDA on sales database before creating a Tableau Dashboard

##1) Repartition of customers by type

select count(distinct customer_type)
from customers;

select customer_type,count(*) as 'Total customer'
from customers
group by customer_type;

# We have 38 customers and they are equally divided between phyisical and e-commerce 

##2) Find the most 3 sold products by year
create temporary table top3products
with 
total_sales as 
(
	select product_code,year,sum(sales_amount) as year_sale
	from transactions t
	join date d
		on t.order_date=d.date
	group by year,product_code
	order by year DESC,year_sale DESC
),
ranked_total_sales as
(
select *,rank() over(partition by year order by year_sale DESC) as rnk
from total_sales
),
yearlytop3_products as 
(
select * 
from ranked_total_sales
where rnk <= 3
)

select * from yearlytop3_products;
----------

select * from top3products;

##3) Find the top3 markets by year
create temporary table top3markets

with 
total_sales_market as 
(
	select market_code,year,sum(sales_amount) as year_sale_market
	from transactions t
	join date d
		on t.order_date=d.date
	group by year,market_code
	order by year DESC,year_sale_market DESC
),
ranked_total_sales_market as
(
select *,rank() over(partition by year order by year_sale_market DESC) as rnk_market
from total_sales_market
),
yearlytop3_market as 
(
select * 
from ranked_total_sales_market
where rnk_market <= 3
)

select ym.* , markets_name,zone
from yearlytop3_market ym
join markets m
	on ym.market_code=m.markets_code
order by year DESC, rnk_market ;
-------

select * from top3markets;
select zone,count(*)
from top3markets
group by zone;

#We see that South's market aren't in the top 3

##4) Find yearly sales evolution amount per region

create temporary table year_sale_by_zone

select zone,year,sum(sales_amount) as year_sale
from transactions t
join markets m
	on t.market_code=m.markets_code
join date d
	on t.order_date=d.date
group by zone,year
order by zone,year;

select *,round(100*(year_sale-lag(year_sale)over(partition by zone))/lag(year_sale) over(partition by zone),0) as year_evolution
from year_sale_by_zone;

# We can see a strong increase in sales from 2017 to 2018 for all regions and two years of decreasing also for all regions


##5) Find the monthly sales repartition by year

select month_name,round(100*sum(sales_amount)/(
	select sum(sales_amount)
	from transactions t
	join date d
		on t.order_date=d.date
	where year=2019
),1) as monthly_sale_percentage
from transactions t
join date d
	on t.order_date=d.date
where year=2019
group by month_name;

##6) Does our lower profit margin come from distribution products ?

select t.product_code, product_type, ceil(avg(profit_margin)) as avg_profit
from transactions t
join products p
	on t.product_code=p.product_code
group by product_code
order by 3
limit 5;

# 4 of the 5 least profitable products are from our own brand

##7) Least profitable markets

select market_code,markets_name,zone, ceil(avg(profit_margin)) as avg_profit
from transactions t
join markets m
	on t.market_code=m.markets_code
group by market_code
order by 4
limit 5;

##8) Find markets with a profit greater than average

select market_code,markets_name,zone,ceil(sum(profit_margin)) as profit
from transactions t
join markets m
	on t.market_code=m.markets_code
group by market_code
having profit >(select ceil(avg(a.total_profit)) as avg_profit
				from(
					select market_code,ceil(sum(profit_margin)) as total_profit
					from transactions
					group by market_code)a
)
order by profit DESC;

##9) Find average profit per market by region

select zone,ceil(avg(total_profit)) as avg_profit
from
(
select market_code,zone,sum(profit_margin) as total_profit
from transactions t
join markets m
	on t.market_code=m.markets_code
group by market_code
)a
group by zone
order by avg_profit DESC

#North's zone has the highest total profit average