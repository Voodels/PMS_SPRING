# Java Spring Microservices - Patient Management System

## Project Overview

This is a comprehensive microservices-based Patient Management System built with Java Spring Boot. The system consists of multiple services:

- **Auth Service** (Port 3000) - Authentication and authorization
- **Patient Service** (Port 4000) - Patient data management
- **Billing Service** (Port 5000) - Billing and payment processing
- **Analytics Service** (Port 6000) - Data analytics and reporting
- **API Gateway** (Port 8080) - Central routing and load balancing

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Client Apps   │    │   Web Frontend  │    │  Mobile Apps    │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   API Gateway   │ :8080
                    │  (Load Balancer)│
                    └─────────┬───────┘
                              │
          ┌───────────────────┼───────────────────┐
          │                   │                   │
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  Auth Service   │  │ Patient Service │  │ Billing Service │
│     :3000       │  │     :4000       │  │     :5000       │
└─────────┬───────┘  └─────────┬───────┘  └─────────┬───────┘
          │                    │                    │
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   Auth DB       │  │  Patient DB     │  │  Billing DB     │
│   PostgreSQL    │  │  PostgreSQL     │  │  PostgreSQL     │
└─────────────────┘  └─────────────────┘  └─────────────────┘
                              │
                    ┌─────────────────┐
                    │ Analytics Service│ :6000
                    └─────────┬───────┘
                              │
                    ┌─────────────────┐
                    │     Kafka       │
                    │ Message Broker  │
                    └─────────────────┘
```

## Prerequisites

Before setting up the project, ensure you have the following installed:

### Required Software

1. **Java 21** or higher
   ```bash
   # Check Java version
   java -version
   ```

2. **Maven 3.6+**
   ```bash
   # Check Maven version
   mvn -version
   ```

3. **Docker** and **Docker Compose**
   ```bash
   # Check Docker version
   docker --version
   docker-compose --version
   ```

4. **Git**
   ```bash
   # Check Git version
   git --version
   ```

### Installation Links

- **Java 21**: [Oracle JDK](https://www.oracle.com/java/technologies/downloads/) or [OpenJDK](https://adoptium.net/)
- **Maven**: [Apache Maven](https://maven.apache.org/install.html)
- **Docker**: [Docker Desktop](https://www.docker.com/products/docker-desktop/)

## Quick Start

### Option 1: Automated Setup (Recommended)

Run the automated setup script:

```bash
# Make the script executable
chmod +x setup.sh

# Run the setup script
./setup.sh
```

This script will:
- Check prerequisites
- Build all microservices
- Start infrastructure services (databases, Kafka, etc.)
- Start all microservices
- Perform health checks

### Option 2: Manual Setup

#### Step 1: Start Infrastructure Services

```bash
# Create Docker network
docker network create microservices-network

# Start databases, Kafka, and other infrastructure
docker-compose -f docker-compose-infra.yml up -d

# Wait for services to be ready (about 30-60 seconds)
```

#### Step 2: Build Microservices

Build each service individually:

```bash
# Auth Service
cd auth-service
./mvnw clean package -DskipTests
cd ..

# Patient Service
cd patient-service
./mvnw clean package -DskipTests
cd ..

# Billing Service
cd billing-service
./mvnw clean package -DskipTests
cd ..

# Analytics Service
cd analytics-service
./mvnw clean package -DskipTests
cd ..

# API Gateway
cd api-gateway
./mvnw clean package -DskipTests
cd ..
```

#### Step 3: Start Microservices

```bash
# Build and start all microservices
docker-compose up -d
```

## Service Configuration

### Environment Variables

Each service uses environment variables for configuration:

#### Patient Service
```
SPRING_DATASOURCE_URL=jdbc:postgresql://patient-service-db:5432/db
SPRING_DATASOURCE_USERNAME=admin_user
SPRING_DATASOURCE_PASSWORD=password
SPRING_JPA_HIBERNATE_DDL_AUTO=update
SPRING_KAFKA_BOOTSTRAP_SERVERS=kafka:9092
BILLING_SERVICE_ADDRESS=billing-service
BILLING_SERVICE_GRPC_PORT=9005
```

#### Auth Service
```
SPRING_DATASOURCE_URL=jdbc:postgresql://auth-service-db:5432/db
SPRING_DATASOURCE_USERNAME=admin_user
SPRING_DATASOURCE_PASSWORD=password
SPRING_JPA_HIBERNATE_DDL_AUTO=update
```

#### Billing Service
```
SPRING_DATASOURCE_URL=jdbc:postgresql://billing-service-db:5432/db
SPRING_DATASOURCE_USERNAME=admin_user
SPRING_DATASOURCE_PASSWORD=password
SPRING_JPA_HIBERNATE_DDL_AUTO=update
```

## API Testing

### Default Test User

The system comes with a pre-configured test user:
- **Email**: `testuser@test.com`
- **Password**: `password`
- **Role**: `ADMIN`

### Authentication

First, get an authentication token:

```bash
curl -X POST http://localhost:3000/auth/login \
  -H 'Content-Type: application/json' \
  -d '{
    "email": "testuser@test.com",
    "password": "password"
  }'
```

### API Endpoints

#### Patient Service (Port 4000)
```bash
# Get all patients
curl http://localhost:4000/patients

