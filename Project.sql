use bank_crm;

select * from bank_churn where CustomerId is null;

select extract(year from DateOfJoin) from customerinfo;

-- 1. Identify the top 5 customers with the highest Estimated Salary in the last quarter of the year:
-- Answer-
SELECT customerId, EstimatedSalary, year(DateOfJoin) AS transaction_year
FROM customerinfo
WHERE (year(DateOfJoin) = 2019 AND quarter(DateOfJoin) = 4)
   OR (year(DateOfJoin) = 2018 AND quarter(DateOfJoin) = 4)
   OR (year(DateOfJoin) = 2017 AND quarter(DateOfJoin) = 4)
   OR (year(DateOfJoin) = 2016 AND quarter(DateOfJoin) = 4)
ORDER BY EstimatedSalary DESC
LIMIT 5;


--- 2. Calculate the average number of products used by customers who have a credit card
---- Answer -
select customerId, avg(NumOfProducts) as avg_num_products
from bank_churn 
where HasCrCard = 1
group by customerId;

select * from customerinfo;


---- 3. Compare the average credit score of customers who have exited and those who remain
---- Answer - 
select Exited, avg(CreditScore) as avg_credit_score
from bank_churn 
where Exited = 1 
union all 
select Exited, avg(CreditScore) as avg_credit_score
from bank_churn
where Exited = 0;


----- 4. Which gender has a higher average estimated salary, and how does it relate to the number of active accounts? 
--- Answer -
select g.GenderCategory, round(avg(ci.EstimatedSalary),2) as avg_estimated_salary,
sum(case when  bc.IsActiveMember = 1 then 1 else 0 end) as active_members
from gender g 
join customerinfo ci on g.GenderID = ci.GenderID
join bank_churn bc on ci.CustomerId = bc.CustomerId
group by g.GenderCategory;

----- 5. Segment the customers based on their credit score and identify the segment with the highest exit rate
---- Answer -

with credit_score_segment as (
select case
when CreditScore <= 599 then 'Poor'
when CreditScore > 599 and CreditScore <= 700 then 'Low'
when CreditScore > 700 and CreditScore <= 749 then 'Fair'
when CreditScore > 749 and CreditScore <=799 then 'Good'
else 'Excellent'
end as Credit_Segment, Exited, CustomerId
from bank_churn
)
select Credit_Segment, sum( case when Exited = 1 then 1 else 0 end) as Total_exited_Cust,
count(CustomerId) as Total_customers, 
round(sum( case when Exited = 1 then 1 else 0 end)/count(*), 3) as Exit_rate
from credit_score_segment
group by Credit_Segment
order by Exit_rate desc limit 1;



---- 6. Find out which geographic region has the highest number of active customers with a tenure greater than 5 years
---- Answer -
 
select gl.GeographyLocation, sum(case when bc.IsActiveMember = 1 then 1 else 0 end) as Active_members,
bc.Tenure 
from geography gl 
join customerinfo ci on gl.GeographyID = ci.GeographyID
join bank_churn bc on ci.CustomerId = bc.CustomerId
where bc.Tenure > 5
Group By gl.GeographyLocation, bc.Tenure
order by Active_members desc limit 1;



----- 7. Examine the trend of customer joining over time and identify any seasonal patterns (yearly or monthly). 
----- Prepare the data through SQL and then visualize it.

----- Answer -
select extract(year from DateOfJoin) as Join_year,
count(*) as customer_count
from customerinfo
group by Join_year
order by Join_year;

-------- 8. write a query to find out the gender wise average income of male and 
----- female in each geography id. Also rank the gender according to the average value. 

---- Answer-

select round(avg(ci.EstimatedSalary),2) as Avg_income, ci.GeographyID,
gd.GenderCategory as Gender,
rank() over (order by round(avg(ci.EstimatedSalary),2) desc) as Gender_rank
from customerinfo ci 
left join gender gd on ci.GenderID = gd.GenderID
group by ci.GeographyID, gd.GenderCategory;

---------- 9. write a query to find out the average tenure of the people who have exited in each age bracket (18-30, 30-50, 50+)
--- Answer -

