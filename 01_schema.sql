-- ============================================================
--  FOOD DELIVERY PLATFORM DATABASE
--  File: 01_schema.sql
--  Description: Core table definitions
-- ============================================================

CREATE DATABASE IF NOT EXISTS food_delivery_db;
USE food_delivery_db;

-- ─────────────────────────────────────────
--  USERS
-- ─────────────────────────────────────────
CREATE TABLE users (
    user_id       INT AUTO_INCREMENT PRIMARY KEY,
    full_name     VARCHAR(100) NOT NULL,
    email         VARCHAR(150) NOT NULL UNIQUE,
    phone         VARCHAR(20)  NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role          ENUM('customer','rider','admin') NOT NULL DEFAULT 'customer',
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ─────────────────────────────────────────
--  CUSTOMER ADDRESSES
-- ─────────────────────────────────────────
CREATE TABLE addresses (
    address_id   INT AUTO_INCREMENT PRIMARY KEY,
    user_id      INT NOT NULL,
    label        VARCHAR(50) NOT NULL DEFAULT 'Home',
    address_line VARCHAR(255) NOT NULL,
    city         VARCHAR(100) NOT NULL,
    state        VARCHAR(100) NOT NULL,
    pincode      VARCHAR(10)  NOT NULL,
    latitude     DECIMAL(10,7),
    longitude    DECIMAL(10,7),
    is_default   BOOLEAN NOT NULL DEFAULT FALSE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- ─────────────────────────────────────────
--  RESTAURANTS
-- ─────────────────────────────────────────
CREATE TABLE restaurants (
    restaurant_id   INT AUTO_INCREMENT PRIMARY KEY,
    owner_id        INT NOT NULL,
    name            VARCHAR(150) NOT NULL,
    description     TEXT,
    cuisine_type    VARCHAR(100) NOT NULL,
    address_line    VARCHAR(255) NOT NULL,
    city            VARCHAR(100) NOT NULL,
    state           VARCHAR(100) NOT NULL,
    pincode         VARCHAR(10)  NOT NULL,
    latitude        DECIMAL(10,7),
    longitude       DECIMAL(10,7),
    phone           VARCHAR(20),
    email           VARCHAR(150),
    opening_time    TIME NOT NULL DEFAULT '09:00:00',
    closing_time    TIME NOT NULL DEFAULT '22:00:00',
    avg_rating      DECIMAL(3,2) NOT NULL DEFAULT 0.00,
    total_reviews   INT NOT NULL DEFAULT 0,
    delivery_radius DECIMAL(5,2) NOT NULL DEFAULT 5.00,  -- in km
    min_order_amt   DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    is_verified     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (owner_id) REFERENCES users(user_id)
);

-- ─────────────────────────────────────────
--  CATEGORIES
-- ─────────────────────────────────────────
CREATE TABLE categories (
    category_id   INT AUTO_INCREMENT PRIMARY KEY,
    name          VARCHAR(100) NOT NULL UNIQUE,
    description   TEXT,
    icon_url      VARCHAR(255)
);

-- ─────────────────────────────────────────
--  MENU ITEMS
-- ─────────────────────────────────────────
CREATE TABLE menu_items (
    item_id       INT AUTO_INCREMENT PRIMARY KEY,
    restaurant_id INT NOT NULL,
    category_id   INT,
    name          VARCHAR(150) NOT NULL,
    description   TEXT,
    price         DECIMAL(10,2) NOT NULL,
    discount_pct  DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    image_url     VARCHAR(255),
    is_veg        BOOLEAN NOT NULL DEFAULT TRUE,
    is_available  BOOLEAN NOT NULL DEFAULT TRUE,
    calories      INT,
    prep_time_min INT NOT NULL DEFAULT 15,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id) ON DELETE CASCADE,
    FOREIGN KEY (category_id)   REFERENCES categories(category_id) ON DELETE SET NULL
);

-- ─────────────────────────────────────────
--  RIDERS
-- ─────────────────────────────────────────
CREATE TABLE riders (
    rider_id        INT AUTO_INCREMENT PRIMARY KEY,
    user_id         INT NOT NULL UNIQUE,
    vehicle_type    ENUM('bike','bicycle','scooter','car') NOT NULL DEFAULT 'bike',
    vehicle_number  VARCHAR(20),
    license_number  VARCHAR(50),
    is_available    BOOLEAN NOT NULL DEFAULT TRUE,
    current_lat     DECIMAL(10,7),
    current_lng     DECIMAL(10,7),
    total_deliveries INT NOT NULL DEFAULT 0,
    avg_rating      DECIMAL(3,2) NOT NULL DEFAULT 0.00,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- ─────────────────────────────────────────
--  COUPONS
-- ─────────────────────────────────────────
CREATE TABLE coupons (
    coupon_id       INT AUTO_INCREMENT PRIMARY KEY,
    code            VARCHAR(30) NOT NULL UNIQUE,
    description     TEXT,
    discount_type   ENUM('flat','percentage') NOT NULL DEFAULT 'flat',
    discount_value  DECIMAL(10,2) NOT NULL,
    min_order_amt   DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    max_discount    DECIMAL(10,2),
    usage_limit     INT NOT NULL DEFAULT 1,
    used_count      INT NOT NULL DEFAULT 0,
    valid_from      DATETIME NOT NULL,
    valid_until     DATETIME NOT NULL,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE
);

-- ─────────────────────────────────────────
--  ORDERS
-- ─────────────────────────────────────────
CREATE TABLE orders (
    order_id        INT AUTO_INCREMENT PRIMARY KEY,
    user_id         INT NOT NULL,
    restaurant_id   INT NOT NULL,
    rider_id        INT,
    address_id      INT NOT NULL,
    coupon_id       INT,
    status          ENUM(
                        'placed','confirmed','preparing',
                        'ready','picked_up','on_the_way',
                        'delivered','cancelled','refunded'
                    ) NOT NULL DEFAULT 'placed',
    subtotal        DECIMAL(10,2) NOT NULL,
    discount_amt    DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    delivery_fee    DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    tax_amt         DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    total_amt       DECIMAL(10,2) NOT NULL,
    payment_method  ENUM('cash','card','upi','wallet') NOT NULL DEFAULT 'cash',
    payment_status  ENUM('pending','paid','failed','refunded') NOT NULL DEFAULT 'pending',
    special_note    TEXT,
    estimated_time  INT,                          -- minutes
    placed_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    delivered_at    DATETIME,
    cancelled_at    DATETIME,
    cancel_reason   TEXT,
    FOREIGN KEY (user_id)       REFERENCES users(user_id),
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id),
    FOREIGN KEY (rider_id)      REFERENCES riders(rider_id) ON DELETE SET NULL,
    FOREIGN KEY (address_id)    REFERENCES addresses(address_id),
    FOREIGN KEY (coupon_id)     REFERENCES coupons(coupon_id) ON DELETE SET NULL
);

-- ─────────────────────────────────────────
--  ORDER ITEMS
-- ─────────────────────────────────────────
CREATE TABLE order_items (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id      INT NOT NULL,
    item_id       INT NOT NULL,
    quantity      INT NOT NULL DEFAULT 1,
    unit_price    DECIMAL(10,2) NOT NULL,
    discount_pct  DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    subtotal      DECIMAL(10,2) NOT NULL,
    special_note  TEXT,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (item_id)  REFERENCES menu_items(item_id)
);

-- ─────────────────────────────────────────
--  ORDER STATUS HISTORY (audit trail)
-- ─────────────────────────────────────────
CREATE TABLE order_status_history (
    history_id  INT AUTO_INCREMENT PRIMARY KEY,
    order_id    INT NOT NULL,
    status      VARCHAR(50) NOT NULL,
    changed_by  INT,
    note        TEXT,
    changed_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id)   REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (changed_by) REFERENCES users(user_id) ON DELETE SET NULL
);

