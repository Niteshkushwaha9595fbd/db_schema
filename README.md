# Database Schema & Data Deployment Repository

PostgreSQL database schema and initial data deployment script for automated CI/CD pipelines.

---

## 📁 Repository Contents

- **`schema.sql`**: Main SQL migration script. It contains:
  1. **Tables**:
     - `schema_migrations` (Tracks migration history)
     - `departments` (Department details & budget)
     - `roles` (Job roles & designations)
     - `employees` (Employee details, contact info, salary, status)
  2. **Performance Indexes**: Index on `email`, `department_id`, and `role_id`
  3. **Seed Data Entries**: Initial records for departments, roles, and employees
  4. **Idempotent Logic**: Uses `IF NOT EXISTS` and `ON CONFLICT` so running multiple times will not cause duplicate key or table exists errors.

---

## 🧪 Local Testing via Docker Container

Aap apne local running PostgreSQL container (`postgres_db`) par is script ko test kar sakte hain:

```powershell
# Directly run against running postgres_db container:
docker exec -i postgres_db psql -U postgres -d mydb < schema.sql
```

Verification command:
```powershell
docker exec -it postgres_db psql -U postgres -d mydb -c "SELECT * FROM employees;"
```

---

## 🚀 Jenkinsfile Integration with JSL_Template

In your Jenkinsfile:

```groovy
@Library('JSL_Template') _

def dbConfig = [
    repoUrl          : 'https://github.com/Niteshkushwaha9595fbd/db_schema.git',
    branch           : 'main',
    environment      : 'DEV',
    dbType           : 'postgres',
    dbHost           : 'localhost',                // Host machine IP or host.docker.internal if Jenkins is in docker
    dbPort           : '5432',
    dbName           : 'mydb',
    credentialsId    : 'postgres-credentials-id',  // Jenkins Credentials ID (user: postgres, pass: mysecretpassword)
    sqlFile          : 'schema.sql',
    dryRun           : false
]

dbDeployTemplate(dbConfig)
```
