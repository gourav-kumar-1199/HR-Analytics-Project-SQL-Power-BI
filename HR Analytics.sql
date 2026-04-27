select * from hr;
use hr;

set birthdate = replace(birthdate,'/','-');

update hr
set birthdate = case
when birthdate like '%-%' then date_format(str_to_date(birthdate,'%m-%d-%Y'),'%Y-%m-%d')
else null
end;

update hr set termdate = replace(termdate,'UTC','') where termdate like '%UTC';

alter table hr modify termdate date;

update hr
 set hire_date = replace(hire_date,"/","-");

UPDATE hr 
SET 
    hire_date = CASE
        WHEN
            hire_date LIKE '%-%'
        THEN
            DATE_FORMAT(STR_TO_DATE(hire_date, '%m-%d-%Y'),
                    '%Y-%m-%d')
        ELSE NULL
    END;

alter table hr rename column ï»¿id to emp_id;

describe hr;

alter table hr modify column birthdate date;
alter table hr modify column hire_date date;

update hr set termdate = Null where termdate = "";

-- HR ANALYTICS USING SQL

-- ***************** QUESTION: Overall attiration rate ********************

-- calculate total employees
SELECT 
    COUNT(DISTINCT (emp_id)) AS Count_of_Emp_Present
FROM
    hr where termdate is null;
    
-- Connt how many employees have left

SELECT 
    COUNT(termdate) as Count_Emp_Left
FROM
    hr
WHERE
    termdate IS NOT NULL;

-- Compute overall attrition rate.

SELECT 
    COUNT(*) AS total_emp,
    SUM(CASE
        WHEN termdate IS NOT NULL THEN 1
        ELSE 0
    END) AS total_attiration,
    ROUND(SUM(CASE
                WHEN termdate IS NOT NULL THEN 1
                ELSE 0
            END) / COUNT(*) * 100,
            2) AS Attiration_percentage
FROM
    hr;

-- ***************** QUESTION: Department wise attiration rate *******************

-- Calculate the attiration of each department

SELECT 
    department,
    COUNT(emp_id) AS current_emp,
    SUM(CASE
        WHEN termdate IS NOT NULL THEN 1
        ELSE 0
    END) AS employee_left,
    ROUND(SUM(CASE
                WHEN termdate IS NOT NULL THEN 1
                ELSE 0
            END) / COUNT(emp_id) * 100,
            2) AS attiration_rate_Percentage
FROM
    hr
GROUP BY department
ORDER BY attiration_rate_percentage DESC;

-- Rank department base on attiration

select department, 
COUNT(emp_id) AS current_emp,
    SUM(CASE
        WHEN termdate IS NOT NULL THEN 1
        ELSE 0
    END) AS employee_left,
    ROUND(SUM(CASE
                WHEN termdate IS NOT NULL THEN 1
                ELSE 0
            END) / COUNT(emp_id) * 100,
            2) AS ATR, dense_rank()
            over(order by ROUND(SUM(CASE
                WHEN termdate IS NOT NULL THEN 1
                ELSE 0
            END) / COUNT(emp_id) * 100,
            2)  desc) as Department_Churn_Rank from hr group by department;


-- ****************** Qestion Average employee tenure **************************
 
-- Calculate average tenure of employee : Active & Terminated
use hr;
SELECT 
    ROUND(AVG(CASE
                WHEN termdate IS NULL THEN TIMESTAMPDIFF(DAY, hire_date, CURDATE())
            END) / 365,
            2) AS avg_tenure_active_year,
    ROUND(AVG(CASE
                WHEN termdate IS NOT NULL THEN TIMESTAMPDIFF(DAY, hire_date, termdate)
            END) / 365,
            2) AS avg_tenure_terminated_year
FROM
    hr;
    
-- Comapre tenure by department

  SELECT 
    department,
    ROUND(AVG(TIMESTAMPDIFF(YEAR,
                hire_date,
                CASE
                    WHEN termdate IS NULL THEN CURDATE()
                    ELSE termdate
                END)),
            2) AS avg_tenure_by_year
FROM
    hr
GROUP BY department;

-- WORKFORCE DIVERSITY ANALYSIS

-- Calculate gender distribution percentage.

SELECT 
    gender,
    COUNT(*) AS Total_Employee,
    (COUNT(*) * 100) / (SELECT 
            COUNT(gender)
        FROM
            hr) as gender_percentage
FROM
    hr
GROUP BY gender;


-- Calculate race distribution percentage.

