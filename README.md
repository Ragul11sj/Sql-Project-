# 🍔 Food Delivery Platform — SQL Database Project

A production-grade relational database for a food delivery platform (think Swiggy / Zomato clone), built entirely in **MySQL**. Includes schema design, seed data, views, stored procedures, triggers, and 20+ analytical queries.

---

## 📁 Project Structure

```
food-delivery-db/
├── 00_run_all.sql               ← Master script (run this first)
├── schema/
│   └── 01_schema.sql            ← All table definitions + indexes
├── data/
│   └── 02_seed_data.sql         ← Sample data (restaurants, orders, etc.)
├── views/
│   └── 03_views.sql             ← 6 analytical views
├── procedures/
│   └── 04_procedures.sql        ← 5 stored procedures
├── triggers/
│   └── 05_triggers.sql          ← 7 automation triggers
└── queries/
    └── 06_queries.sql           ← 20+ analytical & operational queries
```

---

## 🗃️ Database Schema (13 Tables)

| Table | Description |
|---|---|
| `users` | Customers, riders, and admins |
| `addresses` | Delivery addresses per user |
| `restaurants` | Restaurant profiles and settings |
| `categories` | Food categories (Biryani, Pizza, etc.) |
| `menu_items` | Items with pricing and availability |
| `riders` | Delivery rider profiles and live location |
| `coupons` | Discount coupons with usage rules |
| `orders` | Order lifecycle with financials |
| `order_items` | Line items per order |
| `order_status_history` | Full audit trail of status changes |
| `reviews` | Food and delivery ratings |
| `payments` | Payment records and gateway info |
| `notifications` | In-app notifications per user |

---

## 🔍 Views (03_views.sql)

| View | Purpose |
|---|---|
| `vw_menu_with_price` | Menu with effective discounted price |
| `vw_order_summary` | Full order details with all joins |
| `vw_restaurant_performance` | Revenue, ratings, delivery success rate |
| `vw_rider_leaderboard` | Rider stats and earnings |
| `vw_customer_history` | Spend and order history per customer |
| `vw_top_menu_items` | Best-selling items with revenue |

---

## ⚙️ Stored Procedures (04_procedures.sql)

| Procedure | Purpose |
|---|---|
| `sp_place_order` | Place order with coupon validation & pricing |
| `sp_update_order_status` | Safe status transitions with validation |
| `sp_assign_rider` | Nearest available rider assignment |
| `sp_monthly_revenue` | Monthly revenue report by restaurant |
| `sp_search_restaurants` | Search by city, cuisine, rating |

---

## ⚡ Triggers (05_triggers.sql)

| Trigger | Event | Purpose |
|---|---|---|
| `trg_update_restaurant_rating` | AFTER INSERT on reviews | Auto-recalculate restaurant rating |
| `trg_update_rider_stats` | AFTER INSERT on reviews | Auto-update rider rating & deliveries |
| `trg_free_rider_on_delivery` | AFTER UPDATE on orders | Mark rider available after delivery |
| `trg_notify_on_status_change` | AFTER UPDATE on orders | Auto-create notifications |
| `trg_validate_review` | BEFORE INSERT on reviews | Block reviews for undelivered orders |
| `trg_single_default_address` | BEFORE INSERT on addresses | Ensure one default address per user |
| `trg_create_payment_record` | AFTER INSERT on orders | Auto-create payment record |

---

## 📊 Query Highlights (06_queries.sql)

**Business Analytics**
- Revenue breakdown by restaurant
- Daily order trends (last 30 days)
- Peak ordering hours
- Revenue by payment method
- Coupon effectiveness analysis

**Customer Insights**
- Top customers by spend
- Retention segmentation (one-time vs loyal)
- Churn risk: customers inactive 30+ days

**Menu Analytics**
- Best-selling items
- Veg vs non-veg split
- Dead-stock (items never ordered)

**Delivery Performance**
- Rider performance with avg delivery time
- Late deliveries report
- Cancellation rate per restaurant

**Advanced SQL (Window Functions + CTEs)**
- Running revenue totals using `SUM() OVER`
- Customer rank by city using `RANK() OVER PARTITION BY`
- Month-over-month growth with `LAG()`
- Top item per restaurant using CTE + RANK

---

## 🚀 Setup Instructions

### Prerequisites
- MySQL 8.0+ (for window functions & CTEs)
- MySQL Workbench / DBeaver / CLI

### Run everything at once
```bash
mysql -u root -p < 00_run_all.sql
```

### Or run step by step
```bash
mysql -u root -p < schema/01_schema.sql
mysql -u root -p < data/02_seed_data.sql
mysql -u root -p < views/03_views.sql
mysql -u root -p < procedures/04_procedures.sql
mysql -u root -p < triggers/05_triggers.sql
```

### Try a stored procedure
```sql
USE food_delivery_db;

-- Place an order
CALL sp_place_order(1, 1, 1, 'WELCOME50', 'upi', 'No onions please', @oid, @msg);
SELECT @oid AS order_id, @msg AS message;

-- Search restaurants in Bangalore
CALL sp_search_restaurants('Bangalore', NULL, 3.5);

-- Monthly revenue report
CALL sp_monthly_revenue(2024, 11);
```

### Try a view
```sql
SELECT * FROM vw_restaurant_performance;
SELECT * FROM vw_rider_leaderboard ORDER BY avg_delivery_rating DESC;
SELECT * FROM vw_top_menu_items ORDER BY total_qty_sold DESC LIMIT 5;
```

---

## 🛠️ Tech Stack

- **Database**: MySQL 8.0+
- **Features used**: Foreign Keys, Indexes, Views, Stored Procedures, Triggers, CTEs, Window Functions, Transactions, ENUM types, CHECK constraints

---

## 📌 Key Design Decisions

- **Audit trail**: Every status change is logged in `order_status_history`
- **Soft deletes**: Users and restaurants use `is_active` flags instead of hard deletes
- **Normalized pricing**: Order items store price at time of purchase to handle future price changes
- **Geolocation**: `latitude` / `longitude` stored on restaurants and riders for proximity queries
- **Trigger-driven automation**: Rating updates, notifications, and rider availability handled automatically

---

## 👨‍💻 Author

Built as a portfolio SQL project demonstrating real-world database design, business logic, and analytics.

---

## 📄 License

MIT License — free to use, modify, and share.
