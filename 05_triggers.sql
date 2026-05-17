-- ============================================================
--  FOOD DELIVERY PLATFORM DATABASE
--  File: 05_triggers.sql
--  Description: Automated triggers for business rules
-- ============================================================

USE food_delivery_db;
DELIMITER $$

-- ─────────────────────────────────────────
--  TRIGGER 1: Auto-update restaurant rating after review
-- ─────────────────────────────────────────
CREATE TRIGGER trg_update_restaurant_rating
AFTER INSERT ON reviews
FOR EACH ROW
BEGIN
    UPDATE restaurants
    SET
        avg_rating    = (
            SELECT ROUND(AVG(food_rating), 2)
            FROM   reviews
            WHERE  restaurant_id = NEW.restaurant_id
        ),
        total_reviews = (
            SELECT COUNT(*)
            FROM   reviews
            WHERE  restaurant_id = NEW.restaurant_id
        )
    WHERE restaurant_id = NEW.restaurant_id;
END$$

-- ─────────────────────────────────────────
--  TRIGGER 2: Auto-update rider rating & stats after review
-- ─────────────────────────────────────────
CREATE TRIGGER trg_update_rider_stats
AFTER INSERT ON reviews
FOR EACH ROW
BEGIN
    IF NEW.rider_id IS NOT NULL THEN
        UPDATE riders
        SET
            avg_rating       = (
                SELECT ROUND(AVG(delivery_rating), 2)
                FROM   reviews
                WHERE  rider_id = NEW.rider_id
                  AND  delivery_rating IS NOT NULL
            ),
            total_deliveries = (
                SELECT COUNT(*)
                FROM   orders
                WHERE  rider_id = NEW.rider_id AND status = 'delivered'
            )
        WHERE rider_id = NEW.rider_id;
    END IF;
END$$

-- ─────────────────────────────────────────
--  TRIGGER 3: Free rider after delivery
-- ─────────────────────────────────────────
CREATE TRIGGER trg_free_rider_on_delivery
AFTER UPDATE ON orders
FOR EACH ROW
BEGIN
    IF NEW.status = 'delivered' AND OLD.status != 'delivered' AND NEW.rider_id IS NOT NULL THEN
        UPDATE riders
        SET is_available = TRUE
        WHERE rider_id = NEW.rider_id;
    END IF;
END$$

-- ─────────────────────────────────────────
--  TRIGGER 4: Auto-notify customer on status change
-- ─────────────────────────────────────────
CREATE TRIGGER trg_notify_on_status_change
AFTER UPDATE ON orders
FOR EACH ROW
BEGIN
    DECLARE v_title   VARCHAR(150);
    DECLARE v_message TEXT;

    IF NEW.status != OLD.status THEN
        CASE NEW.status
            WHEN 'confirmed'  THEN
                SET v_title   = 'Order Confirmed ✅';
                SET v_message = CONCAT('Great news! Restaurant has confirmed your order #', NEW.order_id, '.');
            WHEN 'preparing'  THEN
                SET v_title   = 'Preparing your order 🍳';
                SET v_message = CONCAT('The kitchen is preparing your order #', NEW.order_id, '. Hang tight!');
            WHEN 'picked_up'  THEN
                SET v_title   = 'Rider picked up 🛵';
                SET v_message = CONCAT('Your order #', NEW.order_id, ' has been picked up by the rider.');
            WHEN 'on_the_way' THEN
                SET v_title   = 'On the way! 📍';
                SET v_message = CONCAT('Your order #', NEW.order_id, ' is ', NEW.estimated_time, ' minutes away!');
            WHEN 'delivered'  THEN
                SET v_title   = 'Delivered! 🎉';
                SET v_message = CONCAT('Your order #', NEW.order_id, ' has been delivered. Enjoy your meal!');
            WHEN 'cancelled'  THEN
                SET v_title   = 'Order Cancelled ❌';
                SET v_message = CONCAT('Your order #', NEW.order_id, ' has been cancelled. Refund will be processed.');
            ELSE
                SET v_title   = NULL;
                SET v_message = NULL;
        END CASE;

        IF v_title IS NOT NULL THEN
            INSERT INTO notifications (user_id, order_id, type, title, message)
            VALUES (NEW.user_id, NEW.order_id, 'order_update', v_title, v_message);
        END IF;
    END IF;
END$$

-- ─────────────────────────────────────────
--  TRIGGER 5: Prevent review without delivery
-- ─────────────────────────────────────────
CREATE TRIGGER trg_validate_review
BEFORE INSERT ON reviews
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(30);

    SELECT status INTO v_status FROM orders WHERE order_id = NEW.order_id;

    IF v_status != 'delivered' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Reviews can only be submitted for delivered orders.';
    END IF;
END$$

-- ─────────────────────────────────────────
--  TRIGGER 6: Ensure only one default address per user
-- ─────────────────────────────────────────
CREATE TRIGGER trg_single_default_address
BEFORE INSERT ON addresses
FOR EACH ROW
BEGIN
    IF NEW.is_default = TRUE THEN
        UPDATE addresses
        SET is_default = FALSE
        WHERE user_id = NEW.user_id AND is_default = TRUE;
    END IF;
END$$

-- ─────────────────────────────────────────
--  TRIGGER 7: Log payment on order creation
-- ─────────────────────────────────────────
CREATE TRIGGER trg_create_payment_record
AFTER INSERT ON orders
FOR EACH ROW
BEGIN
    INSERT INTO payments (order_id, method, amount, status)
    VALUES (NEW.order_id, NEW.payment_method, NEW.total_amt, 'pending');
END$$

DELIMITER ;
