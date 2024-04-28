-- Month
-- Product Name
-- Variant
-- Sold Quantity
-- Gross Price Per Item
-- Gross Price Total

select * from dim_customer 
where customer like "%croma%" and market = "India";                             # we will use market because if croma is available in other markets as well

select * from fact_sales_monthly
where customer_code = 90002002 and year(date)=2021
order by date desc;


-- Month 
# For Fiscal Year
select * from fact_sales_monthly
where customer_code = 90002002 and 
year(adddate(date,interval 4 month))=2021
order by date desc;


-- Sold quantity
# We have created a user-define function we will apply and check it in below query
select * from fact_sales_monthly
where customer_code = 90002002 and        
get_fiscal_year(date)=2021 and                     # user define function get_fiscal_year 
get_fiscal_quarter(date)="Q2"                 # Here as you chnage the quarter it will give outputs     # user define function get_fiscal_year 
order by date asc
limit 500000;


-- Product Name and Variant 
 select 
 s.date,s.product_code,
 p.product,p.variant,s.sold_quantity            # The order of writing the code matters as you mention it will provide output in same order
 from fact_sales_monthly s 
 join dim_product p
 on p.product_code = s.product_code 
 where customer_code = 90002002 and get_fiscal_year(date)=2021
 order by date asc;
 
 -- Gross Price per Item and  Gross Price Total
 select 
 s.date,s.product_code,
 p.product,p.variant,s.sold_quantity,     
 g.gross_price,
 Round(g.gross_price * s.sold_quantity,2) as gross_price_total                  -- Gross Price Total
 from fact_sales_monthly s 
 join dim_product p
 on p.product_code = s.product_code 
 join fact_gross_price g
 on g.product_code = s.product_code and
 g.fiscal_year = get_fiscal_year(s.date)
 where customer_code = 90002002 and get_fiscal_year(date)=2021
 order by date asc
 limit 100000;
 
 
 -- Gross Sales Report: Total Sales Amount
 select 
 s.date,
 sum(g.gross_price * s.sold_quantity) as gross_price_total
 from 
 fact_sales_monthly s
 Join fact_gross_price g
 on g.product_code = s.product_code and 
 g.fiscal_year = get_fiscal_year(s.date)
 where customer_code = 90002002
 group by s.date                                    # If you are using group by then we need to give aggregation function in select clause
 order by s.date asc;
 
 /* ------------------------------------Exercise----------------------------------------------*/
 
 -- Fiscal Year
 -- Total Gross Sales amount In that year from Croma
 
 select
            get_fiscal_year(date) as fiscal_year,
            sum(round(sold_quantity*g.gross_price,2)) as yearly_sales
	from fact_sales_monthly s
	join fact_gross_price g
	on 
	    g.fiscal_year=get_fiscal_year(s.date) and
	    g.product_code=s.product_code
	where
	    customer_code=90002002
	group by get_fiscal_year(date)
	order by fiscal_year;


-- Stored Procedures  
-- Stored Procedures help to do repetative task easier and faster by automating it

-- Stored Procedures: Monthly Gross Sales Report
select 
 s.date,
 sum(round(g.gross_price * s.sold_quantity,2)) as monthly_sales 
 from 
 fact_sales_monthly s
 Join fact_gross_price g
  on  g.fiscal_year = get_fiscal_year(s.date)  and 
     g.product_code = s.product_code
 where customer_code in (90002002,90002008)
 group by date;      
 
 
 
 -- India, 2021 --> Gold 
 -- Srilanka, 2020  --> Silver
 
 select 
  #c.market,                                        --when required we can enable it
  sum(sold_quantity) as total_qty
  from fact_sales_monthly s
  join dim_customer c
  on s.customer_code = c.customer_code 
  where get_fiscal_year(s.date) = 2021 and c.market="India"
  group by c.market;
  
  
  -- Problem Statement and Pre-Invoice Discount Report
 #Explain Analyze          -- Performance Improved 1
 select 
 s.date,s.product_code,
 p.product,p.variant,s.sold_quantity,     
 g.gross_price,
 Round(g.gross_price * s.sold_quantity,2) as gross_price_total,                  -- Gross Price Total
 pre.pre_invoice_discount_pct
 from fact_sales_monthly s 
 join dim_product p
 on p.product_code = s.product_code 
 
 Join dim_date dt
 on dt.calendar_date = s.date 
 Join fact_gross_price g
 on g.product_code = s.product_code and
 g.fiscal_year = dt.fiscal_year
 
 Join fact_pre_invoice_deductions pre
 On 
 pre.customer_code=s.customer_code and 
 pre.fiscal_year = dt.fiscal_year
 