select case when ci.Age between 18 and 30 then '18-30'
when ci.Age between 31 and 50 then '31-50'
else '50+'
end as Age_bracket, 
avg(bc.Tenure) as average_tenure 
from customerinfo ci
join bank_churn bc on ci.CustomerId = bc.CustomerId
where bc.Exited = 1 
group by case when ci.Age between 18 and 30 then '18-30'
when ci.Age between 31 and 50 then '31-50'
else '50+'
end
order by case when ci.Age between 18 and 30 then '18-30'
when ci.Age between 31 and 50 then '31-50'
else '50+'
end asc;

------  10. Rank each bucket of credit score as per the number of customers who have churned the bank.
----- Answer - 

with churned_customers as (select case
when CreditScore <= 599 then 'Poor'
when CreditScore > 599 and CreditScore <= 700 then 'Low'
when CreditScore > 700 and CreditScore <= 749 then 'Fair'
when CreditScore > 749 and CreditScore <=799 then 'Good'
else 'Excellent'
end as Credit_category, count(*) as churnedcount
from bank_churn
where Exited = 1
group by case
when CreditScore <= 599 then 'Poor'
when CreditScore > 599 and CreditScore <= 700 then 'Low'
when CreditScore > 700 and CreditScore <= 749 then 'Fair'
when CreditScore > 749 and CreditScore <=799 then 'Good'
else 'Excellent'
end
), ranked_bucket as (select Credit_category,churnedcount,rank() over (order by churnedcount desc) as BucketRank 
from churned_customers)
 select Credit_category, churnedcount, BucketRank
 from ranked_bucket;
 
----- 11.  According to the age buckets find the number of customers who have a credit card. 
---- Also retrieve those buckets who have lesser than average number of credit cards per bucket.


with creditCrad as (
select case when ci.Age between 18 and 30 then '18-30'
when ci.Age between 31 and 50 then '31-50' else '50+'
end as Age_bucket, 
count(bc.HasCrCard) as CreditCardCount
from bank_churn bc
join customerinfo ci on bc.CustomerId = ci.CustomerId
where HasCrCard = 1
group by case when ci.Age between 18 and 30 then '18-30'
when ci.Age between 31 and 50 then '31-50' else '50+' end),
Avg_creditcards as (
select avg(CreditCardCount) as Avg_creditcard
from creditCrad)
select Age_bucket, CreditCardCount from creditCrad
cross join Avg_creditcards
where CreditCardCount<Avg_creditcard;
  
------ 12. Write the query to get the customer ids, their last name and whether they are active or not for 
----- the customers whose surname ends with “on”

select  bc.CustomerId, bc.IsActiveMember from bank_churn bc
inner join customerinfo ci on bc.CustomerID = ci.CustomerId
where ci.Surname like '%on';

---------- 13.  Without using “Join”, can we get the “ExitCategory” from ExitCustomers table to Bank_Churn table? If yes do this using SQL.

select bc.*, (select ec.ExitCategory from exitcustomer ec 
where ec.ExitID = bc.Exited) as ExitCategory
from bank_churn bc;

------- 14. As we can see that the “CustomerInfo” table has the CustomerID and Surname, now if we 
----- have to join it with a table where the primary key is also a combination of CustomerID and 
----- Surname, come up with a column where the format is “CustomerID_Surname”

select cast(CustomerId as char) as CustomerID from customerinfo;

select cast(CustomerId as char) as CustomerID from bank_churn;

select concat(ci.CustomerID,' ',ci.Surname) as CustomerID_Surname from customerinfo ci
join bank_churn bc on ci.CustomerID = bc.CustomerID;

----- 15. Rank the Locations as per the number of people who have churned the bank and average 
------ balance of the leavers.

select g.GeographyLocation, 
count(case when bc.Exited =1 then 1 end) as Churned_customers,
round(avg(bc.Balance),2) as avg_balance,
rank() over (order by count(case when bc.Exited =1 then 1 end) desc) as Ranking
from bank_churn bc 
join customerinfo ci on ci.CustomerId = bc.CustomerId
join geography g on ci.GeographyID=g.GeographyID
where bc.Exited =1
group by g.GeographyLocation
order by count(case when bc.Exited =1 then bc.CustomerId end) desc;

----- 16.How many different tables are given in the dataset, out of these tables which 
---- table only consist of categorical variables?


SELECT COUNT(*) AS total_tables
FROM information_schema.tables
WHERE table_schema = 'bank_crm';



