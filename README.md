![Olist_logo](Assets/logo_olist.svg)

# Olist Health & Beauty Category Analysis
Edmond Antonian, 2026.10
Tools used: T-SQL, Python

## 1. Business Background
### 1.1 Client Background

**Olist** is a Brazilian ecommerce company that offers a wide range of online retail tools. These include a marketplace, an ERP system, marketplace integration, credit and financial services, a point-of-sale (POS) system and shipping.

This analysis uses **Olist** order data from September 2016 to October 2018. For the financial year, I use August 2017 to July 2018, the most recent period with complete data.

In this period, the dataset covers about 70k unique customers and more than 2.5k sellers, spread across almost all of Brazil. Revenue between August 2017 and July 2018 reached R$9.9 million (Brazilian reals) and grew steadily year on year.

Health and Beauty was one of the biggest contributors to this growth. Its revenue rose by around  280%, from almost R$250k (Oct 2016 to Sep 2017) to R$935k (Oct 2017 to Sep 2018), alongside a sharp rise in the number of orders. Understand  ing what made the category successful, and how to repeat it, can help the whole business.

### 1.2 Purpose and Audience
This report is written for the Category Management team and the Head of Operations. It reviews the category's performance over the last complete year, covering:
- sales trends
- customers and their satisfaction
- delivery performance
- seller growth
- the main factors behind these results

## 2. Key Metrics

- **Sales**
  - *Revenue(Gross Merchendise Value):* total price of items sold, excluding delivery charges, since we don't know take value of platform.
  - *Orders:* number of orders placed
  - *Units:* number of items sold
  - *Average order value (AOV):* revenue divided by number of orders
  - *Category share:* Health and Beauty revenue as a percentage of total Olist revenue
- **Customers**
  - *Unique customers:* people who bought at least once
  - *Repeat purchase rate:* share of customers who ordered more than once
- **Logistics**
  - *Delivery time:* days from purchase to arrival at the customer
  - *Late-delivery rate:* share of orders that arrived after the estimated date
  - *Freight share:* delivery charge as a percentage of item price
- **Customer Satisfaction**
  - *Average review score:* from 1 (worst) to 5 (best)
  - *Low-score share:* percentage of reviews scoring 1 or 2
- **Sellers and Geography**
  - *Seller concentration:* share of revenue coming from the top sellers
  - *Revenue by state:* where the category sells best

## 3. Executive Summary

![hb_monthly_revenue.png](Assets/hbrevenue.png)


## 4. Database Structure and ERD

![ERD](Assets/DB_Schema.png)

The data is stored in SQL Server as linked tables. Each order connects to a customer, its items, payments and review. Each item connects to a product and a seller.

**Main tables and key columns**

| Table | What it holds | Key columns | N. of rows |
|---|---|---|---|
| orders | One row per order | `order_id`, `order_status`, purchase and delivery dates | 99441 |
| order_items | Each product within an order | `price`, `freight_value`, `product_id`, `seller_id` | 112650 |
| products | Product details | `product_category_name`, weight, size, photo count | 32951 |
| category_translation | Portuguese-to-English category names | `product_category_name_english` | 73 |
| customers | Where each customer lives | `customer_unique_id`, city, state | 99441 |
| sellers | Where each seller is based | `seller_id`, city, state | 3095 |
| payments | How each order was paid | `payment_type`, `payment_installments`, `payment_value` | 103886 |
| reviews | Customer ratings and comments | `review_score`, `review_creation_date` | 99224 |
| geolocation | Map coordinates for postcodes | `geolocation_zip_code_prefix`, lat, lng | 1000163 |

The two marketing tables (`marketing_qualified_leads` and `closed_deals`) describe how sellers were recruited. They are not relevant to this analysis, so they are not used.	

**Data preparation notes**

- Only delivered orders are included.
- Category names were translated into English using the translation table. Stray line-break characters were removed and underscores replaced with spaces.
- Revenue is the item price. Freight is analysed separately.
- Payments were compared with item price plus freight to check that revenue figures are reliable. [State result here.]
- Products with no category are excluded.

## 5. Insights Deep-Dive

### 5.1 Category Overview

![top10.png](Assets/top10.png)
- Health & Beauty vs other categories: revenue rank, order share, AOV comparison (bar chart).

### 5.2 Sales Trend
![hb_aov_and_orders](Assets/hb_aov_and_orders.png)
- Monthly revenue, orders and AOV .
- Seasonality, check brazilian marketing days, like Black Friday.
- MoM growth vs AOV growth.

### 5.3 Product Performance

- Top and bottom products by revenue (using `product_id` or product attributes such as weight and photo count, since Olist has no sub-category).
- Price distribution and price-band analysis.
- Pareto (80/20) of products.

### 5.4 Customer Behaviour

- New vs repeat customers.
- Orders per customer and basket size.
- Payment methods and installments.

### 5.5 Regional Results

- Revenue and orders by state (map or bar chart).
- Freight cost and delivery time by state.
- Concentration in São Paulo vs underserved regions.

### 5.6 Seller Analysis

- Number of active sellers, top-seller revenue share, seller geography.
- Seller performance vs review score.

### 5.7 Delivery and Customer Satisfaction

- Review score distribution.
- Delivery time vs review score.
- Late deliveries and cancellation rate.
- Common complaint themes in review comments, if you use the text.

## 6. Recommendations

- **Sales:** 
- **Products:** 
- **Customers:** 
- **Regions:** 
- **Sellers and operations:** 

## 7. Limitations and Next Steps

- Data is a sample covering about two years, with no cost or margin data.
- Suggested follow-ups

## 8. Appendix

- SQL or Python code
