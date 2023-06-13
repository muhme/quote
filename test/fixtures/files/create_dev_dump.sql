-- Create development dump from production dump
-- . clean all sensitive fields and not needed user entries
-- . add users user/user_password, admin/admin_password and super_admin/super_admin

-- Begin Transaction
BEGIN;

-- Delete users with no entries in quotations and comments
DELETE FROM users 
WHERE id NOT IN (
  SELECT user_id FROM quotations 
  UNION 
  SELECT user_id FROM comments
);

-- Clean specified columns
UPDATE users 
SET email = NULL, 
    crypted_password = NULL, 
    password_salt = NULL, 
    persistence_token = NULL,
    last_login_at = NULL,
    perishable_token = "XXX";

-- Insert new users
INSERT INTO users (login, crypted_password, password_salt, active, approved, confirmed, admin, super_admin, email, created_at, updated_at) 
VALUES 
('user', '400$8$59$cfc992b438ad2e47$b310841feee31f8104abf5dbedc17cfdb6f4e44956a6cde170ac9dd83cbf0e76', 'x0bwgYQk5lLxJ56lojgP', 1, 1, 1, 0, 0, 'user@user.com', NOW(), NOW()),
('admin', '400$8$59$c0dd1d728d7ef508$0bf6091960972a299d416ecac1fc957929b34b5997e893e036ca07da333316ea', '5LPGOsVaddwj2jsalWc0', 1, 1, 1, 1, 0, 'admin@admin.com', NOW(), NOW()),
('super_admin', '400$8$59$56cfc117c02e86b6$5be5e050a8758e2f1882da26151f58e7bd673d4e5671dee0b67152893424a049', 'tgqc6jyAvrxFS7oYdLFq', 1, 1, 1, 1, 1, 'super_admin@admin.com', NOW(), NOW());

-- Update timestamps
UPDATE users 
SET created_at = NOW(), 
    updated_at = NOW();

-- Commit Transaction
COMMIT;
