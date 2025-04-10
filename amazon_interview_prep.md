# Amazon Data Analyst Interview Preparation Guide

## Table of Contents
1. [Common SQL Questions](#common-sql-questions)
2. [Python Interview Problems](#python-interview-problems)
3. [Case Study Examples](#case-study-examples)
4. [Behavioral Framework](#behavioral-framework)
5. [Amazon Leadership Principles](#amazon-leadership-principles)
6. [Interview Tips](#interview-tips)

---

## Common SQL Questions

### Question 1: Second Highest Salary
**Problem:** Find the second highest salary in the employees table.

**Difficulty:** Easy-Medium

**Solution:**
```sql
-- Approach 1: Using OFFSET
SELECT DISTINCT salary
FROM employees
ORDER BY salary DESC
LIMIT 1 OFFSET 1;

-- Approach 2: Using subquery and MAX
SELECT MAX(salary) as second_highest_salary
FROM employees
WHERE salary < (SELECT MAX(salary) FROM employees);

-- Approach 3: Using DENSE_RANK
WITH ranked_salaries AS (
    SELECT salary, DENSE_RANK() OVER (ORDER BY salary DESC) as rank
    FROM employees
)
SELECT salary
FROM ranked_salaries
WHERE rank = 2;
```

**Follow-up:** Return NULL if there's no second highest salary.

**Key Concepts:** Window functions, ranking, handling edge cases

---

### Question 2: Customer with Multiple Purchases
**Problem:** Find customers who purchased both Product A and Product B.

**Difficulty:** Easy-Medium

**Solution:**
```sql
-- Approach 1: Using HAVING with COUNT(DISTINCT)
SELECT customer_id
FROM orders
WHERE product_id IN (1, 2)
GROUP BY customer_id
HAVING COUNT(DISTINCT product_id) = 2;

-- Approach 2: Using JOINs
SELECT DISTINCT o1.customer_id
FROM orders o1
INNER JOIN orders o2 ON o1.customer_id = o2.customer_id
WHERE o1.product_id = 1 AND o2.product_id = 2;

-- Approach 3: Using subqueries
SELECT customer_id
FROM orders
WHERE product_id = 1
INTERSECT
SELECT customer_id
FROM orders
WHERE product_id = 2;
```

**Follow-up:** What if we need to return customer details and purchase dates?

**Key Concepts:** JOIN, HAVING, set operations, subqueries

---

### Question 3: Running Total
**Problem:** Calculate cumulative sales for each date, ordered by date.

**Difficulty:** Medium

**Solution:**
```sql
SELECT 
    sale_date,
    daily_sales,
    SUM(daily_sales) OVER (ORDER BY sale_date) as running_total,
    SUM(daily_sales) OVER (ORDER BY sale_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) as moving_avg_3day
FROM daily_sales_table
ORDER BY sale_date;
```

**Key Concepts:** Window functions, frame specifications, ORDER BY

---

### Question 4: Top N Per Group
**Problem:** Find the top 3 customers by spending in each country.

**Difficulty:** Medium

**Solution:**
```sql
WITH ranked_customers AS (
    SELECT 
        country,
        customer_id,
        total_spent,
        RANK() OVER (PARTITION BY country ORDER BY total_spent DESC) as rank
    FROM (
        SELECT 
            c.country,
            c.customer_id,
            SUM(o.order_amount) as total_spent
        FROM customers c
        JOIN orders o ON c.customer_id = o.customer_id
        GROUP BY c.country, c.customer_id
    ) customer_spending
)
SELECT country, customer_id, total_spent
FROM ranked_customers
WHERE rank <= 3
ORDER BY country, rank;
```

**Key Concepts:** Window functions, CTEs, ranking, nested queries

---

### Question 5: Date Range Queries
**Problem:** Find all orders within the last 30 days and their customer details.

**Difficulty:** Easy

**Solution:**
```sql
SELECT 
    o.order_id,
    c.customer_name,
    o.order_date,
    o.order_amount,
    DATEDIFF(DAY, o.order_date, CURRENT_DATE) as days_ago
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_date >= DATEADD(DAY, -30, CURRENT_DATE)
ORDER BY o.order_date DESC;

-- Alternative: Using BETWEEN
WHERE o.order_date BETWEEN DATEADD(DAY, -30, CURRENT_DATE) AND CURRENT_DATE
```

**Key Concepts:** Date functions, WHERE clauses, JOINs

---

### Question 6: Duplicate Detection
**Problem:** Find customers with duplicate orders (same product, same date, same amount).

**Difficulty:** Medium

**Solution:**
```sql
WITH order_duplicates AS (
    SELECT 
        customer_id,
        product_id,
        order_date,
        order_amount,
        COUNT(*) as duplicate_count,
        ROW_NUMBER() OVER (PARTITION BY customer_id, product_id, order_date, order_amount ORDER BY order_id) as row_num
    FROM orders
    GROUP BY customer_id, product_id, order_date, order_amount
    HAVING COUNT(*) > 1
)
SELECT *
FROM order_duplicates
WHERE row_num <= duplicate_count;
```

**Key Concepts:** Window functions, GROUP BY with HAVING, duplicate patterns

---

### Question 7: Cumulative Distribution
**Problem:** Calculate percentile rank for each customer by spending.

**Difficulty:** Medium-Hard

**Solution:**
```sql
SELECT 
    customer_id,
    total_spent,
    PERCENT_RANK() OVER (ORDER BY total_spent) as percentile_rank,
    CUME_DIST() OVER (ORDER BY total_spent) as cumulative_distribution,
    NTILE(100) OVER (ORDER BY total_spent) as percentile_bucket
FROM (
    SELECT customer_id, SUM(order_amount) as total_spent
    FROM orders
    GROUP BY customer_id
) customer_totals;
```

**Key Concepts:** Advanced window functions, distribution analysis

---

### Question 8: Complex JOIN with Multiple Conditions
**Problem:** Find customers who purchased in multiple categories in the same month.

**Difficulty:** Hard

**Solution:**
```sql
WITH monthly_categories AS (
    SELECT 
        o.customer_id,
        YEAR(o.order_date) as year,
        MONTH(o.order_date) as month,
        COUNT(DISTINCT p.category) as num_categories
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    JOIN products p ON od.product_id = p.product_id
    GROUP BY o.customer_id, YEAR(o.order_date), MONTH(o.order_date)
    HAVING COUNT(DISTINCT p.category) > 1
)
SELECT *
FROM monthly_categories;
```

**Key Concepts:** Multiple JOINs, GROUP BY, HAVING, CTEs

---

## Python Interview Problems

### Problem 1: Data Cleaning Challenge
**Problem:** Clean customer dataset with missing values, duplicates, and format issues.

**Solution:**
```python
import pandas as pd
import numpy as np

def clean_customer_data(df):
    # Remove duplicates
    df = df.drop_duplicates(subset=['customer_id'])
    
    # Handle missing values
    df['email'] = df['email'].fillna('unknown@example.com')
    df['phone'] = df['phone'].fillna('')
    df['last_purchase_date'] = df['last_purchase_date'].fillna(pd.Timestamp('2020-01-01'))
    
    # Standardize formats
    df['customer_name'] = df['customer_name'].str.strip().str.title()
    df['country'] = df['country'].str.upper()
    
    # Remove invalid records
    df = df[df['email'].str.contains('@', na=False)]
    df = df[df['age'] > 18]
    
    return df
```

---

### Problem 2: Cohort Analysis
**Problem:** Calculate month-over-month retention cohorts.

**Solution:**
```python
def cohort_analysis(df):
    # Create cohort data
    df['cohort_month'] = df.groupby('customer_id')['order_date'].transform('min').dt.to_period('M')
    df['order_month'] = df['order_date'].dt.to_period('M')
    
    # Create cohort table
    cohorts = df.groupby(['cohort_month', 'order_month'])['customer_id'].nunique().reset_index()
    cohort_pivot = cohorts.pivot(index='cohort_month', columns='order_month', values='customer_id')
    
    # Calculate cohort size and retention rates
    cohort_sizes = cohort_pivot.iloc[:, 0]
    cohort_retention = cohort_pivot.divide(cohort_sizes, axis=0)
    
    return cohort_retention
```

---

### Problem 3: Feature Engineering
**Problem:** Create useful features from transaction data for predictive modeling.

**Solution:**
```python
def engineer_features(df):
    df['order_date'] = pd.to_datetime(df['order_date'])
    
    # Time-based features
    df['days_since_order'] = (pd.Timestamp.now() - df['order_date']).dt.days
    df['order_month'] = df['order_date'].dt.month
    df['order_day_of_week'] = df['order_date'].dt.day_name()
    
    # Aggregated features (per customer)
    customer_agg = df.groupby('customer_id').agg({
        'order_amount': ['sum', 'mean', 'count'],
        'order_date': ['min', 'max']
    }).reset_index()
    
    customer_agg.columns = ['customer_id', 'total_spent', 'avg_order_value', 
                            'num_orders', 'first_order_date', 'last_order_date']
    
    # Calculate derived features
    customer_agg['customer_lifetime_days'] = (customer_agg['last_order_date'] - 
                                              customer_agg['first_order_date']).dt.days
    customer_agg['orders_per_month'] = (customer_agg['num_orders'] / 
                                        (customer_agg['customer_lifetime_days'] / 30 + 1))
    
    return customer_agg
```

---

## Case Study Examples

### Case Study: E-commerce Customer Analysis
**Scenario:** You work at an online retailer. Management wants to understand customer behavior to improve retention.

**Questions to Answer:**
1. What is the average customer lifetime value?
2. Which customer segments are most valuable?
3. What is the churn rate month-over-month?
4. What are the top drivers of repeat purchases?

**Solution Approach:**
1. **SQL:** Calculate CLV, segment customers, identify cohorts
2. **Python:** Statistical analysis, visualization, trend identification
3. **Tableau:** Create dashboard with KPI tracking

**Key Metrics:**
- Customer Lifetime Value (CLV)
- Repeat Purchase Rate
- Churn Rate
- Customer Acquisition Cost (CAC)
- Return on Ad Spend (ROAS)

---

## Behavioral Framework: STAR Method

### What is STAR?
- **S**ituation: Set the context
- **T**ask: Describe your responsibility
- **A**ction: Explain what you did
- **R**esult: Share the outcome with metrics

### Example Answer

**Question:** "Tell me about a time you had to present complex data to a non-technical audience."

**STAR Answer:**
- **Situation:** At my previous role at HTC Global Services, I needed to explain data quality issues to finance stakeholders.
- **Task:** The team had identified 40% of reconciliation errors came from data inconsistencies. I needed to present the findings clearly.
- **Action:** I created a visual dashboard showing error types, root causes, and impact on revenue. I practiced explaining technical concepts in business terms.
- **Result:** Management approved a $50K budget for data governance tools. We reduced errors by 25% in the first quarter.

---

## Amazon Leadership Principles

### 1. **Customer Obsession**
- Think about customer needs in data analysis
- Example: "I analyzed customer churn patterns to identify at-risk customers before they leave"

### 2. **Ownership**
- Take full responsibility for projects end-to-end
- Example: "I owned the entire data pipeline from source to dashboard"

### 3. **Invent and Simplify**
- Create elegant, efficient solutions
- Example: "I automated a process that saved 10 hours per week of manual work"

### 4. **Are Right, A Lot**
- Use data to make good decisions
- Example: "I validated my analysis with multiple methods to ensure accuracy"

### 5. **Learn and Be Curious**
- Continuous skill development
- Example: "I completed advanced SQL training to improve query optimization"

### 6. **Hire and Develop the Best**
- Help others succeed
- Example: "I mentored a junior analyst on statistical testing methodology"

---

## Interview Tips

### Technical Interview Tips
1. **Think out loud** - Explain your approach before coding
2. **Ask clarifying questions** - Confirm assumptions
3. **Start simple, optimize later** - Get a working solution first
4. **Test edge cases** - NULLs, empty sets, duplicates
5. **Explain trade-offs** - SQL vs Python, time vs space complexity
6. **Optimize wisely** - Only optimize after understanding requirements

### SQL Interview Tips
- Write clear, readable queries with aliases
- Use CTEs for complex logic
- Test with LIMIT before running full queries
- Explain execution plan considerations
- Consider performance of large datasets

### Python Interview Tips
- Import necessary libraries at the start
- Use meaningful variable names
- Add comments for complex logic
- Test with sample data first
- Discuss Pandas vs pure Python approaches

### Behavioral Interview Tips
- Use the STAR framework consistently
- Include specific metrics and outcomes
- Show customer/business impact
- Mention how you handled challenges
- Demonstrate learning from mistakes
- Be honest about limitations

### Dashboard/Visualization Tips
- Lead with insights, not data
- Use appropriate chart types
- Include clear labels and legends
- Design for the audience
- Focus on actionable findings

---

## Common Mistakes to Avoid

1. **SQL:** Forgetting to handle NULLs properly
2. **Python:** Not validating data assumptions
3. **Interviews:** Not asking clarifying questions
4. **Case Studies:** Proposing solutions without understanding the problem
5. **Behavioral:** Giving generic answers without specific examples
6. **Technical:** Jumping to code without explaining approach

---

## Practice Resources

### SQL Practice
- LeetCode SQL problems
- HackerRank SQL challenges
- Mode Analytics SQL Tutorial

### Python Practice
- DataCamp
- Kaggle datasets
- Real-world practice projects

### Mock Interviews
- Practice with peers
- Record and review
- Time yourself
- Get feedback

---

## Day-by-Day Interview Prep Schedule (5 Days)

**Day 1: SQL Review**
- Solve 5-10 LeetCode SQL problems
- Review window functions and CTEs

**Day 2: Python Review**
- Solve 3-5 Python data problems
- Practice Pandas operations

**Day 3: Case Studies**
- Work through 1-2 case studies
- Time yourself

**Day 4: Behavioral Prep**
- Prepare 5-10 STAR stories
- Practice Amazon Leadership Principles

**Day 5: Mock Interview**
- Simulate full interview (60-90 min)
- Review performance
- Identify weak areas

---

## Final Checklist Before Interview

- [ ] Practiced SQL optimization questions
- [ ] Solved Python coding challenges
- [ ] Prepared 5+ STAR stories
- [ ] Reviewed Amazon Leadership Principles
- [ ] Practiced 1-2 case studies
- [ ] Tested technical setup (video, audio)
- [ ] Dressed professionally
- [ ] Arrived 10 minutes early
- [ ] Brought pen and paper
- [ ] Got good sleep night before

Good luck! 🎯
