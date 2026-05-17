-- ============================================================
--  FOOD DELIVERY PLATFORM DATABASE
--  File: 04_procedures.sql
--  Description: Stored procedures for core business logic
-- ============================================================

USE food_delivery_db;
DELIMITER $$

-- ─────────────────────────────────────────
--  PROC 1: Place a new order
-- ─────────────────────────────────────────
CREATE PROCEDURE sp_place_order(
    IN  p_user_id       INT,
    IN  p_restaurant_id INT,
    IN  p_address_id    INT,
    IN  p_coupon_code   VARCHAR(30),
    IN  p_payment_method ENUM('cash','card','upi','wallet'),
    IN  p_special_note  TEXT,
    OUT p_order_id      INT,
    OUT p_message       VARCHAR(255)
)
BEGIN
    DECLARE v_coupon_id      INT DEFAULT NULL;
    DECLARE v_discount_type  VARCHAR(20);
    DECLARE v_discount_value DECIMAL(10,2) DEFAULT 0;
    DECLARE v_max_discount   DECIMAL(10,2);
    DECLARE v_min_order      DECIMAL(10,2);
    DECLARE v_subtotal       DECIMAL(10,2);
    DECLARE v_discount_amt   DECIMAL(10,2) DEFAULT 0;
    DECLARE v_delivery_fee   DECIMAL(10,2) DEFAULT 40.00;
    DECLARE v_tax_rate       DECIMAL(5,4) DEFAULT 0.09;
    DECLARE v_tax_amt        DECIMAL(10,2);
    DECLARE v_total          DECIMAL(10,2);
    DECLARE v_est_time       INT DEFAULT 35;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_message = 'Error: Order placement failed due to a database error.';
        SET p_order_id = NULL;
    END;

    START TRANSACTION;

    -- Calculate subtotal from cart (latest unlinked order_items for this user)
    -- In production this would come from a cart table; here we use passed items
    SET v_subtotal = 300.00; -- placeholder; real app sums cart

    -- Validate coupon
    IF p_coupon_code IS NOT NULL AND p_coupon_code != '' THEN
        SELECT coupon_id, discount_type, discount_value, max_discount, min_order_amt
        INTO   v_coupon_id, v_discount_type, v_discount_value, v_max_discount, v_min_order
        FROM   coupons
        WHERE  code = p_coupon_code
          AND  is_active = TRUE
          AND  NOW() BETWEEN valid_from AND valid_until
          AND  used_count < usage_limit
        LIMIT 1;

        IF v_coupon_id IS NULL THEN
            SET p_message  = 'Invalid or expired coupon code.';
            SET p_order_id = NULL;
            ROLLBACK;
            LEAVE sp_place_order;
        END IF;

        IF v_subtotal < v_min_order THEN
            SET p_message  = CONCAT('Minimum order of ₹', v_min_order, ' required for this coupon.');
            SET p_order_id = NULL;
            ROLLBACK;
            LEAVE sp_place_order;
        END IF;

        IF v_discount_type = 'flat' THEN
            SET v_discount_amt = v_discount_value;
        ELSE
            SET v_discount_amt = ROUND(v_subtotal * v_discount_value / 100, 2);
        END IF;

        IF v_max_discount IS NOT NULL AND v_discount_amt > v_max_discount THEN
            SET v_discount_amt = v_max_discount;
        END IF;

        -- Mark coupon used
        UPDATE coupons SET used_count = used_count + 1 WHERE coupon_id = v_coupon_id;
    END IF;

    -- Delivery fee waiver for large orders
    IF v_subtotal >= 500 THEN SET v_delivery_fee = 0; END IF;

    SET v_tax_amt = ROUND((v_subtotal - v_discount_amt) * v_tax_rate, 2);
    SET v_total   = v_subtotal - v_discount_amt + v_delivery_fee + v_tax_amt;

    -- Create order
    INSERT INTO orders
        (user_id, restaurant_id, address_id, coupon_id, status,
         subtotal, discount_amt, delivery_fee, tax_amt, total_amt,
         payment_method, payment_status, special_note, estimated_time)
    VALUES
        (p_user_id, p_restaurant_id, p_address_id, v_coupon_id, 'placed',
         v_subtotal, v_discount_amt, v_delivery_fee, v_tax_amt, v_total,
         p_payment_method,
         IF(p_payment_method = 'cash', 'pending', 'pending'),
         p_special_note, v_est_time);

    SET p_order_id = LAST_INSERT_ID();

    -- Record status history
    INSERT INTO order_status_history (order_id, status, note)
    VALUES (p_order_id, 'placed', 'Order placed successfully by customer.');

    COMMIT;
    SET p_message = CONCAT('Order #', p_order_id, ' placed successfully! Estimated time: ', v_est_time, ' minutes.');
END$$