# Create a patient
curl -X POST http://localhost:4000/patients \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer YOUR_TOKEN' \
  -d '{
    "firstName": "John",
    "lastName": "Doe",
    "email": "john.doe@email.com",
    "phone": "123-456-7890",
    "dateOfBirth": "1990-01-01"
  }'
```

#### Auth Service (Port 3000)
```bash
# Login
curl -X POST http://localhost:3000/auth/login \
  -H 'Content-Type: application/json' \
  -d '{
    "email": "testuser@test.com",
    "password": "password"
  }'

# Validate token
curl -X POST http://localhost:3000/auth/validate \
  -H 'Content-Type: application/json' \
  -d '{
    "token": "YOUR_JWT_TOKEN"
  }'
```

#### Billing Service (Port 5000)
```bash
# Create billing account (gRPC)
# See grpc-requests/billing-service/create-billing-account.http
```

## API Documentation

Each service provides Swagger/OpenAPI documentation:

- **Patient Service**: http://localhost:4000/swagger-ui.html
- **Auth Service**: http://localhost:3000/swagger-ui.html
- **Billing Service**: http://localhost:5000/swagger-ui.html
- **Analytics Service**: http://localhost:6000/swagger-ui.html

## Database Access

### PostgreSQL Databases

Each service has its own PostgreSQL database:

- **Patient DB**: `localhost:5432`
- **Auth DB**: `localhost:5433`
- **Billing DB**: `localhost:5434`

Connection details:
- **Username**: `admin_user`
- **Password**: `password`
- **Database**: `db`

### H2 Console (Development)

For local development without Docker, you can use H2 in-memory database by uncommenting the H2 configuration in `application.properties`.

## Monitoring and Debugging

### Docker Logs

View logs for any service:

```bash
# View all service logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f patient-service
docker-compose logs -f auth-service
docker-compose logs -f billing-service
```

### Health Checks

Check if services are running:

```bash
# Check all containers
docker ps

# Check specific service health
curl http://localhost:4000/actuator/health
curl http://localhost:3000/actuator/health
```

### Debug Mode

Patient Service runs with debug mode enabled on port 5005:
```bash
# Connect your IDE debugger to localhost:5005
```

## Development Workflow

### Making Changes

1. **Stop the specific service**:
   ```bash
   docker-compose stop patient-service
   ```

2. **Make your code changes**

3. **Rebuild the service**:
   ```bash
   cd patient-service
   ./mvnw clean package -DskipTests
   cd ..
   ```

4. **Restart the service**:
   ```bash
   docker-compose up -d patient-service
   ```

### Hot Reload (Development)

For faster development, run services locally:

1. Start only infrastructure:
   ```bash
   docker-compose -f docker-compose-infra.yml up -d
   ```

2. Run service locally:
   ```bash
   cd patient-service
   ./mvnw spring-boot:run
   ```

## Troubleshooting

### Common Issues

1. **Port conflicts**:
   ```bash
   # Check what's using a port
   lsof -i :4000
   
   # Kill process using port
   kill -9 PID
   ```

2. **Database connection issues**:
   ```bash
   # Check if database is running
   docker ps | grep postgres
   
   # Restart database
   docker-compose -f docker-compose-infra.yml restart patient-service-db
   ```

3. **Kafka connection issues**:
   ```bash
   # Check Kafka logs
   docker-compose -f docker-compose-infra.yml logs kafka
   
   # Restart Kafka
   docker-compose -f docker-compose-infra.yml restart kafka
   ```

### Clean Reset

To completely reset the environment:

```bash
# Stop all services
docker-compose down
docker-compose -f docker-compose-infra.yml down

# Remove volumes (this will delete all data)
docker volume prune -f

# Remove network
docker network rm microservices-network

# Restart setup
./setup.sh
```

## Testing

### Unit Tests

Run unit tests for each service:

```bash
cd patient-service
./mvnw test
```

### Integration Tests

Run integration tests:

```bash
cd integration-tests
./mvnw test
```

### API Testing with HTTP Files

The project includes HTTP request files in the `api-requests` directory:
- `api-requests/auth-service/` - Auth service requests
- `api-requests/patient-service/` - Patient service requests
- `grpc-requests/billing-service/` - gRPC requests for billing service

## Performance Considerations

### Resource Requirements

- **Minimum**: 8GB RAM, 4 CPU cores
- **Recommended**: 16GB RAM, 8 CPU cores

### Scaling

To scale services horizontally:

```bash
# Scale patient service to 3 instances
docker-compose up -d --scale patient-service=3
```

## Security

### JWT Tokens

- Tokens expire after a configurable time
- Use strong secrets in production
- Implement token refresh mechanism

### Database Security

- Change default passwords in production
- Use SSL/TLS for database connections
- Implement database encryption at rest

## Production Deployment

### Environment Variables

Set production environment variables:

```bash
export SPRING_PROFILES_ACTIVE=prod
export JWT_SECRET=your-production-secret
export DB_PASSWORD=your-production-password
```

### Docker Registry

Build and push images to a registry:

```bash
# Build and tag
docker build -t your-registry/patient-service:v1.0 ./patient-service

# Push to registry
docker push your-registry/patient-service:v1.0
```

## Support

- **Discord Community**: https://discord.gg/nCrDnfCE
- **GitHub Issues**: Create an issue for bugs or feature requests
- **Documentation**: Check service-specific README files

## License

Copyright © 2025 Code Jackal | Original Course Material by Chris Blakely