where 
dt.fiscal_year=2021
limit 100000;
 
  -- Performance Improved 2 
  
 select 
 s.date,s.product_code,
 p.product,p.variant,s.sold_quantity,     
 g.gross_price,
 Round(g.gross_price * s.sold_quantity,2) as gross_price_total,                  -- Gross Price Total
 pre.pre_invoice_discount_pct
 from fact_sales_monthly s 
 join dim_product p
 on p.product_code = s.product_code 
 
 Join fact_gross_price g
 on g.product_code = s.product_code and
 g.fiscal_year = s.fiscal_year
 
 Join fact_pre_invoice_deductions pre
 On 
 pre.customer_code=s.customer_code and 
 pre.fiscal_year = s.fiscal_year
 
where 
s.fiscal_year=2021
limit 100000;


-- Database Views: Introduction
-- View is virtual query
with cte1 as (select 
 s.date,s.product_code,
 p.product,p.variant,s.sold_quantity,     
 g.gross_price,
 Round(g.gross_price * s.sold_quantity,2) as gross_price_total,                  -- Gross Price Total
 pre.pre_invoice_discount_pct
 # (gross_price_total - gross_price_total*pre_invoice_discount_pct) as net_invoice_sales              -- we cannot use derived field in same query
 from fact_sales_monthly s 
 join dim_product p
 on p.product_code = s.product_code 
 
 Join fact_gross_price g
 on g.product_code = s.product_code and
 g.fiscal_year = s.fiscal_year
 
 Join fact_pre_invoice_deductions pre
 On 
 pre.customer_code=s.customer_code and 
 pre.fiscal_year = s.fiscal_year
 
 where 
 s.fiscal_year=2021)
 select *,
 (gross_price_total - gross_price_total*pre_invoice_discount_pct) as net_invoice_sales
 from cte1;
 
 
# Another way to run above query after creation of views

 select *,
 (gross_price_total - gross_price_total*pre_invoice_discount_pct) as net_invoice_sales
 from sales_preinv_discount;

-- cte create temporary view or temporary table just for that session whereas the views is creating the table for all the sessions 

-- Database Views: Post Invoice Discount, Net Sales

select *,
(1-pre_invoice_discount_pct)*gross_price_total as net_invoice_sales,
(po.discounts_pct+po.other_deductions_pct) as post_invoice_discount_pct
from sales_preinv_discount s
join fact_post_invoice_deductions po
on s.date = po.date and
   s.product_code = po.product_code and
   s.customer_code = po.customer_code;
   
   
-- After creation of sales_postinv_discount

select *,
(1-pre_invoice_discount_pct)*net_invoice_sales as net_sales
from gdb0041.sales_postinv_discount;

/*----------------------------------------------------Exercise------------------------------------------------*/

-- Create a view for gross sales. It should have the following columns,date, fiscal_year, customer_code, customer, market, product_code, product, variant,sold_quanity, gross_price_per_item, gross_price_total

-- View is created in Views

-- Top Markets 

select
     market, round(sum(net_sales)/1000000,2) as net_sales_mln
from gdb0041.net_sales
where fiscal_year = 2021
group by market 
order by net_sales_mln desc
limit 5;


-- Top Customers

select
     c.customer, round(sum(net_sales)/1000000,2) as net_sales_mln
from gdb0041.net_sales n
join dim_customer c 
on n.customer_code = c.customer_code
where fiscal_year = 2021
group by c.customer 
order by net_sales_mln desc
limit 5;


-- Top Products 
-- Stored Procedure

-- Window Functions: OVER Clause

with cte1 as (
    select
        customer,
        round(sum(net_sales) / 1000000, 2) as net_sales_mln
    from
        net_sales s
        join dim_customer c on s.customer_code = c.customer_code
    where
        s.fiscal_year = 2021
    group by
        customer
)
select
    customer,
    net_sales_mln,
    net_sales_mln*100/sum(net_sales_mln) over () as pct