SELECT 
    race,
    COUNT(race) AS total_race_count,
    (COUNT(*) * 100) / (SELECT 
            COUNT(race)
        FROM
            hr) AS race_percentage
FROM
    hr
GROUP BY race
order by race_percentage desc;


-- Show diversity breakdown department-wise.

select department, gender, count(*)*100 / sum(count(*)) over( partition by department) as dept from hr group by department, gender;

-- AGE DEMOGRAPHIC ANALYSIS

-- Calculate employee age using birthdate.

SELECT 
    *
FROM
    (SELECT 
        emp_id,
            first_name,
            last_name,
            TIMESTAMPDIFF(YEAR, birthdate, CURDATE()) AS emp_age
    FROM
        hr) t;
        
        alter table hr add column age int after gender;
        update hr set age = TIMESTAMPDIFF(YEAR, birthdate, CURDATE()) ;
        
        
/* Categorize into age groups:
18–25
26–35
36–45
46–60
60+ */ 

alter table hr add column age_category varchar(20) after gender;
select * from hr;
 UPDATE hr 
SET 
    age_category = CASE
        WHEN age BETWEEN 18 AND 25 THEN '18-25'
        WHEN age BETWEEN 26 AND 35 THEN '26-35'
        WHEN age BETWEEN 36 AND 45 THEN '36-45'
        WHEN age BETWEEN 46 AND 60 THEN '46-60'
        ELSE '60+'
    END;
    
    
-- Identify dominant age group per department.

WITH age_count AS (
    SELECT 
        department,
        age_category,
        COUNT(*) AS total_employees
    FROM hr
    GROUP BY department, age_category
)

SELECT 
    department,
   age_category,
    total_employees
FROM (
    SELECT *,
           RANK() OVER (PARTITION BY department ORDER BY total_employees DESC) AS rnk
    FROM age_count
) ranked
WHERE rnk = 1;

-- Hiring Trend Analysis
-- calculate number of hires per year

SELECT 
    YEAR(hire_date) AS Year, COUNT(*) as numnber_of_hirings
FROM
    hr
GROUP BY YEAR(hire_date) order by year(hire_date) ;

-- Identify year with highest hiring.

with year as (
SELECT 
    YEAR(hire_date) AS Year, COUNT(hire_date) AS total_hire
FROM
    hr
GROUP BY YEAR(hire_date)) SELECT 
    year, total_hire
FROM
    year
WHERE
    total_hire = (SELECT 
            MAX(total_hire)
        FROM
            year);
            
-- Compute Year-over-Year hiring growth rate.

with previous_year as (
SELECT 
    YEAR(hire_date) AS Year, COUNT(*) AS Current_year_hire
FROM
    hr
GROUP BY YEAR(hire_date)) select year, current_year_hire, lag(current_year_hire) over( order by year) as previous_year, round((current_year_hire - lag(current_year_hire) over( order by year))/(lag(current_year_hire) over( order by year))*100,2) as hiring_growth_rate  from previous_year;


-- *************** HEAD COUNT ANALYSIS BY LOCATION ***********************

-- Calculate total employees by state.

SELECT 
    location_state, COUNT(emp_id)
FROM
    hr
GROUP BY location_state;

-- Identify top 3 states with highest workforce.

SELECT 
    location_state, COUNT(*)
FROM
    hr
GROUP BY location_state
ORDER BY COUNT(*) DESC
LIMIT 3;

-- Compute percentage workforce distribution by state.

SELECT 
    location_state,
    COUNT(*) AS total_employee,
    ROUND((COUNT(*) * 100) / (SELECT 
                    COUNT(*)
                FROM
                    hr),
            2) AS percent_employee_distribution
FROM
    hr
GROUP BY location_state
ORDER BY percent_employee_distribution;


-- 8 Job Title Distribution & Ranking

-- Count employees per jobtitle.

SELECT 
    jobtitle, COUNT(emp_id) AS Number_of_emp_per_job_title
FROM
    hr
GROUP BY jobtitle
ORDER BY count(emp_id) DESC;

-- Rank top 5 most common job roles.

SELECT 
    jobtitle, COUNT(jobtitle) AS Count_of_Emp
FROM
    hr
GROUP BY jobtitle
ORDER BY COUNT(jobtitle) DESC
LIMIT 5;

-- Identify roles with highest attrition.

SELECT 
    jobtitle, COUNT(termdate) AS terminated_emp
FROM
    hr
WHERE
    termdate IS NOT NULL
GROUP BY jobtitle
ORDER BY terminated_emp DESC;

