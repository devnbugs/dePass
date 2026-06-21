-- dePass MySQL Database Setup
-- Run: mysql -u root -p < database/mysql_setup.sql

CREATE DATABASE IF NOT EXISTS depass
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS 'depass'@'localhost' IDENTIFIED BY 'depass_secret_2026';
GRANT ALL PRIVILEGES ON depass.* TO 'depass'@'localhost';

-- For production, use a strong password and restrict host
-- CREATE USER IF NOT EXISTS 'depass'@'%' IDENTIFIED BY 'your_strong_password';
-- GRANT ALL PRIVILEGES ON depass.* TO 'depass'@'%';

FLUSH PRIVILEGES;