from
    cte1
#group by
    #customer, net_sales_mln
order by
    net_sales_mln desc;

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

-- Exercise: Window Functions: OVER Clause

with cte1 as(
select
        c.customer,
        c.region,
        round(sum(net_sales)/1000000,2) as net_sales_mln
    from
        net_sales s
        join dim_customer c 
        on s.customer_code = c.customer_code
    where s.fiscal_year = 2021
    group by c.customer,c.region)
    
    
    select *,
	   net_sales_mln*100/sum(net_sales_mln) over (partition by region) as pct_share_region 
	from  cte1 
    order by region, net_sales_mln desc;

-- Window Functions: ROW_NUMBER, RANK, DENSE_RANK

with cte1 as(
select 
              p.division,
              p.product,
              sum(sold_quantity) as total_qty
	          from fact_sales_monthly s
              Join dim_product p
              On p.product_code = s.product_code
              where fiscal_year = 2021
              group by p.division,p.product),

cte2 as(select *,
 dense_rank() over (partition by division order by total_qty desc) as drnk
 from cte1)

select * from cte2 where drnk <=3;

-- Retrieve the top 2 markets in every region by their gross sales amount in FY=2021.




with cte1 as (
		select
			c.market,
			c.region,
			round(sum(gross_price)/1000000,2) as gross_sales_mln
			from fact_sales_monthly s
			join dim_customer c
			on c.customer_code=s.customer_code
            Join fact_gross_price p
            on p.product_code = s.product_code
			where s.fiscal_year = 2021
			group by c.market, c.region
			order by gross_sales_mln desc
		),
		cte2 as (
			select *,
			dense_rank() over(partition by region order by gross_sales_mln desc) as drnk
			from cte1
		)
	select * from cte2 where drnk<=2;

-- ------------------------- -- ---------------------- -- ----------------------- -- ----------------------- -- ------------------------- -- ---------------------------------- -- -------------------------------------

-- Supply Chain Analytics

-- Create a Helper Table
/*
select  s.*,
        f.forecast_quantity
	 from gdb0041.fact_sales_monthly s
     left join fact_forecast_monthly f
     using(date, product_code, customer_code)
     where f.forecast_quantity is null;
*/
create table fact_act_est (
select 
	     s.date as date,
         s.fiscal_year as fiscal_year,
         s.product_code as product_code,
         s.customer_code as customer_code,
		 s.sold_quantity as sold_quantity,
		 f.forecast_quantity as forecast_quantity
	from fact_sales_monthly s
    left join fact_forecast_monthly f
    using (date, customer_code, product_code)
    
union

select 
	     s.date as date,
         s.fiscal_year as fiscal_year,
         s.product_code as product_code,
         s.customer_code as customer_code,
		 s.sold_quantity as sold_quantity,
		 f.forecast_quantity as forecast_quantity
	from fact_sales_monthly s
    right join fact_forecast_monthly f
    using (date, customer_code, product_code));
    
