-- ============================================================
--  FOOD DELIVERY PLATFORM DATABASE
--  File: 03_views.sql
--  Description: Useful views for reporting and app queries
-- ============================================================

USE food_delivery_db;

-- ─────────────────────────────────────────
--  VIEW 1: Active menu with effective price
-- ─────────────────────────────────────────
CREATE OR REPLACE VIEW vw_menu_with_price AS
SELECT
    mi.item_id,
    r.restaurant_id,
    r.name                                              AS restaurant_name,
    r.cuisine_type,
    c.name                                              AS category,
    mi.name                                             AS item_name,
    mi.description,
    mi.price                                            AS original_price,
    mi.discount_pct,
    ROUND(mi.price * (1 - mi.discount_pct / 100), 2)  AS effective_price,
    mi.is_veg,
    mi.calories,
    mi.prep_time_min,
    mi.is_available
FROM menu_items mi
JOIN restaurants r  ON r.restaurant_id = mi.restaurant_id
LEFT JOIN categories c ON c.category_id = mi.category_id
WHERE r.is_active = TRUE;

-- ─────────────────────────────────────────
--  VIEW 2: Order summary with all details
-- ─────────────────────────────────────────
CREATE OR REPLACE VIEW vw_order_summary AS
SELECT
    o.order_id,
    o.placed_at,
    u.full_name                                          AS customer_name,
    u.phone                                              AS customer_phone,
    r.name                                               AS restaurant_name,
    CONCAT(ru.full_name, ' (', ri.vehicle_type, ')')    AS rider_info,
    CONCAT(a.address_line, ', ', a.city)                AS delivery_address,
    o.status,
    o.subtotal,
    o.discount_amt,
    o.delivery_fee,
    o.tax_amt,
    o.total_amt,
    o.payment_method,
    o.payment_status,
    o.estimated_time                                     AS est_minutes,
    TIMESTAMPDIFF(MINUTE, o.placed_at, o.delivered_at)  AS actual_minutes,
    o.delivered_at
FROM orders o
JOIN users       u  ON u.user_id       = o.user_id
JOIN restaurants r  ON r.restaurant_id = o.restaurant_id
JOIN addresses   a  ON a.address_id    = o.address_id
LEFT JOIN riders ri ON ri.rider_id     = o.rider_id
LEFT JOIN users  ru ON ru.user_id      = ri.user_id;

-- ─────────────────────────────────────────
--  VIEW 3: Restaurant performance dashboard
-- ─────────────────────────────────────────
CREATE OR REPLACE VIEW vw_restaurant_performance AS
SELECT
    r.restaurant_id,
    r.name                                                  AS restaurant_name,
    r.cuisine_type,
    r.city,
    COUNT(DISTINCT o.order_id)                              AS total_orders,
    COUNT(DISTINCT CASE WHEN o.status = 'delivered' THEN o.order_id END) AS delivered_orders,
    COUNT(DISTINCT CASE WHEN o.status = 'cancelled' THEN o.order_id END) AS cancelled_orders,
    ROUND(SUM(CASE WHEN o.status = 'delivered' THEN o.total_amt ELSE 0 END), 2) AS total_revenue,
    ROUND(AVG(CASE WHEN o.status = 'delivered' THEN o.total_amt END), 2)        AS avg_order_value,
    ROUND(AVG(rev.food_rating), 2)                          AS avg_food_rating,
    COUNT(rev.review_id)                                    AS review_count,
    ROUND(
        COUNT(DISTINCT CASE WHEN o.status = 'delivered' THEN o.order_id END) * 100.0 /
        NULLIF(COUNT(DISTINCT o.order_id), 0), 2
    )                                                       AS delivery_success_rate
FROM restaurants r
LEFT JOIN orders  o   ON o.restaurant_id = r.restaurant_id
LEFT JOIN reviews rev ON rev.restaurant_id = r.restaurant_id
GROUP BY r.restaurant_id, r.name, r.cuisine_type, r.city;

-- ─────────────────────────────────────────
--  VIEW 4: Rider leaderboard
-- ─────────────────────────────────────────
CREATE OR REPLACE VIEW vw_rider_leaderboard AS
SELECT
    ri.rider_id,
    u.full_name                                             AS rider_name,
    u.phone,
    ri.vehicle_type,
    ri.is_available,
    COUNT(DISTINCT o.order_id)                              AS total_deliveries,
    ROUND(AVG(rev.delivery_rating), 2)                      AS avg_delivery_rating,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, o.placed_at, o.delivered_at)), 1) AS avg_delivery_time_min,
    ROUND(SUM(o.delivery_fee), 2)                           AS total_earnings
FROM riders ri
JOIN users  u   ON u.user_id   = ri.user_id
LEFT JOIN orders  o   ON o.rider_id   = ri.rider_id AND o.status = 'delivered'
LEFT JOIN reviews rev ON rev.rider_id = ri.rider_id
GROUP BY ri.rider_id, u.full_name, u.phone, ri.vehicle_type, ri.is_available;

-- ─────────────────────────────────────────
--  VIEW 5: Customer order history
-- ─────────────────────────────────────────
CREATE OR REPLACE VIEW vw_customer_history AS
SELECT
    u.user_id,
    u.full_name,
    u.email,
    COUNT(o.order_id)                                       AS total_orders,
    ROUND(SUM(o.total_amt), 2)                              AS total_spent,
    ROUND(AVG(o.total_amt), 2)                              AS avg_order_value,
    MAX(o.placed_at)                                        AS last_order_date,
    COUNT(DISTINCT o.restaurant_id)                         AS unique_restaurants,
    COUNT(DISTINCT rev.review_id)                           AS reviews_written
FROM users u
LEFT JOIN orders  o   ON o.user_id  = u.user_id AND o.status = 'delivered'
LEFT JOIN reviews rev ON rev.user_id = u.user_id
WHERE u.role = 'customer'
GROUP BY u.user_id, u.full_name, u.email;

-- ─────────────────────────────────────────
--  VIEW 6: Top selling menu items
-- ─────────────────────────────────────────
CREATE OR REPLACE VIEW vw_top_menu_items AS
SELECT
    mi.item_id,
    mi.name                         AS item_name,
    r.name                          AS restaurant_name,
    c.name                          AS category,
    mi.price,
    SUM(oi.quantity)                AS total_qty_sold,
    COUNT(DISTINCT oi.order_id)     AS order_count,
    ROUND(SUM(oi.subtotal), 2)      AS total_revenue,
    ROUND(AVG(rev.food_rating), 2)  AS avg_rating
FROM menu_items mi
JOIN order_items oi  ON oi.item_id       = mi.item_id
JOIN orders      o   ON o.order_id       = oi.order_id AND o.status = 'delivered'
JOIN restaurants r   ON r.restaurant_id  = mi.restaurant_id
LEFT JOIN categories c   ON c.category_id   = mi.category_id
LEFT JOIN reviews    rev ON rev.restaurant_id = mi.restaurant_id
GROUP BY mi.item_id, mi.name, r.name, c.name, mi.price;
