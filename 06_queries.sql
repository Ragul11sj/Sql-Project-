-- ============================================================
--  FOOD DELIVERY PLATFORM DATABASE
--  File: 06_queries.sql
--  Description: Analytical & operational SQL queries
-- ============================================================

USE food_delivery_db;

-- ══════════════════════════════════════════
--  SECTION A: BUSINESS ANALYTICS
-- ══════════════════════════════════════════

-- A1. Total revenue breakdown by restaurant
SELECT
    r.name                          AS restaurant,
    COUNT(o.order_id)               AS orders,
    ROUND(SUM(o.subtotal), 2)       AS gross_sales,
    ROUND(SUM(o.discount_amt), 2)   AS discounts_given,
    ROUND(SUM(o.delivery_fee), 2)   AS delivery_fees,
    ROUND(SUM(o.tax_amt), 2)        AS taxes,
    ROUND(SUM(o.total_amt), 2)      AS net_revenue
FROM orders o
JOIN restaurants r ON r.restaurant_id = o.restaurant_id
WHERE o.status = 'delivered'
GROUP BY r.restaurant_id, r.name
ORDER BY net_revenue DESC;

-- A2. Daily order trends (last 30 days)
SELECT
    DATE(placed_at)             AS order_date,
    COUNT(*)                    AS total_orders,
    SUM(CASE WHEN status = 'delivered' THEN 1 ELSE 0 END) AS delivered,
    SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled,
    ROUND(SUM(total_amt), 2)    AS revenue
FROM orders
WHERE placed_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY DATE(placed_at)
ORDER BY order_date DESC;

-- A3. Peak ordering hours
SELECT
    HOUR(placed_at)             AS hour_of_day,
    COUNT(*)                    AS order_count,
    ROUND(AVG(total_amt), 2)    AS avg_order_value
FROM orders
GROUP BY HOUR(placed_at)
ORDER BY order_count DESC;

-- A4. Revenue by payment method
SELECT
    payment_method,
    COUNT(*)                    AS transactions,
    ROUND(SUM(total_amt), 2)    AS total_collected,
    ROUND(AVG(total_amt), 2)    AS avg_transaction
FROM orders
WHERE payment_status = 'paid'
GROUP BY payment_method
ORDER BY total_collected DESC;

-- A5. Coupon effectiveness analysis
SELECT
    c.code,
    c.discount_type,
    c.discount_value,
    c.used_count,
    ROUND(SUM(o.discount_amt), 2)           AS total_discounted,
    ROUND(SUM(o.total_amt), 2)              AS revenue_generated,
    ROUND(AVG(o.total_amt), 2)              AS avg_order_with_coupon,
    ROUND(SUM(o.discount_amt) / SUM(o.total_amt) * 100, 2) AS discount_pct_of_revenue
FROM coupons c
JOIN orders  o ON o.coupon_id = c.coupon_id AND o.status = 'delivered'
GROUP BY c.coupon_id, c.code, c.discount_type, c.discount_value, c.used_count
ORDER BY revenue_generated DESC;

-- ══════════════════════════════════════════
--  SECTION B: CUSTOMER INSIGHTS
-- ══════════════════════════════════════════

-- B1. Top customers by spend
SELECT
    u.full_name,
    u.email,
    COUNT(o.order_id)           AS orders_placed,
    ROUND(SUM(o.total_amt), 2)  AS total_spent,
    ROUND(MAX(o.total_amt), 2)  AS largest_order,
    MAX(DATE(o.placed_at))      AS last_order
FROM users u
JOIN orders o ON o.user_id = u.user_id AND o.status = 'delivered'
GROUP BY u.user_id, u.full_name, u.email
ORDER BY total_spent DESC
LIMIT 10;

-- B2. Customer retention — repeat vs one-time
SELECT
    CASE
        WHEN order_count = 1 THEN 'One-time'
        WHEN order_count BETWEEN 2 AND 5 THEN 'Occasional (2-5)'
        ELSE 'Loyal (6+)'
    END                         AS customer_type,
    COUNT(*)                    AS customer_count,
    ROUND(AVG(total_spent), 2)  AS avg_spend
FROM (
    SELECT
        user_id,
        COUNT(order_id)         AS order_count,
        SUM(total_amt)          AS total_spent
    FROM orders
    WHERE status = 'delivered'
    GROUP BY user_id
) AS user_stats
GROUP BY customer_type;

-- B3. Customers who haven't ordered in 30+ days (churn risk)
SELECT
    u.user_id,
    u.full_name,
    u.email,
    MAX(o.placed_at)            AS last_order_date,
    DATEDIFF(NOW(), MAX(o.placed_at)) AS days_since_order,
    COUNT(o.order_id)           AS lifetime_orders
