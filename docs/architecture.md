# AWX Proxy – Architecture & Design Notes

## 1. Purpose & High-Level Goal

The project is to build a **secure proxy application** (written in **Python / Flask**) that acts as a front-end for **service accounts** to interact with **AWX**, without exposing AWX directly to external or untrusted systems.

The proxy:

* Receives external requests (webhooks / API calls)
* Authenticates clients
* Validates and audits payloads
* Maps requests to allowed AWX templates
* Executes those templates via an internal executor
* Reports execution status back to the caller

Security, auditability, and future multi-tenancy are first-class requirements.

---

## 2. Core Architectural Principles

* **AWX must never be externally exposed**
* **Strong separation of concerns** between components
* **Audit everything** (requests, decisions, executions, admin changes)
* **Design for multi-tenancy from day one**
* **Start centralized, but allow future customer-specific admin interfaces**
* **Prefer simple, understandable solutions over heavy infrastructure**

---

## 3. Container Layout (Compose-based)

Initial deployment will use **Docker Compose**.

### 3.1 Containers

1. **Main API Container (Externally Exposed)**

   * Flask API
   * Receives payloads
   * OAuth / Bearer authentication
   * Input validation
   * Writes jobs + audit logs to DB
   * Notifies executor via internal API

2. **Executor Container (Internal Only)**

   * No external exposure
   * Receives job notifications
   * Pulls job data from DB
   * Executes AWX templates
   * Sends execution status back
   * Maintains its own logs

3. **Admin Container (Internal Only)**

   * Admin UI / API
   * Manages:

     * Customers (tenants)
     * OAuth clients
     * Roles & permissions
     * Template mappings
   * Communicates with AWX to fetch templates & metadata
   * Fully audited

4. **Database Container**

   * PostgreSQL
   * Source of truth for jobs, audit logs, RBAC, tenants

5. **Reverse Proxy (Nginx)**

   * Single reverse proxy
   * TLS termination
   * Routing to Main API
   * Admin interface protected via IP allowlisting or internal-only exposure

---

## 4. Data Flow (Execution Path)

1. External system sends request to Main API
2. Authentication (OAuth or Bearer token)
3. Input validation & sanitization
4. Payload written to DB (immutable audit record)
5. Job marked as `NEW`
6. Main API calls Executor internal API: `job_available(job_id)`
7. Executor acknowledges & marks job `IN_PROGRESS`
8. Executor executes AWX template
9. Status + results stored in DB
10. Callback/report sent to external system

**Crash Safety**:

* DB is the source of truth
* On startup, Main API re-sends notifications for jobs not acknowledged
* Executor can resume uncompleted jobs

---

## 5. Auditing (Critical Requirement)

Everything is auditable.

### 5.1 What Is Audited

* Incoming payloads
* Client identity
* Timestamps (received, scheduled, executed)
* Payload content (or hash + reference)
* Template mapping decisions
* Execution status & errors
* Admin actions (RBAC changes, client updates)

### 5.2 Where Audits Live

* **Database** (structured, queryable)
* **Syslog output** (integration with SIEM)
* **Persistent log files** mounted into containers

Each sensitive container (Main API, Admin, Executor) logs independently.

---

## 6. Authentication & Authorization

### 6.1 External API Authentication

Support **side-by-side authentication methods**:

* OAuth 2.0 (preferred)
* Bearer tokens (managed by OAuth libraries)

Clients can choose which model they prefer.

### 6.2 OAuth / Token Handling

* Use existing OAuth libraries (e.g. Authlib)
* Bearer tokens piggyback on OAuth token infrastructure
* Tokens can include:

  * Scopes
  * Tenant ID
  * Role mappings

### 6.3 Admin Authentication

* Start simple
* Supported methods:

  * LDAP
  * Remote user headers (OIDC proxy in front)
* Keep design open for future native OIDC / SAML

---

## 7. RBAC & Multi-Tenancy Model

### 7.1 Tenancy

* System is **multi-tenant**
* Each customer (tenant) has:

  * Its own OAuth clients
  * Its own roles
  * Its own template permissions

### 7.2 Roles

* Roles are tenant-scoped
* Roles map to allowed AWX templates
* Primary permission is **execute**
* Optional: restrict allowed template parameters

### 7.3 Future Design

* Start with centralized admin interface
* Architect RBAC logic so it can later be exposed as:

  * One admin UI per customer
  * Without rewriting backend logic

---

## 8. Input Validation & Security

* All incoming payloads validated
* Strong schema enforcement:

  * Type checking
  * Required fields
  * Allowed values
  * Regex validation where appropriate
* Reject unknown fields
* Sanitize inputs before DB or AWX usage

Goal: prevent injection, malformed payloads, and AWX abuse.

---

## 9. Database Design

### 9.1 Engine

* **PostgreSQL**

### 9.2 Core Tables (High-Level)

* tenants
* oauth_clients
* roles
* role_template_map
* jobs
* job_parameters
* audit_logs
* admin_audit_logs

### 9.3 Migrations

* Database migrations are mandatory
* Use Alembic (via SQLAlchemy)
* Migrations run during container startup or deployment

---

## 10. Executor Communication Model

* Executor exposes internal REST API
* Main API notifies executor when jobs are created
* Executor acknowledges receipt
* DB reflects job state transitions

No message broker required initially.

---

## 11. Logging Strategy

* Structured logs to DB (audit)
* Syslog support
* File-based logs on persistent storage
* Executor logs kept independent but correlated via job IDs

---

## 12. Deployment & Upgrades

* Docker Compose
* Simple restarts acceptable
* Downtime expected to be seconds
* DB migrations may add small overhead

---

## 13. Open / Future Topics

* Metrics & monitoring (Prometheus, health endpoints)
* Rate limiting
* Template parameter whitelisting per role
* Customer self-service admin portals
* Kubernetes migration (later)

---

## 14. Current Status

Architecture is well-defined.

Next steps (when resuming):

* Define initial DB schema
* Define Flask app structure (blueprints)
* Draft docker-compose.yml
* Implement minimal happy-path execution flow
