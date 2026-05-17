-- ============================================================
--  FOOD DELIVERY PLATFORM DATABASE
--  File: 02_seed_data.sql
--  Description: Sample data for testing and demo
-- ============================================================

USE food_delivery_db;

-- ─────────────────────────────────────────
--  USERS
-- ─────────────────────────────────────────
INSERT INTO users (full_name, email, phone, password_hash, role) VALUES
('Arjun Sharma',     'arjun@email.com',   '9876543210', SHA2('pass123', 256), 'customer'),
('Priya Nair',       'priya@email.com',   '9876543211', SHA2('pass123', 256), 'customer'),
('Rohit Verma',      'rohit@email.com',   '9876543212', SHA2('pass123', 256), 'customer'),
('Sneha Patel',      'sneha@email.com',   '9876543213', SHA2('pass123', 256), 'customer'),
('Karan Mehta',      'karan@email.com',   '9876543214', SHA2('pass123', 256), 'customer'),
('Rahul Rider',      'rahul.r@email.com', '9000000001', SHA2('pass123', 256), 'rider'),
('Amit Rider',       'amit.r@email.com',  '9000000002', SHA2('pass123', 256), 'rider'),
('Vijay Rider',      'vijay.r@email.com', '9000000003', SHA2('pass123', 256), 'rider'),
('Spice Garden',     'spice@rest.com',    '8000000001', SHA2('pass123', 256), 'customer'),
('Pizza Paradise',   'pizza@rest.com',    '8000000002', SHA2('pass123', 256), 'customer'),
('Burger Barn',      'burger@rest.com',   '8000000003', SHA2('pass123', 256), 'customer'),
('Wok & Roll',       'wok@rest.com',      '8000000004', SHA2('pass123', 256), 'customer'),
('Admin User',       'admin@fdelivery.com','9999999999', SHA2('admin123', 256), 'admin');

-- ─────────────────────────────────────────
--  ADDRESSES
-- ─────────────────────────────────────────
INSERT INTO addresses (user_id, label, address_line, city, state, pincode, latitude, longitude, is_default) VALUES
(1, 'Home',   '12, MG Road, Indiranagar',    'Bangalore', 'Karnataka', '560038', 12.9719, 77.6412, TRUE),
(1, 'Work',   '100, Whitefield Tech Park',   'Bangalore', 'Karnataka', '560066', 12.9716, 77.7499, FALSE),
(2, 'Home',   '45, Anna Nagar, 6th Street',  'Chennai',   'Tamil Nadu','600040', 13.0827, 80.2707, TRUE),
(3, 'Home',   '7, Bandra West, Hill Road',   'Mumbai',    'Maharashtra','400050',19.0596, 72.8295, TRUE),
(4, 'Home',   '23, Connaught Place, Block B','Delhi',     'Delhi',     '110001', 28.6315, 77.2167, TRUE),
(5, 'Home',   '89, Park Street',             'Kolkata',   'West Bengal','700016',22.5514, 88.3516, TRUE);

-- ─────────────────────────────────────────
--  CATEGORIES
-- ─────────────────────────────────────────
INSERT INTO categories (name, description) VALUES
('Biryani',      'Fragrant rice dishes slow-cooked with spices'),
('Pizza',        'Italian flatbread with various toppings'),
('Burgers',      'Grilled patties in buns with sauces'),
('Chinese',      'Stir-fried noodles, rice and dimsums'),
('South Indian', 'Dosas, idlis, vadas and more'),
('Desserts',     'Sweet treats and ice creams'),
('Beverages',    'Juices, shakes and hot drinks'),
('Rolls & Wraps','Stuffed flatbreads and wraps');

-- ─────────────────────────────────────────
--  RESTAURANTS
-- ─────────────────────────────────────────
INSERT INTO restaurants
    (owner_id, name, description, cuisine_type, address_line, city, state, pincode,
     latitude, longitude, phone, opening_time, closing_time, delivery_radius, min_order_amt, is_active, is_verified)