FROM users u
JOIN orders o ON o.user_id = u.user_id
WHERE u.role = 'customer'
GROUP BY u.user_id, u.full_name, u.email
HAVING days_since_order > 30
ORDER BY days_since_order DESC;

-- ══════════════════════════════════════════
--  SECTION C: MENU & FOOD ANALYTICS
-- ══════════════════════════════════════════

-- C1. Best-selling items overall
SELECT
    mi.name                     AS item,
    r.name                      AS restaurant,
    SUM(oi.quantity)            AS qty_sold,
    ROUND(SUM(oi.subtotal), 2)  AS revenue,
    ROUND(AVG(rev.food_rating), 2) AS avg_rating
FROM order_items oi
JOIN menu_items  mi  ON mi.item_id       = oi.item_id
JOIN orders      o   ON o.order_id       = oi.order_id AND o.status = 'delivered'
JOIN restaurants r   ON r.restaurant_id  = mi.restaurant_id
LEFT JOIN reviews rev ON rev.restaurant_id = mi.restaurant_id
GROUP BY mi.item_id, mi.name, r.name
ORDER BY qty_sold DESC
LIMIT 10;

-- C2. Veg vs non-veg sales split
SELECT
    IF(mi.is_veg, 'Vegetarian', 'Non-Vegetarian') AS food_type,
    COUNT(DISTINCT oi.order_item_id)               AS items_ordered,
    SUM(oi.quantity)                               AS total_qty,
    ROUND(SUM(oi.subtotal), 2)                     AS total_revenue
FROM order_items oi
JOIN menu_items mi ON mi.item_id = oi.item_id
JOIN orders      o  ON o.order_id = oi.order_id AND o.status = 'delivered'
GROUP BY mi.is_veg;

-- C3. Menu items never ordered (dead stock)
SELECT
    mi.item_id,
    mi.name             AS item_name,
    r.name              AS restaurant,
    mi.price,
    mi.is_available,
    mi.created_at
FROM menu_items mi
JOIN restaurants r ON r.restaurant_id = mi.restaurant_id
LEFT JOIN order_items oi ON oi.item_id = mi.item_id
WHERE oi.item_id IS NULL
ORDER BY mi.created_at;

-- ══════════════════════════════════════════
--  SECTION D: DELIVERY PERFORMANCE
-- ══════════════════════════════════════════

-- D1. Rider performance summary
SELECT
    u.full_name                 AS rider,
    ri.vehicle_type,
    COUNT(o.order_id)           AS deliveries,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, o.placed_at, o.delivered_at)), 1) AS avg_delivery_min,
    ROUND(MIN(TIMESTAMPDIFF(MINUTE, o.placed_at, o.delivered_at)), 1) AS fastest_min,
    ROUND(AVG(rev.delivery_rating), 2) AS avg_rating
FROM riders ri
JOIN users   u   ON u.user_id   = ri.user_id
LEFT JOIN orders  o   ON o.rider_id   = ri.rider_id AND o.status = 'delivered'
LEFT JOIN reviews rev ON rev.rider_id = ri.rider_id
GROUP BY ri.rider_id, u.full_name, ri.vehicle_type
ORDER BY avg_rating DESC;

-- D2. Late deliveries (delivered > estimated time)
SELECT
    o.order_id,
    u.full_name                 AS customer,
    r.name                      AS restaurant,
    o.estimated_time            AS est_min,
    TIMESTAMPDIFF(MINUTE, o.placed_at, o.delivered_at) AS actual_min,
    TIMESTAMPDIFF(MINUTE, o.placed_at, o.delivered_at) - o.estimated_time AS delay_min
FROM orders o
JOIN users       u ON u.user_id       = o.user_id
JOIN restaurants r ON r.restaurant_id = o.restaurant_id
WHERE o.status = 'delivered'
  AND TIMESTAMPDIFF(MINUTE, o.placed_at, o.delivered_at) > o.estimated_time
ORDER BY delay_min DESC;

