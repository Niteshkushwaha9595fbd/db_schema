-- ==============================================================
-- Database Schema & Seed Data Deployment Script
-- Target Database : PostgreSQL (mydb)
-- Description     : Idempotent table creation and details entry
-- ==============================================================

-- 1. Migration History Table
CREATE TABLE IF NOT EXISTS schema_migrations (
    id SERIAL PRIMARY KEY,
    migration_name VARCHAR(150) NOT NULL UNIQUE,
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) DEFAULT 'SUCCESS',
    details TEXT
);

-- 2. Departments Table
CREATE TABLE IF NOT EXISTS departments (
    id SERIAL PRIMARY KEY,
    dept_code VARCHAR(20) NOT NULL UNIQUE,
    dept_name VARCHAR(100) NOT NULL UNIQUE,
    location VARCHAR(150) NOT NULL,
    budget NUMERIC(12, 2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Job Roles Table
CREATE TABLE IF NOT EXISTS roles (
    id SERIAL PRIMARY KEY,
    role_title VARCHAR(100) NOT NULL UNIQUE,
    job_level VARCHAR(50) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Employees Table (Create if not exists)
CREATE TABLE IF NOT EXISTS employees (
    id SERIAL PRIMARY KEY,
    employee_code VARCHAR(20) UNIQUE,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(150) UNIQUE,
    phone VARCHAR(20),
    department_id INT REFERENCES departments(id) ON DELETE SET NULL,
    role_id INT REFERENCES roles(id) ON DELETE SET NULL,
    salary NUMERIC(10, 2) DEFAULT 0.00,
    hire_date DATE DEFAULT CURRENT_DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Backward compatibility / schema upgrade for existing tables
DO $$ 
BEGIN
    -- Add columns if missing from earlier table versions
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='employees' AND column_name='employee_code') THEN
        ALTER TABLE employees ADD COLUMN employee_code VARCHAR(20);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='employees' AND column_name='first_name') THEN
        ALTER TABLE employees ADD COLUMN first_name VARCHAR(50);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='employees' AND column_name='last_name') THEN
        ALTER TABLE employees ADD COLUMN last_name VARCHAR(50);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='employees' AND column_name='phone') THEN
        ALTER TABLE employees ADD COLUMN phone VARCHAR(20);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='employees' AND column_name='department_id') THEN
        ALTER TABLE employees ADD COLUMN department_id INT REFERENCES departments(id) ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='employees' AND column_name='role_id') THEN
        ALTER TABLE employees ADD COLUMN role_id INT REFERENCES roles(id) ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='employees' AND column_name='hire_date') THEN
        ALTER TABLE employees ADD COLUMN hire_date DATE DEFAULT CURRENT_DATE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='employees' AND column_name='is_active') THEN
        ALTER TABLE employees ADD COLUMN is_active BOOLEAN DEFAULT TRUE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='employees' AND column_name='created_at') THEN
        ALTER TABLE employees ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='employees' AND column_name='updated_at') THEN
        ALTER TABLE employees ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
    END IF;
END $$;

-- Adjust column types/nullability safely
ALTER TABLE employees ALTER COLUMN email TYPE VARCHAR(150);
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='employees' AND column_name='name' AND is_nullable='NO') THEN
        ALTER TABLE employees ALTER COLUMN name DROP NOT NULL;
    END IF;
END $$;

-- Ensure Unique Constraints and Indexes
CREATE UNIQUE INDEX IF NOT EXISTS idx_employees_code ON employees(employee_code);
CREATE INDEX IF NOT EXISTS idx_employees_email ON employees(email);
CREATE INDEX IF NOT EXISTS idx_employees_dept ON employees(department_id);
CREATE INDEX IF NOT EXISTS idx_employees_role ON employees(role_id);

-- ==============================================================
-- DATA INSERTION (DETAILS ENTRY)
-- ==============================================================

-- 1. Insert Departments
INSERT INTO departments (dept_code, dept_name, location, budget)
VALUES 
    ('DEV',  'DevOps & Cloud',       'Bangalore', 500000.00),
    ('ENG',  'Software Engineering', 'Hyderabad', 750000.00),
    ('DBA',  'Database Management',  'Pune',      350000.00),
    ('QA',   'Quality Assurance',    'Noida',     250000.00),
    ('HR',   'Human Resources',      'Gurgaon',   150000.00)
ON CONFLICT (dept_code) DO UPDATE 
SET dept_name = EXCLUDED.dept_name,
    location  = EXCLUDED.location,
    budget    = EXCLUDED.budget;

-- 2. Insert Job Roles
INSERT INTO roles (role_title, job_level, description)
VALUES
    ('Senior DevOps Engineer',    'Lead',   'Infrastructure automation, CI/CD pipelines, and Kubernetes'),
    ('PostgreSQL Database Admin', 'Senior', 'Database clustering, backup automation, and query optimization'),
    ('Full Stack Developer',      'Mid',    'Backend microservices and frontend user interfaces'),
    ('QA Automation Engineer',    'Mid',    'Selenium, Playwright and API test automation'),
    ('Cloud Security Architect',  'Staff',  'Cloud governance, IAM policy and security compliance')
ON CONFLICT (role_title) DO NOTHING;

-- 3. Insert Employees Details
INSERT INTO employees (employee_code, first_name, last_name, email, phone, department_id, role_id, salary, hire_date, is_active)
VALUES 
    ('EMP001', 'Nitesh',  'Kushwaha', 'nitesh.kushwaha@example.com', '+91-9876543210', 1, 1, 95000.00, '2023-01-15', TRUE),
    ('EMP002', 'Aarav',   'Sharma',   'aarav.sharma@example.com',   '+91-9876543211', 2, 3, 80000.00, '2023-03-20', TRUE),
    ('EMP003', 'Priya',   'Verma',    'priya.verma@example.com',    '+91-9876543212', 3, 2, 85000.00, '2023-05-10', TRUE),
    ('EMP004', 'Rohan',   'Gupta',    'rohan.gupta@example.com',    '+91-9876543213', 4, 4, 70000.00, '2023-08-01', TRUE),
    ('EMP005', 'Ananya',  'Patel',    'ananya.patel@example.com',   '+91-9876543214', 5, 5, 90000.00, '2024-01-10', TRUE)
ON CONFLICT (employee_code) DO UPDATE
SET first_name = EXCLUDED.first_name,
    last_name  = EXCLUDED.last_name,
    salary     = EXCLUDED.salary,
    is_active  = EXCLUDED.is_active,
    updated_at = CURRENT_TIMESTAMP;

-- 4. Log migration entry
INSERT INTO schema_migrations (migration_name, status, details)
VALUES ('V1_initial_schema_deployment', 'SUCCESS', 'Created departments, roles, employees tables with initial seed data')
ON CONFLICT (migration_name) DO UPDATE
SET applied_at = CURRENT_TIMESTAMP,
    status = 'SUCCESS';

-- ==============================================================
-- VERIFICATION REPORT (Output shown in Jenkins logs)
-- ==============================================================
SELECT 'Departments: ' || count(*)::text FROM departments
UNION ALL
SELECT 'Roles: ' || count(*)::text FROM roles
UNION ALL
SELECT 'Employees: ' || count(*)::text FROM employees;