VALUES
(9,  'Spice Garden',   'Authentic Indian cuisine with rich flavours', 'Indian',
     'Shop 4, Commercial Street', 'Bangalore', 'Karnataka', '560001',
     12.9766, 77.6101, '080-41234567', '10:00', '23:00', 8.00, 150.00, TRUE, TRUE),

(10, 'Pizza Paradise', 'Wood-fired pizzas and Italian classics', 'Italian',
     '2nd Floor, Forum Mall', 'Bangalore', 'Karnataka', '560029',
     12.9347, 77.6101, '080-41234568', '11:00', '23:30', 6.00, 200.00, TRUE, TRUE),

(11, 'Burger Barn',    'Gourmet smash burgers and crispy fries', 'American',
     '15, Church Street', 'Bangalore', 'Karnataka', '560001',
     12.9716, 77.6070, '080-41234569', '10:00', '22:00', 5.00, 100.00, TRUE, TRUE),

(12, 'Wok & Roll',     'Pan-Asian street food and noodles', 'Chinese',
     '88, Koramangala 5th Block', 'Bangalore', 'Karnataka', '560095',
     12.9279, 77.6271, '080-41234570', '11:00', '23:00', 7.00, 120.00, TRUE, TRUE);

-- ─────────────────────────────────────────
--  MENU ITEMS
-- ─────────────────────────────────────────
-- Spice Garden (restaurant_id = 1)
INSERT INTO menu_items (restaurant_id, category_id, name, description, price, discount_pct, is_veg, calories, prep_time_min) VALUES
(1, 1, 'Chicken Biryani',        'Hyderabadi dum biryani with raita',       299.00, 0.00,  FALSE, 650, 25),
(1, 1, 'Veg Biryani',            'Aromatic basmati with fresh vegetables',  199.00, 10.00, TRUE,  500, 20),
(1, 5, 'Masala Dosa',            'Crispy dosa with spiced potato filling',  120.00, 0.00,  TRUE,  380, 15),
(1, 5, 'Idli Sambar (4 pcs)',    'Steamed rice cakes with sambar & chutney', 89.00, 0.00,  TRUE,  280, 10),
(1, 6, 'Gulab Jamun (2 pcs)',    'Soft milk-solid balls in sugar syrup',     79.00, 0.00,  TRUE,  250, 5),
(1, 7, 'Masala Chai',            'Spiced Indian tea with ginger',            49.00, 0.00,  TRUE,  80,  5);

-- Pizza Paradise (restaurant_id = 2)
INSERT INTO menu_items (restaurant_id, category_id, name, description, price, discount_pct, is_veg, calories, prep_time_min) VALUES
(2, 2, 'Margherita Pizza',       'Classic tomato, mozzarella and basil',    349.00, 0.00,  TRUE,  750, 20),
(2, 2, 'Pepperoni Pizza',        'Loaded with spicy pepperoni slices',       449.00, 5.00,  FALSE, 900, 20),
(2, 2, 'BBQ Chicken Pizza',      'Grilled chicken with BBQ sauce',           499.00, 0.00,  FALSE, 950, 25),
(2, 2, 'Pesto Paneer Pizza',     'Fresh paneer with basil pesto',            399.00, 0.00,  TRUE,  820, 20),
(2, 6, 'Tiramisu',               'Classic Italian coffee dessert',           199.00, 0.00,  TRUE,  420, 5),
(2, 7, 'Cold Coffee',            'Creamy iced coffee with chocolate drizzle', 99.00, 0.00,  TRUE,  200, 5);

-- Burger Barn (restaurant_id = 3)
INSERT INTO menu_items (restaurant_id, category_id, name, description, price, discount_pct, is_veg, calories, prep_time_min) VALUES
(3, 3, 'Classic Smash Burger',   'Double smash patty with American cheese', 259.00, 0.00,  FALSE, 780, 15),
(3, 3, 'Crispy Chicken Burger',  'Buttermilk fried chicken with coleslaw',  239.00, 0.00,  FALSE, 720, 15),
(3, 3, 'Veggie Supreme Burger',  'Black bean patty with guacamole',         199.00, 0.00,  TRUE,  580, 12),
(3, 3, 'Mushroom Swiss Burger',  'Sautéed mushrooms with Swiss cheese',     229.00, 10.00, TRUE,  650, 15),
(3, 6, 'Oreo Milkshake',         'Thick shake blended with Oreo cookies',   149.00, 0.00,  TRUE,  550, 5),
(3, 7, 'Fresh Lime Soda',        'Sparkling lime soda with mint',            69.00, 0.00,  TRUE,  40,  3);

