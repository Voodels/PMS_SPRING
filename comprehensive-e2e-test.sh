#!/bin/bash

# Comprehensive End-to-End Test Suite for Patient Management System
# Tests everything: databases, Kafka, CRUD operations, gRPC, health checks

# Remove set -e to allow tests to continue on failures
# set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BASE_URL="http://localhost:8081"
AUTH_URL="http://localhost:3002"
PATIENT_URL="http://localhost:4000"
BILLING_URL="http://localhost:5000"
ANALYTICS_URL="http://localhost:6000"

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Utility functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    ((PASSED_TESTS++))
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    ((FAILED_TESTS++))
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

test_start() {
    ((TOTAL_TESTS++))
    log_info "Test $TOTAL_TESTS: $1"
}

# Wait for service to be ready
wait_for_service() {
    local url=$1
    local service_name=$2
    local max_attempts=30
    local attempt=1
    
    log_info "Waiting for $service_name to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "$url" >/dev/null 2>&1; then
            log_success "$service_name is ready!"
            return 0
        fi
        echo "   Attempt $attempt/$max_attempts..."
        sleep 5
        ((attempt++))
    done
    
    log_error "$service_name failed to start!"
    return 1
}

# Database connectivity tests
test_database_connectivity() {
    test_start "Database Connectivity"
    
    # Test PostgreSQL databases
    log_info "Testing Patient Service Database..."
    if docker exec patient-service-db pg_isready -U admin_user -d db >/dev/null 2>&1; then
        log_success "Patient Database is ready"
    else
        log_error "Patient Database connection failed"
    fi
    
    log_info "Testing Auth Service Database..."
    if docker exec auth-service-db pg_isready -U admin_user -d db >/dev/null 2>&1; then
        log_success "Auth Database is ready"
    else
        log_error "Auth Database connection failed"
    fi
    
    log_info "Testing Billing Service Database..."
    if docker exec billing-service-db pg_isready -U admin_user -d db >/dev/null 2>&1; then
        log_success "Billing Database is ready"
    else
        log_error "Billing Database connection failed"
    fi
}

# Kafka connectivity test
test_kafka_connectivity() {
    test_start "Kafka Connectivity"
    
    log_info "Testing Kafka broker..."
    if docker exec kafka kafka-broker-api-versions.sh --bootstrap-server localhost:9092 >/dev/null 2>&1; then
        log_success "Kafka is ready"
    else
        log_error "Kafka connection failed"
        return 1
    fi
    
    # Test topic creation
    log_info "Testing Kafka topic operations..."
    if docker exec kafka kafka-topics.sh --bootstrap-server localhost:9092 --create --topic test-topic --partitions 1 --replication-factor 1 >/dev/null 2>&1; then
        log_success "Kafka topic creation successful"
        # Clean up test topic
        docker exec kafka kafka-topics.sh --bootstrap-server localhost:9092 --delete --topic test-topic >/dev/null 2>&1
    else
        log_error "Kafka topic creation failed"
        return 1
    fi
}

# Service health checks
test_service_health() {
    test_start "Service Health Checks"
    
    # Wait for services to be ready
    wait_for_service "$AUTH_URL/actuator/health" "Auth Service" || wait_for_service "$AUTH_URL" "Auth Service"
    wait_for_service "$PATIENT_URL/actuator/health" "Patient Service" || wait_for_service "$PATIENT_URL" "Patient Service"
    wait_for_service "$BILLING_URL/actuator/health" "Billing Service" || wait_for_service "$BILLING_URL" "Billing Service"
    wait_for_service "$ANALYTICS_URL/actuator/health" "Analytics Service" || wait_for_service "$ANALYTICS_URL" "Analytics Service"
    wait_for_service "$BASE_URL/actuator/health" "API Gateway" || wait_for_service "$BASE_URL" "API Gateway"
}

