CREATE DATABASE ecommerce_db;

-- Customers / Users
CREATE TABLE customers (
id BIGINT UNSIGNEDcustomers AUTO_INCREMENT,
firstName VARCHAR(100) NOT NULL,
lastName VARCHAR(100) NOT NULL,
email VARCHAR(255) NOT NULL,
 phone VARCHAR(40) DEFAULT NULL,
password_hash VARCHAR(255) NOT NULL,
is_active TINYINT(1) NOT NULL DEFAULT 1,
created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
PRIMARY KEY (id),
UNIQUE KEY `uq_customers_email` (email)
) ;

-- One-to-one : customer profile
CREATE TABLE `customer_profiles` (
customer_id BIGINT UNSIGNED NOT NULL,
birthday DATE DEFAULT NULL,
gender ENUM('male','female','non_binary','other') DEFAULT NULL,
loyalty_points INT NOT NULL DEFAULT 0,
notes TEXT DEFAULT NULL,
PRIMARY KEY (`customer_id`),
CONSTRAINT fk_profile_customer FOREIGN KEY (`customer_id`) REFERENCES `customers`(id) 
);

-- Addresses (one customer -> many addresses)
CREATE TABLE addresses(
id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
customer_id BIGINT UNSIGNED NOT NULL,
label VARCHAR(50) DEFAULT 'home', 
line1 VARCHAR(255) NOT NULL,
line2 VARCHAR(255) DEFAULT NULL,
city VARCHAR(100) NOT NULL,
state VARCHAR(100) DEFAULT NULL,
postal_code VARCHAR(30) DEFAULT NULL,
country VARCHAR(100) NOT NULL,
is_default TINYINT(1) NOT NULL DEFAULT 0,
created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
PRIMARY KEY (id),
INDEX idx_addresses_customer (customer_id),
CONSTRAINT fk_addresses_customer FOREIGN KEY (customer_id) REFERENCES customers(id)
);


CREATE TABLE categories (
id INT UNSIGNED NOT NULL AUTO_INCREMENT,
name VARCHAR(150) NOT NULL,
slug VARCHAR(180) NOT NULL,
description TEXT DEFAULT NULL,
parent_id INT UNSIGNED DEFAULT NULL,
created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
PRIMARY KEY (id),
UNIQUE KEY `uq_categories_slug` (`slug`),
CONSTRAINT `fk_categories_parent` FOREIGN KEY (`parent_id`) REFERENCES `categories`(`id`)
) ;

-- Suppliers
CREATE TABLE suppliers (
id INT UNSIGNED NOT NULL AUTO_INCREMENT,
name VARCHAR(200) NOT NULL,
contact_name VARCHAR(200) DEFAULT NULL,
contact_email VARCHAR(255) DEFAULT NULL,
phone VARCHAR(50) DEFAULT NULL,
created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
PRIMARY KEY (`id`)
) ;

-- Warehouses (for inventory tracking)
CREATE TABLE `warehouses` (
id INT UNSIGNED NOT NULL AUTO_INCREMENT,
name VARCHAR(200) NOT NULL,
address VARCHAR(300) DEFAULT NULL,
is_active TINYINT(1) NOT NULL DEFAULT 1,
PRIMARY KEY (`id`),
UNIQUE KEY `uq_warehouses_name` (`name`)
) ;


-- Products
CREATE TABLE products (
id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
sku VARCHAR(100) NOT NULL,
name VARCHAR(255) NOT NULL,
short_description VARCHAR(512) DEFAULT NULL,
description TEXT DEFAULT NULL,
price DECIMAL(12,2) NOT NULL DEFAULT 0.00,
currency CHAR(3) NOT NULL DEFAULT 'USD',
is_active TINYINT(1) NOT NULL DEFAULT 1,
created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
PRIMARY KEY (`id`),
UNIQUE KEY `uq_products_sku` (`sku`)
) ;