-- Wok & Roll (restaurant_id = 4)
INSERT INTO menu_items (restaurant_id, category_id, name, description, price, discount_pct, is_veg, calories, prep_time_min) VALUES
(4, 4, 'Chicken Fried Rice',     'Wok-tossed rice with egg and vegetables', 199.00, 0.00,  FALSE, 600, 15),
(4, 4, 'Hakka Noodles',          'Stir-fried noodles with mixed veggies',   179.00, 0.00,  TRUE,  520, 12),
(4, 4, 'Veg Dimsums (6 pcs)',    'Steamed dumplings with chili dip',        169.00, 0.00,  TRUE,  340, 15),
(4, 4, 'Chilli Chicken',         'Crispy chicken tossed in spicy sauce',    249.00, 0.00,  FALSE, 680, 20),
(4, 8, 'Paneer Frankies (2 pcs)','Grilled paneer wrap with mint chutney',   189.00, 5.00,  TRUE,  450, 10),
(4, 7, 'Thai Iced Tea',          'Creamy spiced Thai tea over ice',          99.00, 0.00,  TRUE,  180, 5);

-- ─────────────────────────────────────────
--  RIDERS
-- ─────────────────────────────────────────
INSERT INTO riders (user_id, vehicle_type, vehicle_number, license_number, is_available, current_lat, current_lng) VALUES
(6, 'bike',    'KA01AB1234', 'KA2019DL1234', TRUE,  12.9716, 77.5946),
(7, 'scooter', 'KA02CD5678', 'KA2020DL5678', TRUE,  12.9352, 77.6245),
(8, 'bicycle', 'N/A',        'KA2021DL9012', FALSE, 12.9279, 77.6271);

-- ─────────────────────────────────────────
--  COUPONS
-- ─────────────────────────────────────────
INSERT INTO coupons (code, description, discount_type, discount_value, min_order_amt, max_discount, usage_limit, valid_from, valid_until) VALUES
('WELCOME50',  'New user 50% off up to ₹100',   'percentage', 50.00, 100.00, 100.00, 1000, '2024-01-01', '2025-12-31'),
('FLAT100',    'Flat ₹100 off on ₹400+',         'flat',      100.00, 400.00, NULL,   500,  '2024-01-01', '2025-06-30'),
('PIZZA20',    '20% off on any pizza order',     'percentage', 20.00, 200.00,  80.00, 200,  '2024-01-01', '2025-03-31'),
('FREESHIP',   'Free delivery on all orders',    'flat',       40.00,  50.00, NULL,   2000, '2024-01-01', '2025-12-31'),
('WEEKEND30',  '30% off on weekends',            'percentage', 30.00, 150.00, 120.00, 500,  '2024-01-01', '2025-12-31');

-- ─────────────────────────────────────────
--  ORDERS
-- ─────────────────────────────────────────
INSERT INTO orders
    (user_id, restaurant_id, rider_id, address_id, coupon_id, status,
     subtotal, discount_amt, delivery_fee, tax_amt, total_amt,
     payment_method, payment_status, estimated_time, placed_at, delivered_at)
