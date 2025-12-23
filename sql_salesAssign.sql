create database superstore;
create table sales_store
(transaction_id	varchar(20),
customer_id	varchar(15),
customer_name varchar(30),
customer_age int,
gender varchar(15),
product_id	varchar(15),
product_name varchar(20),
product_category varchar(15),
quantiy	int,
prce float,
payment_mode varchar(15),	
purchase_date date,
time_of_purchase time,
status varchar(15));

select * from sales_store;

-- Create a duplicate table with same data to perform functions
create table sales like sales_store;
insert into sales
select * from sales_store;

-- convert the format of purchase_date coulumn according to mysql 
select * from sales;
select purchase_date from sales
where purchase_date is not null;

update sales set purchase_date = str_to_date(purchase_date, '%d-%m-%Y');

-- count the duplicate rows in a data
select transaction_id, count(*) from sales
group by transaction_id
having count(transaction_id) >1;

with cte as (
select *,
    row_number() over (partition by transaction_id order by transaction_id) as row_num
from  sales
)
select * from cte
where transaction_id in ('TXN855235','TXN342128','TXN240646','TXN981773');


select * 
from (
   select *,
	   row_number() over (
		   partition by transaction_id 
           order by transaction_id) 
       as row_num
from sales
) t
where row_num > 1;


-- treating the duplicate entries(data cleaning)
create table sales_data as select distinct * from sales;
select count(*) from sales_data;
truncate table sales;
insert into sales select * from sales_data;
drop table sales_data;

set sql_safe_updates = 0;

select* from sales;

-- (data cleaning) correcting column names
alter table sales
rename column quantiy to quantity;
alter table sales
rename column prce to price;
describe sales;


-- verify datatype of a data
alter table sales
modify transaction_id varchar(20),
modify customer_id varchar(15),
modify customer_name varchar(30),
modify gender varchar(15),
modify product_id	varchar(15),
modify product_name varchar(20),
modify product_category varchar(15),
modify price float,
modify payment_mode varchar(15),	
modify purchase_date date,
modify time_of_purchase time,
modify status varchar(15);

select * from sales;

-- (data cleaning) checking null values
select * from sales
where transaction_id is null
 or customer_id is null
 or customer_name is null
 or gender is null
 or product_id is null
 or product_name is null
 or product_category is null
 or price is null
 or payment_mode is null	
 or purchase_date is null
 or time_of_purchase is null
 or status is null;
 
 -- treating null values(data cleaning)
 select * from sales where customer_name = 'Ehsaan Ram';
 update sales set customer_id = 'CUST9494'
 where transaction_id = 'TXN977900';
 select * from sales where customer_name = 'Damini Raju';
  update sales set customer_id = 'CUST1401'
 where transaction_id = 'TXN985663';
 
 -- data cleaning on gender and payment_mode column
 select distinct gender from sales;
 update sales set gender = 'M'
 where gender = 'Male';
 update sales set gender = 'F'
 where gender = 'Female';
 select distinct payment_mode from sales;
 update sales set payment_mode = 'Credit Card'
 where payment_mode = 'CC';
 
select * from sales;

-- questions related to business problems
-- what are the top 5 most selling products by quantity?

select product_name, sum(quantity) as total_quantity_sold from sales
where status = 'delivered'
group by product_name
order by total_quantity_sold desc
limit 5;

-- which products are most frequently cancelled?

select product_name, count(*) as total_cancelled from sales
where status = 'cancelled'
group by product_name
order by total_cancelled desc
limit 5;

-- what time of the day has the highest number of purchases?
select
    case 
        when hour(time_of_purchase) between 0 and 5 then 'Night'
        when hour(time_of_purchase) between 6 and 11 then 'Morning'
        when hour(time_of_purchase) between 12 and 17 then 'Afternoon'
        when hour(time_of_purchase) between 18 and 23 then 'Evening'
	end as time_of_day,
    count(*) as total_orders
from sales
where time_of_purchase is not null
group by time_of_day
order by total_orders desc;

-- who are the top 5 highest spending customers?
select customer_name,
	   concat('₹', 
              format(sum(price*quantity), 0)
	   ) as total_spend
from sales
group by customer_name
order by sum(price*quantity) desc
limit 5;

-- which product categories generate the highest revenue?
select product_category, 
       concat('₹', 
              format(sum(price*quantity), 0)
	   ) as Revenue 
from sales
group by product_category
order by sum(price*quantity) desc;

-- what is the return/cancellation rate per product category?
select product_category,
	concat(
	    format(
            count(case when status = 'cancelled' then 1 end)*100.0/count(*), 
            3
		),
		' %'
	) as cancelled_percent
from sales
group by product_category
order by count(case when status = 'cancelled' then 1 end)*100.0/count(*) desc;
-- return
select product_category, 
    concat(
	    format(
            count(case when status = 'returned' then 1 end)*100.0/count(*), 
            3
		),
		' %'
	) as returned_percent
from sales
group by product_category
order by count(case when status = 'returned' then 1 end)*100.0/count(*) desc;

-- what is the most preferred payment mode?
select payment_mode, count(payment_mode) as total_count from sales
group by payment_mode
order by total_count desc;

-- how does age group affect purchasing behaviour?
select
    case
        when customer_age between 18 and 25 then '18-25'
        when customer_age between 26 and 35 then '26-35'
        when customer_age between 36 and 50 then '36-50'
        else '51+'
	end as customer_age,
    count(*) as total_purchase,
    concat(
		'₹ ',
	    format(sum(price*quantity), 0)
	) as total_purchase
from sales
group by case
        when customer_age between 18 and 25 then '18-25'
        when customer_age between 26 and 35 then '26-35'
        when customer_age between 36 and 50 then '36-50'
        else '51+'
	end
order by sum(price*quantity) desc;

-- what's the monthly sales trend?

select 
    -- year(purchase_date) as years,
    month(purchase_date) as months,
    concat(
        '₹ ',
        format(sum(price*quantity), '0') 
	) as total_sales,
    sum(quantity) as total_quantity
from sales
group by month(purchase_date)
order by months;
-- or
select
    date_format(purchase_date, '%Y-%m') as Month_Year,
    concat('₹ ',
        format(sum(price*quantity), 0) 
    ) as total_sales,
    sum(quantity) as total_quantity
from sales
group by date_format(purchase_date, '%Y-%m')
order by month_year;

-- are certain genders buying more specific product categories?
select gender, product_category, count(product_category) as total_purchase from sales
group by gender, product_category
order by gender desc;
-- or
select product_category,
       sum(case when gender = 'M' then 1 else 0 end) as Male,
       sum(case when gender = 'F' then 1 else 0 end) as Female
from sales
group by product_category
order by product_category;
    