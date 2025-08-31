![Featured-Apple-Sales-Statistics](https://github.com/user-attachments/assets/d0a02625-8db1-4737-bf61-c54ca0490314)

## 📌 Project Overview
This project analyzes **1M+ Apple sales transactions** across multiple tables (sales, products, categories, stores, warranty) to generate **business insights**.  
The analysis is fully SQL-driven and demonstrates complex querying, performance optimization, and reporting techniques.

## 🗂️ Dataset
The project uses 5 relational tables:
- **sales.csv** – transaction details (sale_id, product_id, store_id, date, quantity, revenue)
- **products.csv** – product info (product_id, category_id, price, launch_date)
- **category.csv** – product categories
- **warranty.csv** – warranty claims data
- **stores.csv** – store information

  ## 🛠️ Key SQL Techniques Used
- Joins (`INNER`, `LEFT`, `RIGHT`)
- Aggregations (`SUM`, `AVG`, `COUNT`)
- Window functions (`ROW_NUMBER`, `RANK`, `LAG`)
- CTEs & Subqueries
- Index optimization for performance
- Date functions (Year-Month analysis, warranty periods, growth trends)

  ## 📊 Business Insights Generated
✔️ Monthly & yearly sales trends  
✔️ Top-selling and least-selling products  
✔️ Store performance by region  
✔️ Warranty claim risk analysis   
✔️ YoY growth and running totals  
✔️ Customer purchase patterns

## 🗺️ Database ERD
The project schema is represented by the ERD below:

<img width="907" height="623" alt="model view" src="https://github.com/user-attachments/assets/52a7b6f3-c35a-4da3-8426-f5d4c7a358a0" />

## Optimizing Querries

'''sql
EXPLAIN ANALYZE
SELECT * FROM sales
WHERE store_id = 'ST-31';

-- “Optimized query performance by creating appropriate indexes, reducing execution time from 0.297s to 0.172s.”

CREATE INDEX sales_store_id ON sales(store_id);
CREATE INDEX sales_sale_date ON sales(sale_date);
CREATE INDEX sales_product_id ON sales(product_id);
'''