VALUES
-- Delivered orders
(1, 1, 1, 1, 1, 'delivered', 398.00,  99.00, 0.00,  35.82, 334.82, 'upi',    'paid', 35, '2024-11-01 12:10:00', '2024-11-01 12:45:00'),
(2, 2, 2, 3, 2, 'delivered', 449.00, 100.00, 40.00, 35.91, 424.91, 'card',   'paid', 40, '2024-11-02 19:05:00', '2024-11-02 19:48:00'),
(3, 3, 1, 4, NULL,'delivered',498.00,   0.00, 40.00, 53.82, 591.82, 'cash',   'paid', 30, '2024-11-03 13:20:00', '2024-11-03 13:52:00'),
(4, 4, 2, 5, 4, 'delivered', 368.00,  40.00, 0.00,  39.31, 367.31, 'wallet', 'paid', 25, '2024-11-04 20:30:00', '2024-11-04 21:00:00'),
(5, 1, 1, 6, NULL,'delivered',298.00,   0.00, 40.00, 30.42, 368.42, 'upi',   'paid', 30, '2024-11-05 14:10:00', '2024-11-05 14:45:00'),
-- More orders
(1, 2, 2, 1, 3, 'delivered', 498.00,  80.00, 0.00,  41.82, 459.82, 'card',   'paid', 35, '2024-11-06 18:00:00', '2024-11-06 18:40:00'),
(2, 3, 1, 3, NULL,'delivered',259.00,   0.00, 40.00, 29.91, 328.91, 'upi',   'paid', 20, '2024-11-07 21:10:00', '2024-11-07 21:35:00'),
(3, 4, 2, 4, 5, 'delivered', 448.00, 120.00, 40.00, 36.80, 404.80, 'cash',   'paid', 25, '2024-11-08 12:50:00', '2024-11-08 13:20:00'),
-- Active/cancelled orders
(4, 1, NULL,5, NULL,'confirmed', 398.00,  0.00, 40.00, 43.80, 481.80, 'upi',   'pending', 40, NOW(), NULL),
(5, 2, NULL,6, 1, 'preparing',  449.00, 99.00, 0.00,  35.00, 385.00, 'card',  'paid',    45, NOW(), NULL),
(1, 3, 1,   1, NULL,'on_the_way',498.00, 0.00, 40.00, 53.82, 591.82, 'cash',  'paid',    15, NOW(), NULL),
(2, 4, NULL,3, NULL,'cancelled', 368.00,  0.00, 40.00, 39.31, 447.31, 'wallet','refunded',40, NOW(), NULL);

-- ─────────────────────────────────────────
--  ORDER ITEMS
-- ─────────────────────────────────────────
INSERT INTO order_items (order_id, item_id, quantity, unit_price, discount_pct, subtotal) VALUES
-- Order 1 (Spice Garden)
(1, 1, 1, 299.00, 0.00,  299.00),
(1, 3, 1, 120.00, 0.00,  120.00),
-- Order 2 (Pizza Paradise)
(2, 8, 1, 449.00, 5.00,  426.55),
-- Order 3 (Burger Barn)
(3, 13,1, 259.00, 0.00,  259.00),
(3, 14,1, 239.00, 0.00,  239.00),
-- Order 4 (Wok & Roll)
(4, 19,1, 199.00, 0.00,  199.00),
(4, 20,1, 179.00, 0.00,  179.00),
-- Order 5 (Spice Garden)
(5, 2, 1, 199.00, 10.00, 179.10),
(5, 6, 2,  49.00, 0.00,   98.00),
-- Order 6 (Pizza Paradise)
(6, 7, 1, 349.00, 0.00,  349.00),
(6, 9, 1, 499.00, 0.00,  499.00),
-- Order 7 (Burger Barn)
(7, 13,1, 259.00, 0.00,  259.00),
-- Order 8 (Wok & Roll)
(8, 21,1, 169.00, 0.00,  169.00),
(8, 22,1, 249.00, 0.00,  249.00),
-- Order 9
(9, 1, 1, 299.00, 0.00, 299.00),
(9, 4, 1,  89.00, 0.00,  89.00),
-- Order 10
(10,7, 1, 349.00, 0.00, 349.00),
(10,11,1, 199.00, 0.00, 199.00),
-- Order 11
(11,13,2, 259.00, 0.00, 518.00),
-- Order 12
(12,19,1, 199.00, 0.00, 199.00),
(12,23,1, 189.00, 5.00, 179.55);