-- D3. Cancellation rate per restaurant
SELECT
    r.name                      AS restaurant,
    COUNT(o.order_id)           AS total_orders,
    SUM(CASE WHEN o.status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled,
    ROUND(
        SUM(CASE WHEN o.status = 'cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(o.order_id), 2
    )                           AS cancel_rate_pct
FROM restaurants r
LEFT JOIN orders o ON o.restaurant_id = r.restaurant_id
GROUP BY r.restaurant_id, r.name
ORDER BY cancel_rate_pct DESC;

-- ══════════════════════════════════════════
--  SECTION E: ADVANCED WINDOW FUNCTIONS
-- ══════════════════════════════════════════

-- E1. Running total revenue per restaurant (by date)
SELECT
    r.name                      AS restaurant,
    DATE(o.placed_at)           AS order_date,
    ROUND(SUM(o.total_amt), 2)  AS daily_revenue,
    ROUND(SUM(SUM(o.total_amt)) OVER (
        PARTITION BY r.restaurant_id
        ORDER BY DATE(o.placed_at)
    ), 2)                       AS running_total
FROM orders o
JOIN restaurants r ON r.restaurant_id = o.restaurant_id
WHERE o.status = 'delivered'
GROUP BY r.restaurant_id, r.name, DATE(o.placed_at)
ORDER BY r.name, order_date;

-- E2. Rank customers by spending within each city
SELECT
    a.city,
    u.full_name,
    ROUND(SUM(o.total_amt), 2)  AS total_spent,
    RANK() OVER (
        PARTITION BY a.city
        ORDER BY SUM(o.total_amt) DESC
    )                           AS city_rank
FROM orders o
JOIN users     u  ON u.user_id    = o.user_id
JOIN addresses a  ON a.address_id = o.address_id
WHERE o.status = 'delivered'
GROUP BY a.city, u.user_id, u.full_name
ORDER BY a.city, city_rank;

-- E3. Month-over-month growth
SELECT
    DATE_FORMAT(placed_at, '%Y-%m')     AS month,
    ROUND(SUM(total_amt), 2)            AS revenue,
    ROUND(SUM(total_amt) - LAG(SUM(total_amt)) OVER (ORDER BY DATE_FORMAT(placed_at, '%Y-%m')), 2) AS mom_change,
    ROUND(
        (SUM(total_amt) - LAG(SUM(total_amt)) OVER (ORDER BY DATE_FORMAT(placed_at, '%Y-%m'))) * 100.0 /
        NULLIF(LAG(SUM(total_amt)) OVER (ORDER BY DATE_FORMAT(placed_at, '%Y-%m')), 0)
    , 2)                                AS mom_growth_pct
FROM orders
WHERE status = 'delivered'
GROUP BY DATE_FORMAT(placed_at, '%Y-%m')
ORDER BY month;

-- E4. Each restaurant's most ordered item (using CTE + RANK)
WITH ranked_items AS (
    SELECT
        r.name                          AS restaurant,
        mi.name                         AS item,
        SUM(oi.quantity)                AS qty_sold,
        RANK() OVER (
            PARTITION BY r.restaurant_id
            ORDER BY SUM(oi.quantity) DESC
        )                               AS rnk
    FROM order_items oi
    JOIN menu_items  mi ON mi.item_id       = oi.item_id
    JOIN restaurants r  ON r.restaurant_id  = mi.restaurant_id
    JOIN orders      o  ON o.order_id       = oi.order_id AND o.status = 'delivered'
    GROUP BY r.restaurant_id, r.name, mi.item_id, mi.name
)
SELECT restaurant, item, qty_sold
FROM   ranked_items
WHERE  rnk = 1;

-- ══════════════════════════════════════════
--  SECTION F: OPERATIONAL QUERIES
-- ══════════════════════════════════════════

-- F1. Live active orders tracker
SELECT
    o.order_id,
    u.full_name                 AS customer,
    r.name                      AS restaurant,
    COALESCE(ru.full_name,'Unassigned') AS rider,
    o.status,
    o.total_amt,
    TIMESTAMPDIFF(MINUTE, o.placed_at, NOW()) AS minutes_since_placed,
    o.estimated_time
FROM orders o
JOIN users       u  ON u.user_id       = o.user_id
JOIN restaurants r  ON r.restaurant_id = o.restaurant_id
LEFT JOIN riders ri ON ri.rider_id     = o.rider_id
LEFT JOIN users  ru ON ru.user_id      = ri.user_id
WHERE o.status NOT IN ('delivered','cancelled','refunded')
ORDER BY o.placed_at ASC;

-- F2. Available riders right now
SELECT
    u.full_name     AS rider_name,
    ri.vehicle_type,
    ri.vehicle_number,
    ri.total_deliveries,
    ri.avg_rating,
    ri.current_lat,
    ri.current_lng
FROM riders ri
JOIN users u ON u.user_id = ri.user_id
WHERE ri.is_available = TRUE;

-- F3. Expired / about-to-expire coupons
SELECT
    code,
    description,
    discount_type,
    discount_value,
    used_count,
    usage_limit,
    valid_until,
    CASE
        WHEN valid_until < NOW()             THEN 'Expired'
        WHEN valid_until < DATE_ADD(NOW(), INTERVAL 7 DAY) THEN 'Expiring soon'
        ELSE 'Active'
    END AS status
FROM coupons
ORDER BY valid_until ASC;
