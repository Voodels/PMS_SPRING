<div align="center">

# Patient Management System — Java Spring Microservices

Robust, containerized microservices for managing patients, auth, billing, analytics, and an API gateway — designed for local development with Docker.

</div>

## Overview

This monorepo hosts a complete Patient Management System built with Spring Boot services, Kafka for messaging, PostgreSQL for persistence, and Docker for orchestration.

Services included:
- Auth Service (JWT-based auth) — :3002
- Patient Service (CRUD + Kafka events) — :4000
- Billing Service (REST + gRPC) — :5000 (gRPC exposed on :9005)
- Analytics Service (consumes Kafka) — :6000
- API Gateway (routes/aggregation) — :8081

## Architecture

```
							 ┌─────────────────────────┐
							 │        Clients          │
							 └───────────┬────────────┘
													 │ HTTP :8081
									┌────────▼────────┐
									│    API Gateway  │
									└───┬────────┬────┘
					HTTP :3002  │        │  HTTP :5000, gRPC :9005
				┌─────────────▼───┐    │    ┌───────────────┐
				│   Auth Service  │    │    │ Billing Svc   │◄────┐
				└────────┬────────┘    │    └───────┬──────┘     │
								 │             │            │             │
								 │             │            │             │ Kafka :9092
				┌────────▼────────┐    │    ┌───────▼────────┐    │
				│ Patient Service │─────┼───► Analytics Svc  │────┘
				└────────┬────────┘         └────────────────┘
								 │
			┌──────────▼──────────┐
			│ PostgreSQL per svc  │ (5432/5433/5434)
			└─────────────────────┘
```

## Tech Stack
- Java 21, Spring Boot 3
- PostgreSQL (one DB per service)
- Apache Kafka (Bitnami image)
- Docker & docker-compose
- gRPC (Billing service)

## Quick Start

Prerequisites:
- Docker and docker-compose installed

Start all services (build + run):
```bash
docker-compose up -d --build
```

Stop everything:
```bash
docker-compose down
```

Tail logs for a service:
```bash
docker-compose logs -f patient-service
```

## Endpoints

- API Gateway: http://localhost:8081
- Auth Service: http://localhost:3002
- Patient Service: http://localhost:4000
- Billing Service (REST): http://localhost:5000
- Billing Service (gRPC): localhost:9005
- Analytics Service: http://localhost:6000

Databases (PostgreSQL):
- patient-service-db: localhost:5432
- auth-service-db: localhost:5433
- billing-service-db: localhost:5434
	- username: admin_user, password: password, database: db

## Try it quickly

1) Login (Auth Service):
```bash
curl -X POST http://localhost:3002/auth/login \
	-H 'Content-Type: application/json' \
	-d '{"email":"testuser@test.com","password":"password"}'
```

2) List patients (Patient Service):
```bash
curl http://localhost:4000/patients
```

3) Create patient (requires Bearer token):
```bash
curl -X POST http://localhost:4000/patients \
	-H 'Content-Type: application/json' \
	-H "Authorization: Bearer YOUR_JWT_TOKEN" \
	-d '{
		"firstName":"John",
		"lastName":"Doe",
		"email":"john.doe@example.com",
		"phone":"123-456-7890",
		"dateOfBirth":"1990-01-01"
	}'
```

gRPC sample for Billing:
- See `grpc-requests/billing-service/create-billing-account.http`

HTTP request collections:
- See `api-requests/` (Auth + Patient).

## Local Development

Rebuild just one service:
```bash
docker-compose up -d --build auth-service
```

Service debug:
- Patient Service exposes JVM remote debug on :5005 (attach your IDE).

## Troubleshooting

- Port already in use:
	```bash
	lsof -i :4000
	kill -9 <PID>
	```
- Check container health/logs:
	```bash
	docker ps
	docker-compose logs -f
	```
- Reset environment (removes containers; volumes persist unless removed):
	```bash
	docker-compose down
	```

## Repository structure

```
├─ api-gateway/
├─ analytics-service/
├─ auth-service/
├─ billing-service/
├─ patient-service/
├─ integration-tests/
├─ infrastructure/
├─ grpc-requests/
├─ api-requests/
├─ docker-compose.yml
├─ QUICK_COMMANDS.md
└─ PROJECT_SETUP.md
```

---

Made with Spring Boot microservices and containers for a smooth local dev experience.