-- ─────────────────────────────────────────
--  REVIEWS
-- ─────────────────────────────────────────
INSERT INTO reviews (order_id, user_id, restaurant_id, rider_id, food_rating, delivery_rating, comment) VALUES
(1, 1, 1, 1, 5, 5, 'Biryani was amazing! Rider was super fast.'),
(2, 2, 2, 2, 4, 4, 'Great pizza, slightly late delivery but worth it.'),
(3, 3, 3, 1, 5, 4, 'Best smash burger in town! Will order again.'),
(4, 4, 4, 2, 4, 5, 'Dimsums were fresh and delicious. Quick delivery!'),
(5, 5, 1, 1, 3, 4, 'Veg biryani was a bit dry. Masala chai was good.'),
(6, 1, 2, 2, 5, 5, 'BBQ Chicken pizza was outstanding! Perfect crust.'),
(7, 2, 3, 1, 4, 3, 'Good burger. Delivery took a bit long.'),
(8, 3, 4, 2, 5, 5, 'Chilli chicken was the best. Will definitely reorder!');

-- ─────────────────────────────────────────
--  PAYMENTS
-- ─────────────────────────────────────────
INSERT INTO payments (order_id, transaction_ref, method, amount, status, paid_at) VALUES
(1,  'TXN20241101001', 'upi',    334.82, 'success', '2024-11-01 12:11:00'),
(2,  'TXN20241102001', 'card',   424.91, 'success', '2024-11-02 19:06:00'),
(3,  NULL,             'cash',   591.82, 'success', '2024-11-03 13:52:00'),
(4,  'TXN20241104001', 'wallet', 367.31, 'success', '2024-11-04 20:31:00'),
(5,  'TXN20241105001', 'upi',    368.42, 'success', '2024-11-05 14:11:00'),
(6,  'TXN20241106001', 'card',   459.82, 'success', '2024-11-06 18:01:00'),
(7,  'TXN20241107001', 'upi',    328.91, 'success', '2024-11-07 21:11:00'),
(8,  NULL,             'cash',   404.80, 'success', '2024-11-08 12:51:00'),
(9,  'TXN20241109001', 'upi',    481.80, 'pending', NULL),
(10, 'TXN20241110001', 'card',   385.00, 'success', NOW()),
(11, NULL,             'cash',   591.82, 'pending', NULL),
(12, 'TXN20241112001', 'wallet', 447.31, 'refunded',NOW());

-- ─────────────────────────────────────────
--  ORDER STATUS HISTORY
-- ─────────────────────────────────────────
INSERT INTO order_status_history (order_id, status, note, changed_at) VALUES
(1, 'placed',     'Order placed by customer',           '2024-11-01 12:10:00'),
(1, 'confirmed',  'Restaurant confirmed order',         '2024-11-01 12:12:00'),
(1, 'preparing',  'Kitchen started preparation',        '2024-11-01 12:15:00'),
(1, 'picked_up',  'Rider picked up order',              '2024-11-01 12:28:00'),
(1, 'delivered',  'Order delivered successfully',       '2024-11-01 12:45:00'),
(12,'placed',     'Order placed by customer',           NOW()),
(12,'cancelled',  'Customer requested cancellation',    NOW());

-- ─────────────────────────────────────────
--  NOTIFICATIONS
-- ─────────────────────────────────────────
INSERT INTO notifications (user_id, order_id, type, title, message) VALUES
(1, 1,  'order_update', 'Order Delivered! 🎉',   'Your Chicken Biryani from Spice Garden has been delivered. Enjoy!'),
(2, 2,  'order_update', 'Order on the way! 🛵',  'Your order from Pizza Paradise has been picked up and is heading your way.'),
(4, 9,  'order_update', 'Order Confirmed ✅',     'Spice Garden confirmed your order. Preparing now!'),
(1, NULL,'promo',       'Weekend Special! 🎊',    'Get 30% off this weekend. Use code WEEKEND30.'),
(3, NULL,'promo',       'New on the app 🍔',      'Burger Barn just joined! Check out their gourmet smash burgers.');