select * from gdb0041.fact_act_est;
update fact_act_est
set sold_quantity = 0
where sold_quantity is null;
    
  show triggers;   -- This will show triggers in the database
  
  insert into fact_act_est
     (date, product_code,customer_code,sold_quantity)
  values ("2030-09-01","Champ",9910223,123);
  
  select * from fact_act_est where customer_code = 9910223;
  
   insert into fact_forecast_monthly
     (date, product_code,customer_code,forecast_quantity)
  values ("2030-09-01","Champ",9910223,123);
  
   select * from fact_forecast_monthly where customer_code = 9910223;
   
   select * from gdb0041.fact_act_est
   where customer_code = 9910223;
   
   -- Temporary Tables & Forecast Accuracy Report
   
   --   with forecast_err_tale as(      we can use         create temporary table forecast_err_table
   
   -- Temporary tables are valid only for that session once you close the workbench then that table will be of no more use.
   -- CTE is valid until the scope of entire statement
   
 create temporary table forecast_err_table

 with forecast_err_tale as(
   select 
   s.customer_code,
   sum(s.sold_quantity) as total_sold_quantity,
   sum(s.forecast_quantity) as total_forecast_quantity,
   sum(forecast_quantity - sold_quantity) as net_err,
   sum((forecast_quantity - sold_quantity))*100/(forecast_quantity) as net_err_pct,
   sum(abs(forecast_quantity - sold_quantity)) as abs_err,
   sum(abs(forecast_quantity - sold_quantity))*100/(forecast_quantity) as abs_err_pct
   from gdb0041.fact_act_est s
   where fiscal_year = 2021
   group by customer_code)
   
   select 
		e.*,
        c.customer,
        c.market,
    if (abs_err_pct > 100,0, 100 - abs_err_pct) as forecast_accuracy
    from forecast_err_table
    join dim_customer c
    using(customer_code)
    order by  forecast_accuracy desc;             -- To customer with highest number of accuracy
    
 -- The supply chain business manager wants to see which customers’ forecast accuracy has dropped from 2020 to 2021. Provide a complete report with these columns: customer_code, customer_name, market, forecast_accuracy_2020, forecast_accuracy_2021  
   
drop table if exists forecast_accuracy_2021;
create temporary table forecast_accuracy_2021
with forecast_err_table as (
        select
                s.customer_code as customer_code,
                c.customer as customer_name,
                c.market as market,
                sum(s.sold_quantity) as total_sold_qty,
                sum(s.forecast_quantity) as total_forecast_qty,
                sum(s.forecast_quantity-s.sold_quantity) as net_error,
                round(sum(s.forecast_quantity-s.sold_quantity)*100/sum(s.forecast_quantity),1) as net_error_pct,
                sum(abs(s.forecast_quantity-s.sold_quantity)) as abs_error,
                round(sum(abs(s.forecast_quantity-sold_quantity))*100/sum(s.forecast_quantity),2) as abs_error_pct
        from fact_act_est s
        join dim_customer c
        on s.customer_code = c.customer_code
        where s.fiscal_year=2021
        group by customer_code
)
select 
        *,
    if (abs_error_pct > 100, 0, 100.0 - abs_error_pct) as forecast_accuracy
from 
	forecast_err_table
order by forecast_accuracy desc;

   
-- Get forecast accuracy of FY 2020 and store that also in a temporary table

drop table if exists forecast_accuracy_2020;
create temporary table forecast_accuracy_2020
with forecast_err_table as (
        select
                s.customer_code as customer_code,
                c.customer as customer_name,
                c.market as market,
                sum(s.sold_quantity) as total_sold_qty,
                sum(s.forecast_quantity) as total_forecast_qty,
                sum(s.forecast_quantity-s.sold_quantity) as net_error,
                round(sum(s.forecast_quantity-s.sold_quantity)*100/sum(s.forecast_quantity),1) as net_error_pct,
                sum(abs(s.forecast_quantity-s.sold_quantity)) as abs_error,
                round(sum(abs(s.forecast_quantity-sold_quantity))*100/sum(s.forecast_quantity),2) as abs_error_pct
        from fact_act_est s
        join dim_customer c
        on s.customer_code = c.customer_code
        where s.fiscal_year=2020
        group by customer_code
)
select 
        *,
    if (abs_error_pct > 100, 0, 100.0 - abs_error_pct) as forecast_accuracy
from 
	forecast_err_table
order by forecast_accuracy desc;

-- Join forecast accuracy tables for 2020 and 2021 using a customer_code

select 
	f_2020.customer_code,
	f_2020.customer_name,
	f_2020.market,
	f_2020.forecast_accuracy as forecast_acc_2020,
	f_2021.forecast_accuracy as forecast_acc_2021
from forecast_accuracy_2020 f_2020
join forecast_accuracy_2021 f_2021
on f_2020.customer_code = f_2021.customer_code 
where f_2021.forecast_accuracy < f_2020.forecast_accuracy
order by forecast_acc_2020 desc;

-- User Accounts and Privileges

show grants for 'Aashu';

-- Database Indexes: Overview
-- Main benefit of index is query can run faster.

show indexes in fact_act_est;

-- Database Indexes: Composite Index
-- when you have index on more than one column is called composite index
explain analyze
select * from fact_sales_monthly
where product_code = 'A0118150101'
and customer_code = 70002017
limit 5000000;

-- Database Indexes: Index Types