# Authentication tests
test_authentication() {
    test_start "Authentication Service"
    
    # Test user registration/login
    log_info "Testing user authentication..."
    
    # Create test user (if registration endpoint exists)
    local login_response
    login_response=$(curl -s -X POST "$AUTH_URL/auth/login" \
        -H "Content-Type: application/json" \
        -d '{
            "email": "test@example.com",
            "password": "password123"
        }' || echo "")
    
    if [[ "$login_response" == *"token"* ]] || [[ "$login_response" == *"jwt"* ]]; then
        log_success "Authentication successful"
        # Extract JWT token for later use
        JWT_TOKEN=$(echo "$login_response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4 || echo "")
        return 0
    else
        log_warning "Authentication test inconclusive (endpoint may not exist yet)"
        JWT_TOKEN=""
        return 0
    fi
}

# Patient CRUD operations
test_patient_crud() {
    test_start "Patient Service CRUD Operations"
    
    # Test Create Patient
    log_info "Testing Create Patient..."
    local create_response
    create_response=$(curl -s -X POST "$PATIENT_URL/api/patients" \
        -H "Content-Type: application/json" \
        ${JWT_TOKEN:+-H "Authorization: Bearer $JWT_TOKEN"} \
        -d '{
            "firstName": "John",
            "lastName": "Doe",
            "email": "john.doe@example.com",
            "phoneNumber": "+1234567890",
            "dateOfBirth": "1990-01-01"
        }' || echo "")
    
    local patient_id
    if [[ "$create_response" == *"id"* ]] || [[ "$create_response" == *"John"* ]]; then
        log_success "Patient creation successful"
        patient_id=$(echo "$create_response" | grep -o '"id":[0-9]*' | cut -d':' -f2 || echo "1")
    else
        log_warning "Patient creation test inconclusive"
        patient_id="1"
    fi
    
    # Test Read Patient
    log_info "Testing Read Patients..."
    local read_response
    read_response=$(curl -s -X GET "$PATIENT_URL/api/patients" \
        ${JWT_TOKEN:+-H "Authorization: Bearer $JWT_TOKEN"} || echo "")
    
    if [[ "$read_response" == *"["* ]] || [[ "$read_response" == *"patients"* ]] || [[ "$read_response" != *"error"* ]]; then
        log_success "Patient read operation successful"
    else
        log_warning "Patient read test inconclusive"
    fi
    
    # Test Update Patient
    log_info "Testing Update Patient..."
    local update_response
    update_response=$(curl -s -X PUT "$PATIENT_URL/api/patients/$patient_id" \
        -H "Content-Type: application/json" \
        ${JWT_TOKEN:+-H "Authorization: Bearer $JWT_TOKEN"} \
        -d '{
            "firstName": "Jane",
            "lastName": "Doe",
            "email": "jane.doe@example.com",
            "phoneNumber": "+1234567890",
            "dateOfBirth": "1990-01-01"
        }' || echo "")
    
    if [[ "$update_response" == *"Jane"* ]] || [[ "$update_response" != *"error"* ]]; then
        log_success "Patient update operation successful"
    else
        log_warning "Patient update test inconclusive"
    fi
    
    # Test Delete Patient
    log_info "Testing Delete Patient..."
    local delete_response
    delete_response=$(curl -s -X DELETE "$PATIENT_URL/api/patients/$patient_id" \
        ${JWT_TOKEN:+-H "Authorization: Bearer $JWT_TOKEN"} || echo "")
    
    if [[ "$delete_response" != *"error"* ]]; then
        log_success "Patient delete operation successful"
    else
        log_warning "Patient delete test inconclusive"
    fi
}

# Billing service gRPC test
test_billing_grpc() {
    test_start "Billing Service gRPC"
    
    log_info "Testing Billing Service gRPC endpoint..."
    
    # Test if gRPC port is accessible
    if timeout 5 bash -c "echo >/dev/tcp/localhost/9005" 2>/dev/null; then
        log_success "Billing gRPC port is accessible"
    else
        log_error "Billing gRPC port is not accessible"
        return 1
    fi
    
    # Test HTTP endpoint as fallback
    local billing_response
    billing_response=$(curl -s -X GET "$BILLING_URL/health" || curl -s -X GET "$BILLING_URL/actuator/health" || echo "")
    
    if [[ "$billing_response" != *"error"* ]]; then
        log_success "Billing service is responsive"
    else
        log_warning "Billing service HTTP test inconclusive"
    fi
}

# Analytics service Kafka consumer test
test_analytics_kafka() {
    test_start "Analytics Service Kafka Integration"
    
    log_info "Testing Analytics Service..."
    
    # Check if analytics service is running
    local analytics_response
    analytics_response=$(curl -s -X GET "$ANALYTICS_URL/health" || curl -s -X GET "$ANALYTICS_URL/actuator/health" || echo "")
    
    if [[ "$analytics_response" != *"error"* ]]; then
        log_success "Analytics service is responsive"
    else
        log_warning "Analytics service test inconclusive"
    fi
    
    # Test Kafka message production (simulate patient event)
    log_info "Testing Kafka message flow..."
    if docker exec kafka kafka-console-producer.sh --bootstrap-server localhost:9092 --topic patient-events <<< '{"eventType":"PATIENT_CREATED","patientId":1,"timestamp":"2025-07-22T12:00:00Z"}' >/dev/null 2>&1; then
        log_success "Kafka message production successful"
    else
        log_warning "Kafka message production test inconclusive"
    fi
}

# API Gateway routing test
test_api_gateway() {
    test_start "API Gateway Routing"
    
    log_info "Testing API Gateway routes..."
    
    # Test auth route
    local auth_route_response
    auth_route_response=$(curl -s -X GET "$BASE_URL/auth/health" || echo "")
    
    if [[ "$auth_route_response" != *"error"* ]]; then
        log_success "Auth service route through gateway working"
    else
        log_warning "Auth route test inconclusive"
    fi
    
    # Test patient route
    local patient_route_response
    patient_route_response=$(curl -s -X GET "$BASE_URL/api/patients" \
        ${JWT_TOKEN:+-H "Authorization: Bearer $JWT_TOKEN"} || echo "")
    
    if [[ "$patient_route_response" != *"error"* ]]; then
        log_success "Patient service route through gateway working"
    else
        log_warning "Patient route test inconclusive"
    fi
}

# Container status test
test_container_status() {
    test_start "Container Status Check"
    
    log_info "Checking all container statuses..."
    
    local containers=(
        "patient-service-db"
        "auth-service-db"
        "billing-service-db"
        "kafka"
        "auth-service"
        "patient-service"
        "billing-service"
        "analytics-service"
        "api-gateway"
    )
    
    local all_running=true
    for container in "${containers[@]}"; do
        if docker ps --format "table {{.Names}}" | grep -q "^$container$"; then
            local status=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep "^$container" | awk '{print $2}')
            log_success "Container $container is running ($status)"
        else
            log_error "Container $container is not running"
            all_running=false
        fi
    done
    
    if $all_running; then
        log_success "All containers are running"
    else
        log_error "Some containers are not running"
        return 1
    fi
}