-- ─────────────────────────────────────────
--  REVIEWS
-- ─────────────────────────────────────────
CREATE TABLE reviews (
    review_id       INT AUTO_INCREMENT PRIMARY KEY,
    order_id        INT NOT NULL UNIQUE,
    user_id         INT NOT NULL,
    restaurant_id   INT NOT NULL,
    rider_id        INT,
    food_rating     TINYINT NOT NULL CHECK (food_rating BETWEEN 1 AND 5),
    delivery_rating TINYINT CHECK (delivery_rating BETWEEN 1 AND 5),
    comment         TEXT,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id)      REFERENCES orders(order_id),
    FOREIGN KEY (user_id)       REFERENCES users(user_id),
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id),
    FOREIGN KEY (rider_id)      REFERENCES riders(rider_id) ON DELETE SET NULL
);

-- ─────────────────────────────────────────
--  PAYMENTS
-- ─────────────────────────────────────────
CREATE TABLE payments (
    payment_id      INT AUTO_INCREMENT PRIMARY KEY,
    order_id        INT NOT NULL UNIQUE,
    transaction_ref VARCHAR(100),
    method          ENUM('cash','card','upi','wallet') NOT NULL,
    amount          DECIMAL(10,2) NOT NULL,
    status          ENUM('pending','success','failed','refunded') NOT NULL DEFAULT 'pending',
    gateway_response TEXT,
    paid_at         DATETIME,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- ─────────────────────────────────────────
--  NOTIFICATIONS
-- ─────────────────────────────────────────
CREATE TABLE notifications (
    notif_id    INT AUTO_INCREMENT PRIMARY KEY,
    user_id     INT NOT NULL,
    order_id    INT,
    type        ENUM('order_update','promo','system') NOT NULL DEFAULT 'order_update',
    title       VARCHAR(150) NOT NULL,
    message     TEXT NOT NULL,
    is_read     BOOLEAN NOT NULL DEFAULT FALSE,
    sent_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id)  REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE SET NULL
);

-- ─────────────────────────────────────────
--  INDEXES FOR PERFORMANCE
-- ─────────────────────────────────────────
CREATE INDEX idx_orders_user        ON orders(user_id);
CREATE INDEX idx_orders_restaurant  ON orders(restaurant_id);
CREATE INDEX idx_orders_status      ON orders(status);
CREATE INDEX idx_orders_placed_at   ON orders(placed_at);
CREATE INDEX idx_menu_restaurant    ON menu_items(restaurant_id);
CREATE INDEX idx_menu_category      ON menu_items(category_id);
CREATE INDEX idx_reviews_restaurant ON reviews(restaurant_id);
CREATE INDEX idx_riders_available   ON riders(is_available);