-- Product images (one-to-many)
CREATE TABLE `product_images` (
`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
`product_id` BIGINT UNSIGNED NOT NULL,
`url` VARCHAR(1000) NOT NULL,
`alt_text` VARCHAR(255) DEFAULT NULL,
`sort_order` INT NOT NULL DEFAULT 0,
PRIMARY KEY (`id`),
INDEX `idx_product_images_product` (`product_id`),
CONSTRAINT `fk_product_images_product` FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ;

-- Product Category (many-to-many)
CREATE TABLE `product_categories` (
`product_id` BIGINT UNSIGNED NOT NULL,
`category_id` INT UNSIGNED NOT NULL,
PRIMARY KEY (`product_id`,`category_id`),
INDEX `idx_pc_category` (`category_id`),
CONSTRAINT `fk_pc_product` FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
CONSTRAINT `fk_pc_category` FOREIGN KEY (`category_id`) REFERENCES `categories`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE `orders` (
`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
`order_number` VARCHAR(50) NOT NULL,
`customer_id` BIGINT UNSIGNED NOT NULL,
`billing_address_id` BIGINT UNSIGNED DEFAULT NULL,
`shipping_address_id` BIGINT UNSIGNED DEFAULT NULL,
`status` ENUM('pending','paid','processing','shipped','delivered','cancelled','refunded') NOT NULL DEFAULT 'pending',
`subtotal` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
`shipping_cost` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
`tax` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
`discount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
`total` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
`placed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
PRIMARY KEY (`id`),
UNIQUE KEY `uq_orders_number` (`order_number`),
INDEX `idx_orders_customer` (`customer_id`),
CONSTRAINT `fk_orders_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
CONSTRAINT `fk_orders_billing_address` FOREIGN KEY (`billing_address_id`) REFERENCES `addresses`(`id`) ON DELETE SET NULL ON UPDATE CASCADE,
CONSTRAINT `fk_orders_shipping_address` FOREIGN KEY (`shipping_address_id`) REFERENCES `addresses`(`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ;

-- Inventory per warehouse (composite PK)
CREATE TABLE inventory(
`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
`order_id` BIGINT UNSIGNED NOT NULL,
`payment_method` VARCHAR(100) NOT NULL,
`transaction_id` VARCHAR(255) DEFAULT NULL,
`amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
`currency` CHAR(3) NOT NULL DEFAULT 'KSH',
`status` ENUM('initiated','success','failed','refunded') NOT NULL DEFAULT 'initiated',
`paid_at` TIMESTAMP NULL DEFAULT NULL,
PRIMARY KEY (`id`),
INDEX `idx_payments_order` (`order_id`),
CONSTRAINT `fk_payments_order` FOREIGN KEY (`order_id`) REFERENCES `orders`(`id`) 
) ;

-- Order items (many-to-many with extra attributes) between orders and products
CREATE TABLE `order_items` (
`order_id` BIGINT UNSIGNED NOT NULL,
`product_id` BIGINT UNSIGNED NOT NULL,
`qty` INT UNSIGNED NOT NULL DEFAULT 1,
`unit_price` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
`row_total` DECIMAL(12,2) GENERATED ALWAYS  AS (`qty` * `unit_price`) STORED,
PRIMARY KEY (`order_id`,`product_id`),
CONSTRAINT `fk_oi_order` FOREIGN KEY (`order_id`) REFERENCES `orders`(`id`),
CONSTRAINT `fk_oi_product` FOREIGN KEY (`product_id`) REFERENCES `products`(`id`)
) ;

-- Shipments (an order can have multiple shipments)
CREATE TABLE `shipments` (
`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
`order_id` BIGINT UNSIGNED NOT NULL,
`warehouse_id` INT UNSIGNED DEFAULT NULL,
`tracking_number` VARCHAR(255) DEFAULT NULL,
`carrier` VARCHAR(100) DEFAULT NULL,
`status` ENUM('pending','shipped','in_transit','delivered','returned') NOT NULL DEFAULT 'pending',
`shipped_at` TIMESTAMP NULL DEFAULT NULL,
PRIMARY KEY (`id`),
INDEX `idx_shipments_order` (`order_id`),
CONSTRAINT `fk_shipments_order` FOREIGN KEY (`order_id`) REFERENCES `orders`(`id`),
CONSTRAINT `fk_shipments_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses`(`id`) 
) ;

-- Payments (one order -> many payments possible)
CREATE TABLE `payments` (
id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
order_id BIGINT UNSIGNED NOT NULL,
payment_method VARCHAR(100) NOT NULL,
transaction_id VARCHAR(255) DEFAULT NULL,
amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
currency CHAR(3) NOT NULL DEFAULT 'KES',
status ENUM('initiated','success','failed','refunded') NOT NULL DEFAULT 'initiated',
paid_at TIMESTAMP NULL DEFAULT NULL,
PRIMARY KEY (id)
) ;

-- Roles and user roles (example of many-to-many for admin/employee functionality)
CREATE TABLE `roles` (
`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
`name` VARCHAR(100) NOT NULL,
`description` VARCHAR(255) DEFAULT NULL,
PRIMARY KEY (`id`),
UNIQUE KEY `uq_roles_name` (`name`)
) ;


CREATE TABLE `customer_roles` (
`customer_id` BIGINT UNSIGNED NOT NULL,
`role_id` INT UNSIGNED NOT NULL,
PRIMARY KEY (`customer_id`, `role_id`),
CONSTRAINT `fk_cr_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
CONSTRAINT `fk_cr_role` FOREIGN KEY (`role_id`) REFERENCES `roles`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ;