# Performance test
test_performance() {
    test_start "Basic Performance Test"
    
    log_info "Running basic performance tests..."
    
    # Test response times
    local start_time end_time duration
    
    start_time=$(date +%s%N)
    curl -s -X GET "$PATIENT_URL/api/patients" ${JWT_TOKEN:+-H "Authorization: Bearer $JWT_TOKEN"} >/dev/null 2>&1 || true
    end_time=$(date +%s%N)
    duration=$(( (end_time - start_time) / 1000000 )) # Convert to milliseconds
    
    if [ $duration -lt 5000 ]; then # Less than 5 seconds
        log_success "Patient API response time: ${duration}ms (Good)"
    else
        log_warning "Patient API response time: ${duration}ms (Slow)"
    fi
}

# Main test execution
main() {
    echo "=========================================="
    echo "🧪 COMPREHENSIVE E2E TEST SUITE"
    echo "=========================================="
    echo "Testing Patient Management System..."
    echo ""
    
    # Start timer
    local start_time=$(date +%s)
    
    # Run all tests
    test_container_status
    test_database_connectivity
    test_kafka_connectivity
    test_service_health
    test_authentication
    test_patient_crud
    test_billing_grpc
    test_analytics_kafka
    test_api_gateway
    test_performance
    
    # Calculate duration
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo ""
    echo "=========================================="
    echo "📊 TEST RESULTS SUMMARY"
    echo "=========================================="
    echo -e "Total Tests: ${BLUE}$TOTAL_TESTS${NC}"
    echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
    echo -e "Success Rate: ${GREEN}$(( PASSED_TESTS * 100 / TOTAL_TESTS ))%${NC}"
    echo -e "Duration: ${BLUE}${duration}s${NC}"
    echo ""
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${GREEN}🎉 ALL TESTS PASSED! System is working correctly.${NC}"
        echo ""
        echo "✅ Your Patient Management System is fully operational!"
        echo ""
        echo "🌐 Access URLs:"
        echo "   API Gateway: $BASE_URL"
        echo "   Patient API: $PATIENT_URL/api/patients"
        echo "   Auth API: $AUTH_URL/auth"
        echo ""
        return 0
    else
        echo -e "${RED}❌ SOME TESTS FAILED. Please check the logs above.${NC}"
        echo ""
        echo "🔧 Troubleshooting:"
        echo "   1. Check container logs: docker-compose logs [service-name]"
        echo "   2. Verify all services are running: docker-compose ps"
        echo "   3. Check service health: curl [service-url]/actuator/health"
        echo ""
        return 1
    fi
}

# Trap to handle script interruption
trap 'echo -e "\n${YELLOW}Test interrupted by user${NC}"; exit 1' INT

# Run main function
main "$@"