-- ─────────────────────────────────────────
--  PROC 2: Update order status
-- ─────────────────────────────────────────
CREATE PROCEDURE sp_update_order_status(
    IN  p_order_id  INT,
    IN  p_new_status VARCHAR(30),
    IN  p_changed_by INT,
    IN  p_note      TEXT,
    OUT p_success   BOOLEAN,
    OUT p_message   VARCHAR(255)
)
BEGIN
    DECLARE v_current_status VARCHAR(30);
    DECLARE v_allowed        BOOLEAN DEFAULT FALSE;

    SELECT status INTO v_current_status FROM orders WHERE order_id = p_order_id;

    IF v_current_status IS NULL THEN
        SET p_success = FALSE;
        SET p_message = 'Order not found.';
        LEAVE sp_update_order_status;
    END IF;

    -- Transition rules
    SET v_allowed = CASE
        WHEN v_current_status = 'placed'     AND p_new_status IN ('confirmed','cancelled') THEN TRUE
        WHEN v_current_status = 'confirmed'  AND p_new_status IN ('preparing','cancelled') THEN TRUE
        WHEN v_current_status = 'preparing'  AND p_new_status = 'ready'                   THEN TRUE
        WHEN v_current_status = 'ready'      AND p_new_status = 'picked_up'               THEN TRUE
        WHEN v_current_status = 'picked_up'  AND p_new_status = 'on_the_way'              THEN TRUE
        WHEN v_current_status = 'on_the_way' AND p_new_status = 'delivered'               THEN TRUE
        WHEN p_new_status = 'cancelled'                                                    THEN TRUE
        ELSE FALSE
    END;

    IF NOT v_allowed THEN
        SET p_success = FALSE;
        SET p_message = CONCAT('Invalid transition: ', v_current_status, ' → ', p_new_status);
        LEAVE sp_update_order_status;
    END IF;

    UPDATE orders SET
        status       = p_new_status,
        delivered_at = IF(p_new_status = 'delivered', NOW(), delivered_at),
        cancelled_at = IF(p_new_status = 'cancelled', NOW(), cancelled_at),
        cancel_reason= IF(p_new_status = 'cancelled', p_note, cancel_reason)
    WHERE order_id = p_order_id;

    INSERT INTO order_status_history (order_id, status, changed_by, note)
    VALUES (p_order_id, p_new_status, p_changed_by, p_note);

    SET p_success = TRUE;
    SET p_message = CONCAT('Order #', p_order_id, ' updated to ', p_new_status);
END$$

-- ─────────────────────────────────────────
--  PROC 3: Assign rider to order
-- ─────────────────────────────────────────
CREATE PROCEDURE sp_assign_rider(
    IN  p_order_id  INT,
    OUT p_rider_id  INT,
    OUT p_message   VARCHAR(255)
)
BEGIN
    DECLARE v_restaurant_id INT;
    DECLARE v_lat           DECIMAL(10,7);
    DECLARE v_lng           DECIMAL(10,7);

    SELECT r.latitude, r.longitude, o.restaurant_id
    INTO   v_lat, v_lng, v_restaurant_id
    FROM   orders o
    JOIN   restaurants r ON r.restaurant_id = o.restaurant_id
    WHERE  o.order_id = p_order_id;

    -- Find nearest available rider (simplified: pick any available)
    SELECT rider_id INTO p_rider_id
    FROM   riders
    WHERE  is_available = TRUE
    ORDER BY (
        POW(current_lat - v_lat, 2) + POW(current_lng - v_lng, 2)
    ) ASC
    LIMIT 1;

    IF p_rider_id IS NULL THEN
        SET p_message = 'No riders available at the moment. Please try again shortly.';
    ELSE
        UPDATE orders  SET rider_id    = p_rider_id WHERE order_id = p_order_id;
        UPDATE riders  SET is_available = FALSE     WHERE rider_id = p_rider_id;
        SET p_message = CONCAT('Rider #', p_rider_id, ' assigned to order #', p_order_id);
    END IF;
END$$

-- ─────────────────────────────────────────
--  PROC 4: Monthly revenue report
-- ─────────────────────────────────────────
CREATE PROCEDURE sp_monthly_revenue(IN p_year INT, IN p_month INT)
BEGIN
    SELECT
        r.name                                          AS restaurant,
        COUNT(o.order_id)                               AS total_orders,
        ROUND(SUM(o.total_amt), 2)                      AS revenue,
        ROUND(AVG(o.total_amt), 2)                      AS avg_order,
        ROUND(SUM(o.discount_amt), 2)                   AS total_discounts,
        ROUND(SUM(o.delivery_fee), 2)                   AS delivery_fees_collected
    FROM orders o
    JOIN restaurants r ON r.restaurant_id = o.restaurant_id
    WHERE YEAR(o.placed_at)  = p_year
      AND MONTH(o.placed_at) = p_month
      AND o.status = 'delivered'
    GROUP BY r.restaurant_id, r.name
    ORDER BY revenue DESC;
END$$

-- ─────────────────────────────────────────
--  PROC 5: Search restaurants by city & cuisine
-- ─────────────────────────────────────────
CREATE PROCEDURE sp_search_restaurants(
    IN p_city        VARCHAR(100),
    IN p_cuisine     VARCHAR(100),
    IN p_min_rating  DECIMAL(3,2)
)
BEGIN
    SELECT
        r.restaurant_id,
        r.name,
        r.cuisine_type,
        r.address_line,
        r.city,
        r.avg_rating,
        r.total_reviews,
        r.delivery_radius,
        r.min_order_amt,
        CONCAT(r.opening_time, ' - ', r.closing_time) AS hours,
        COUNT(mi.item_id)                              AS menu_items
    FROM restaurants r
    LEFT JOIN menu_items mi ON mi.restaurant_id = r.restaurant_id AND mi.is_available = TRUE
    WHERE r.is_active = TRUE
      AND (p_city    IS NULL OR r.city        LIKE CONCAT('%', p_city, '%'))
      AND (p_cuisine IS NULL OR r.cuisine_type LIKE CONCAT('%', p_cuisine, '%'))
      AND r.avg_rating >= IFNULL(p_min_rating, 0)
    GROUP BY r.restaurant_id
    ORDER BY r.avg_rating DESC, r.total_reviews DESC;
END$$

DELIMITER ;
