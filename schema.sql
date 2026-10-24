-- ==============================================================================
-- DATABASE SCHEMA & DUMMY DATA DEPLOYMENT SCRIPT
-- Target Database : PostgreSQL (mydb)
-- Purpose         : Automated Table Creation & Production-Grade Dummy Data Insertion
-- Idempotent      : Safe for repeated CI/CD pipeline deployments
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. MIGRATION TRACKING TABLE
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS schema_migrations (
    id SERIAL PRIMARY KEY,
    migration_name VARCHAR(150) NOT NULL UNIQUE,
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) DEFAULT 'SUCCESS',
    details TEXT
);

-- ------------------------------------------------------------------------------
-- 2. DEPARTMENTS TABLE
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS departments (
    id SERIAL PRIMARY KEY,
    dept_code VARCHAR(20) NOT NULL UNIQUE,
    dept_name VARCHAR(100) NOT NULL UNIQUE,
    location VARCHAR(150) NOT NULL,
    budget NUMERIC(12, 2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------------------------
-- 3. JOB ROLES TABLE
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS roles (
    id SERIAL PRIMARY KEY,
    role_title VARCHAR(100) NOT NULL UNIQUE,
    job_level VARCHAR(50) NOT NULL,
    description TEXT,
    min_salary NUMERIC(10, 2) DEFAULT 30000.00,
    max_salary NUMERIC(10, 2) DEFAULT 250000.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE roles ADD COLUMN IF NOT EXISTS min_salary NUMERIC(10, 2) DEFAULT 30000.00;
ALTER TABLE roles ADD COLUMN IF NOT EXISTS max_salary NUMERIC(10, 2) DEFAULT 250000.00;

-- ------------------------------------------------------------------------------
-- 4. EMPLOYEES TABLE
-- ------------------------------------------------------------------------------
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

-- Backward compatibility & safety for existing employees table
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'employees_pkey') THEN
        ALTER TABLE employees ADD CONSTRAINT employees_pkey PRIMARY KEY (id);
    END IF;
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
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='employees' AND column_name='name' AND is_nullable='NO') THEN
        ALTER TABLE employees ALTER COLUMN name DROP NOT NULL;
    END IF;
END $$;

ALTER TABLE employees ALTER COLUMN email TYPE VARCHAR(150);
CREATE UNIQUE INDEX IF NOT EXISTS idx_employees_code ON employees(employee_code);

-- ------------------------------------------------------------------------------
-- 5. PROJECTS TABLE
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS projects (
    id SERIAL PRIMARY KEY,
    project_code VARCHAR(20) NOT NULL UNIQUE,
    project_name VARCHAR(150) NOT NULL,
    client_name VARCHAR(150) NOT NULL,
    budget NUMERIC(12, 2) NOT NULL DEFAULT 100000.00,
    start_date DATE DEFAULT CURRENT_DATE,
    end_date DATE,
    status VARCHAR(50) DEFAULT 'IN_PROGRESS',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------------------------
-- 6. PROJECT ASSIGNMENTS (Many-to-Many Linking Table)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS project_assignments (
    id SERIAL PRIMARY KEY,
    project_id INT REFERENCES projects(id) ON DELETE CASCADE,
    employee_id INT REFERENCES employees(id) ON DELETE CASCADE,
    role_in_project VARCHAR(100) NOT NULL,
    assigned_date DATE DEFAULT CURRENT_DATE,
    hours_allocated INT DEFAULT 40,
    CONSTRAINT uq_proj_emp UNIQUE (project_id, employee_id)
);

-- ------------------------------------------------------------------------------
-- 7. PERFORMANCE INDEXES
-- ------------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_emp_email ON employees(email);
CREATE INDEX IF NOT EXISTS idx_emp_dept ON employees(department_id);
CREATE INDEX IF NOT EXISTS idx_emp_role ON employees(role_id);
CREATE INDEX IF NOT EXISTS idx_proj_status ON projects(status);
CREATE INDEX IF NOT EXISTS idx_assign_proj ON project_assignments(project_id);
CREATE INDEX IF NOT EXISTS idx_assign_emp ON project_assignments(employee_id);

-- ==============================================================================
-- DUMMY DETAILS / SEED DATA ENTRY (IDEMPOTENT VIA ON CONFLICT)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- A. INSERT DEPARTMENTS (8 Records)
-- ------------------------------------------------------------------------------
INSERT INTO departments (dept_code, dept_name, location, budget)
VALUES 
    ('DEV',   'DevOps & Cloud Engineering',     'Bangalore, India', 850000.00),
    ('ENG',   'Software Product Engineering',   'Hyderabad, India', 1200000.00),
    ('DATA',  'Artificial Intelligence & Data',  'Pune, India',      950000.00),
    ('DBA',   'Database Platform Engineering',  'Bangalore, India', 600000.00),
    ('SEC',   'Cyber Security & Compliance',    'Noida, India',     500000.00),
    ('QA',    'Quality Assurance & Testing',    'Pune, India',      400000.00),
    ('PROD',  'Product Management & UX',        'Gurgaon, India',   550000.00),
    ('HR',    'Human Resources & Talent',       'Mumbai, India',    300000.00)
ON CONFLICT (dept_code) DO UPDATE 
SET dept_name = EXCLUDED.dept_name,
    location  = EXCLUDED.location,
    budget    = EXCLUDED.budget;

-- ------------------------------------------------------------------------------
-- B. INSERT JOB ROLES (10 Records)
-- ------------------------------------------------------------------------------
INSERT INTO roles (role_title, job_level, description, min_salary, max_salary)
VALUES
    ('Principal DevOps Architect',    'Staff',     'Cloud architecture, Kubernetes clusters, and CI/CD pipelines', 140000, 220000),
    ('Senior DevOps Engineer',         'Senior',    'Terraform, Ansible, Jenkins automation, and Linux administration', 95000, 150000),
    ('PostgreSQL Database Architect',  'Staff',     'PostgreSQL tuning, high availability clusters, and replication', 130000, 200000),
    ('Database Administrator (DBA)',   'Mid',       'Database backups, migration pipelines, and performance tuning', 75000, 120000),
    ('Lead Full Stack Engineer',       'Lead',      'React, Node.js, Spring Boot microservices, and system design', 120000, 180000),
    ('Senior Backend Developer',       'Senior',    'Distributed systems, REST APIs, and database integration', 90000, 140000),
    ('Machine Learning Engineer',      'Senior',    'Predictive models, deep learning pipelines, and MLOps', 105000, 160000),
    ('Cyber Security Specialist',      'Senior',    'Vulnerability assessment, pen-testing, and IAM compliance', 95000, 150000),
    ('QA Automation Lead',             'Lead',      'Playwright, Selenium, and CI/CD integration testing', 85000, 130000),
    ('Technical Product Manager',      'Principal', 'Product strategy, roadmap delivery, and client engagement', 125000, 190000)
ON CONFLICT (role_title) DO UPDATE
SET description = EXCLUDED.description,
    job_level   = EXCLUDED.job_level;

-- ------------------------------------------------------------------------------
-- C. INSERT EMPLOYEES DETAILS (15 Dummy Records)
-- ------------------------------------------------------------------------------
INSERT INTO employees (employee_code, first_name, last_name, email, phone, department_id, role_id, salary, hire_date, is_active)
VALUES 
    ('EMP001', 'Nitesh',    'Kushwaha',  'nitesh.kushwaha@example.com',  '+91-9876543210', (SELECT id FROM departments WHERE dept_code='DEV'), (SELECT id FROM roles WHERE role_title='Senior DevOps Engineer'), 165000.00, '2021-02-10', TRUE),
    ('EMP002', 'Aarav',     'Sharma',    'aarav.sharma@example.com',    '+91-9876543211', (SELECT id FROM departments WHERE dept_code='ENG'), (SELECT id FROM roles WHERE role_title='Lead Full Stack Engineer'), 110000.00, '2022-04-15', TRUE),
    ('EMP003', 'Priya',     'Verma',     'priya.verma@example.com',     '+91-9876543212', (SELECT id FROM departments WHERE dept_code='DBA'), (SELECT id FROM roles WHERE role_title='PostgreSQL Database Architect'), 155000.00, '2020-08-01', TRUE),
    ('EMP004', 'Rohan',     'Gupta',     'rohan.gupta@example.com',     '+91-9876543213', (SELECT id FROM departments WHERE dept_code='DBA'), (SELECT id FROM roles WHERE role_title='Database Administrator (DBA)'), 85000.00,  '2023-01-16', TRUE),
    ('EMP005', 'Ananya',    'Patel',     'ananya.patel@example.com',    '+91-9876543214', (SELECT id FROM departments WHERE dept_code='ENG'), (SELECT id FROM roles WHERE role_title='Senior Backend Developer'), 140000.00, '2021-07-22', TRUE),
    ('EMP006', 'Vikram',    'Singh',     'vikram.singh@example.com',    '+91-9876543215', (SELECT id FROM departments WHERE dept_code='ENG'), (SELECT id FROM roles WHERE role_title='Senior Backend Developer'), 105000.00, '2022-09-05', TRUE),
    ('EMP007', 'Sneha',     'Reddy',     'sneha.reddy@example.com',     '+91-9876543216', (SELECT id FROM departments WHERE dept_code='DATA'), (SELECT id FROM roles WHERE role_title='Machine Learning Engineer'), 125000.00, '2022-11-12', TRUE),
    ('EMP008', 'Aditya',    'Mishra',    'aditya.mishra@example.com',   '+91-9876543217', (SELECT id FROM departments WHERE dept_code='SEC'), (SELECT id FROM roles WHERE role_title='Cyber Security Specialist'), 115000.00, '2023-03-01', TRUE),
    ('EMP009', 'Kavita',    'Nair',      'kavita.nair@example.com',     '+91-9876543218', (SELECT id FROM departments WHERE dept_code='QA'), (SELECT id FROM roles WHERE role_title='QA Automation Lead'), 100000.00, '2022-06-18', TRUE),
    ('EMP010', 'Rahul',     'Mehta',     'rahul.mehta@example.com',     '+91-9876543219', (SELECT id FROM departments WHERE dept_code='PROD'), (SELECT id FROM roles WHERE role_title='Technical Product Manager'), 150000.00, '2021-03-10', TRUE),
    ('EMP011', 'Neha',      'Choudhary', 'neha.choudhary@example.com',  '+91-9876543220', (SELECT id FROM departments WHERE dept_code='HR'), (SELECT id FROM roles WHERE role_title='Technical Product Manager'), 92000.00,  '2023-05-20', TRUE),
    ('EMP012', 'Arjun',     'Kapoor',    'arjun.kapoor@example.com',    '+91-9876543221', (SELECT id FROM departments WHERE dept_code='DEV'), (SELECT id FROM roles WHERE role_title='Senior DevOps Engineer'), 98000.00,  '2023-08-11', TRUE),
    ('EMP013', 'Divya',     'Iyer',      'divya.iyer@example.com',      '+91-9876543222', (SELECT id FROM departments WHERE dept_code='ENG'), (SELECT id FROM roles WHERE role_title='Senior Backend Developer'), 94000.00,  '2023-10-02', TRUE),
    ('EMP014', 'Siddharth', 'Joshi',     'siddharth.joshi@example.com', '+91-9876543223', (SELECT id FROM departments WHERE dept_code='DATA'), (SELECT id FROM roles WHERE role_title='Machine Learning Engineer'), 118000.00, '2023-11-15', TRUE),
    ('EMP015', 'Pooja',     'Bansal',    'pooja.bansal@example.com',    '+91-9876543224', (SELECT id FROM departments WHERE dept_code='QA'), (SELECT id FROM roles WHERE role_title='QA Automation Lead'), 82000.00,  '2024-02-01', TRUE)
ON CONFLICT (employee_code) DO UPDATE
SET first_name    = EXCLUDED.first_name,
    last_name     = EXCLUDED.last_name,
    department_id = EXCLUDED.department_id,
    role_id       = EXCLUDED.role_id,
    salary        = EXCLUDED.salary,
    is_active     = EXCLUDED.is_active,
    updated_at    = CURRENT_TIMESTAMP;

-- ------------------------------------------------------------------------------
-- D. INSERT PROJECTS DETAILS (6 Real-World Projects)
-- ------------------------------------------------------------------------------
INSERT INTO projects (project_code, project_name, client_name, budget, start_date, end_date, status)
VALUES
    ('PRJ-001', 'Cloud Infrastructure Automation & Modernization', 'FinCorp Global',         450000.00, '2024-01-10', '2024-12-31', 'IN_PROGRESS'),
    ('PRJ-002', 'High-Availability PostgreSQL Cluster Migration', 'HealthCare Digital',      280000.00, '2024-02-01', '2024-08-30', 'COMPLETED'),
    ('PRJ-003', 'Enterprise NextGen E-Commerce Microservices',    'RetailMart International', 620000.00, '2024-03-15', '2025-03-31', 'IN_PROGRESS'),
    ('PRJ-004', 'Predictive AI Customer Analytics Engine',         'Telecom Express',          390000.00, '2024-04-01', '2024-11-30', 'IN_PROGRESS'),
    ('PRJ-005', 'Zero-Trust Identity & Cyber Defense Audit',       'Bank of Commerce',         220000.00, '2024-05-10', '2024-09-15', 'COMPLETED'),
    ('PRJ-006', 'Global Automated CI/CD Jenkins Pipeline Mesh',    'Internal Tech Operations',  180000.00, '2024-06-01', '2025-01-31', 'IN_PROGRESS')
ON CONFLICT (project_code) DO UPDATE
SET project_name = EXCLUDED.project_name,
    budget       = EXCLUDED.budget,
    status       = EXCLUDED.status;

-- ------------------------------------------------------------------------------
-- E. INSERT PROJECT ASSIGNMENTS (Linking Employees to Projects via Codes)
-- ------------------------------------------------------------------------------
INSERT INTO project_assignments (project_id, employee_id, role_in_project, hours_allocated)
SELECT p.id, e.id, 'Lead Cloud Architect', 40 
FROM projects p, employees e WHERE p.project_code = 'PRJ-001' AND e.employee_code = 'EMP001'
ON CONFLICT (project_id, employee_id) DO NOTHING;

INSERT INTO project_assignments (project_id, employee_id, role_in_project, hours_allocated)
SELECT p.id, e.id, 'DevOps Specialist', 35 
FROM projects p, employees e WHERE p.project_code = 'PRJ-001' AND e.employee_code = 'EMP002'
ON CONFLICT (project_id, employee_id) DO NOTHING;

INSERT INTO project_assignments (project_id, employee_id, role_in_project, hours_allocated)
SELECT p.id, e.id, 'Principal Database Architect', 40 
FROM projects p, employees e WHERE p.project_code = 'PRJ-002' AND e.employee_code = 'EMP003'
ON CONFLICT (project_id, employee_id) DO NOTHING;

INSERT INTO project_assignments (project_id, employee_id, role_in_project, hours_allocated)
SELECT p.id, e.id, 'DBA Specialist', 30 
FROM projects p, employees e WHERE p.project_code = 'PRJ-002' AND e.employee_code = 'EMP004'
ON CONFLICT (project_id, employee_id) DO NOTHING;

INSERT INTO project_assignments (project_id, employee_id, role_in_project, hours_allocated)
SELECT p.id, e.id, 'Full Stack Lead', 40 
FROM projects p, employees e WHERE p.project_code = 'PRJ-003' AND e.employee_code = 'EMP005'
ON CONFLICT (project_id, employee_id) DO NOTHING;

INSERT INTO project_assignments (project_id, employee_id, role_in_project, hours_allocated)
SELECT p.id, e.id, 'Senior Backend Engineer', 35 
FROM projects p, employees e WHERE p.project_code = 'PRJ-003' AND e.employee_code = 'EMP006'
ON CONFLICT (project_id, employee_id) DO NOTHING;

INSERT INTO project_assignments (project_id, employee_id, role_in_project, hours_allocated)
SELECT p.id, e.id, 'QA Lead Engineer', 25 
FROM projects p, employees e WHERE p.project_code = 'PRJ-003' AND e.employee_code = 'EMP009'
ON CONFLICT (project_id, employee_id) DO NOTHING;

INSERT INTO project_assignments (project_id, employee_id, role_in_project, hours_allocated)
SELECT p.id, e.id, 'Principal Data Scientist', 40 
FROM projects p, employees e WHERE p.project_code = 'PRJ-004' AND e.employee_code = 'EMP007'
ON CONFLICT (project_id, employee_id) DO NOTHING;

INSERT INTO project_assignments (project_id, employee_id, role_in_project, hours_allocated)
SELECT p.id, e.id, 'MLOps Engineer', 35 
FROM projects p, employees e WHERE p.project_code = 'PRJ-004' AND e.employee_code = 'EMP014'
ON CONFLICT (project_id, employee_id) DO NOTHING;

INSERT INTO project_assignments (project_id, employee_id, role_in_project, hours_allocated)
SELECT p.id, e.id, 'Chief Security Auditor', 40 
FROM projects p, employees e WHERE p.project_code = 'PRJ-005' AND e.employee_code = 'EMP008'
ON CONFLICT (project_id, employee_id) DO NOTHING;

-- ------------------------------------------------------------------------------
-- F. LOG DEPLOYMENT IN AUDIT TABLE
-- ------------------------------------------------------------------------------
INSERT INTO schema_migrations (migration_name, status, details)
VALUES ('V2_comprehensive_schema_with_dummy_data', 'SUCCESS', 'Deployed departments (8), roles (10), employees (15), projects (6), and assignments (10)')
ON CONFLICT (migration_name) DO UPDATE
SET applied_at = CURRENT_TIMESTAMP,
    status = 'SUCCESS';

-- ==============================================================================
-- VERIFICATION & SUMMARY METRICS (Visible in Jenkins Pipeline Output)
-- ==============================================================================
SELECT 'Departments Added' AS entity, count(*)::text AS total_records FROM departments
UNION ALL
SELECT 'Roles Added', count(*)::text FROM roles
UNION ALL
SELECT 'Employees Added', count(*)::text FROM employees
UNION ALL
SELECT 'Projects Added', count(*)::text FROM projects
UNION ALL
SELECT 'Project Assignments Added', count(*)::text FROM project_assignments;

-- Display sample preview of employees joined with departments & roles
SELECT 
    e.employee_code,
    e.first_name || ' ' || e.last_name AS full_name,
    d.dept_name AS department,
    r.role_title AS designation,
    e.salary,
    e.hire_date
FROM employees e
LEFT JOIN departments d ON e.department_id = d.id
LEFT JOIN roles r ON e.role_id = r.id
WHERE e.employee_code IS NOT NULL
ORDER BY e.employee_code ASC
LIMIT 5;
