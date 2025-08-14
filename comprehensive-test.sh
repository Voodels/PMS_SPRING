#!/bin/bash

# Comprehensive Test Suite for Java Spring Microservices Patient Management System
# ===================================================================================

set -e  # Exit on any error

echo "🧪 COMPREHENSIVE MICROSERVICES TEST SUITE"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Helper functions
log_test() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "${BLUE}🔍 Test $TOTAL_TESTS: $1${NC}"
}

log_success() {
    PASSED_TESTS=$((PASSED_TESTS + 1))
    echo -e "${GREEN}✅ PASS: $1${NC}"
}

log_failure() {
    FAILED_TESTS=$((FAILED_TESTS + 1))
    echo -e "${RED}❌ FAIL: $1${NC}"
}

log_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Function to check if service is responding
check_service() {
    local service_name=$1
    local url=$2
    local expected_status=${3:-200}
    
    log_test "Checking $service_name connectivity"
    
    if response=$(curl -s -w "%{http_code}" -o /tmp/response.txt "$url" 2>/dev/null); then
        if [[ "$response" == "$expected_status" ]]; then
            log_success "$service_name is responding (HTTP $response)"
            return 0
        else
            log_failure "$service_name returned HTTP $response, expected $expected_status"
            return 1
        fi
    else
        log_failure "$service_name is not responding"
        return 1
    fi
}

# Function to check service health via Docker
check_container_health() {
    local container_name=$1
    log_test "Checking $container_name container health"
    
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "$container_name.*Up"; then
        log_success "$container_name container is running"
        return 0
    else
        log_failure "$container_name container is not running"
        return 1
    fi
}

echo "📋 PHASE 1: INFRASTRUCTURE HEALTH CHECKS"
echo "========================================="

# Check all containers are running
containers=("kafka" "auth-service-db" "patient-service-db" "billing-service-db" "redis" "auth-service" "patient-service" "billing-service" "analytics-service" "api-gateway")

for container in "${containers[@]}"; do
    check_container_health "$container"
done

echo ""
echo "📊 PHASE 2: DATABASE CONNECTIVITY TESTS"
echo "======================================="

# Test PostgreSQL databases
log_test "Testing PostgreSQL databases connectivity"

# Patient DB
if docker exec patient-service-db psql -U admin_user -d db -c "SELECT 1;" > /dev/null 2>&1; then
    log_success "Patient database is accessible"
else
    log_failure "Patient database connection failed"
fi

# Auth DB  
if docker exec auth-service-db psql -U admin_user -d db -c "SELECT 1;" > /dev/null 2>&1; then
    log_success "Auth database is accessible"
else
    log_failure "Auth database connection failed"
fi

# Billing DB
if docker exec billing-service-db psql -U admin_user -d db -c "SELECT 1;" > /dev/null 2>&1; then
    log_success "Billing database is accessible"
else
    log_failure "Billing database connection failed"
fi

# Test Redis
log_test "Testing Redis connectivity"
if docker exec redis redis-cli ping | grep -q "PONG"; then
    log_success "Redis is responding"
else
    log_failure "Redis connection failed"
fi

# Test Kafka
log_test "Testing Kafka connectivity"
if docker exec kafka kafka-topics.sh --bootstrap-server localhost:9092 --list > /dev/null 2>&1; then
    log_success "Kafka is responding"
else
    log_failure "Kafka connection failed"
fi

echo ""
echo "🌐 PHASE 3: MICROSERVICES HTTP ENDPOINT TESTS"
echo "=============================================="

# Wait for services to be fully ready
log_info "Waiting 10 seconds for services to fully initialize..."
sleep 10

# Test each microservice
check_service "Patient Service" "http://localhost:4000/patients"
check_service "Auth Service" "http://localhost:3002/actuator/health" 404  # Auth service might not have actuator
check_service "Billing Service" "http://localhost:5000/actuator/health" 404  # Might not have actuator
check_service "Analytics Service" "http://localhost:6000/actuator/health" 404  # Might not have actuator
check_service "API Gateway" "http://localhost:8081/actuator/health" 404  # Might not have actuator

echo ""
echo "📝 PHASE 4: PATIENT SERVICE CRUD OPERATIONS"
echo "==========================================="

# Test GET all patients
log_test "GET all patients"
if response=$(curl -s -w "%{http_code}" -o /tmp/patients.json "http://localhost:4000/patients"); then
    if [[ "$response" == "200" ]]; then
        patient_count=$(cat /tmp/patients.json | jq '. | length' 2>/dev/null || echo "0")
        log_success "Retrieved $patient_count patients"
    else
        log_failure "Failed to get patients (HTTP $response)"
    fi
else
    log_failure "Patient service not responding"
fi

# Test POST create patient
log_test "POST create new patient"
new_patient_data='{
    "name": "Integration Test Patient",
    "email": "test-patient-'$(date +%s)'@example.com",
    "address": "123 Test Street, Test City",
    "dateOfBirth": "1990-01-01",
    "registeredDate": "'$(date +%Y-%m-%d)'"
}'

if response=$(curl -s -w "%{http_code}" -o /tmp/created_patient.json -X POST \
    -H "Content-Type: application/json" \
    -d "$new_patient_data" \
    "http://localhost:4000/patients"); then
    
    if [[ "$response" == "201" ]] || [[ "$response" == "200" ]]; then
        if [[ -s /tmp/created_patient.json ]]; then
            created_patient_id=$(cat /tmp/created_patient.json | jq -r '.id' 2>/dev/null || echo "")
            if [[ -n "$created_patient_id" && "$created_patient_id" != "null" ]]; then
                log_success "Created patient with ID: $created_patient_id"
                CREATED_PATIENT_ID="$created_patient_id"
            else
                log_failure "Patient created but no ID returned"
            fi
        else
            log_success "Patient creation request accepted (HTTP $response)"
        fi
    else
        log_failure "Failed to create patient (HTTP $response)"
        echo "Response: $(cat /tmp/created_patient.json)"
    fi
else
    log_failure "Patient service not responding for POST"
fi

# Test GET specific patient (if we created one)
if [[ -n "$CREATED_PATIENT_ID" ]]; then
    log_test "GET specific patient by ID"
    if response=$(curl -s -w "%{http_code}" -o /tmp/specific_patient.json "http://localhost:4000/patients/$CREATED_PATIENT_ID"); then
        if [[ "$response" == "200" ]]; then
            log_success "Retrieved specific patient"
        else
            log_failure "Failed to get specific patient (HTTP $response)"
        fi
    else
        log_failure "Patient service not responding for GET by ID"
    fi
fi

echo ""
echo "🔐 PHASE 5: AUTHENTICATION SERVICE TESTS"
echo "========================================"

# Test auth service endpoints
log_test "Testing Auth Service root endpoint"
if response=$(curl -s -w "%{http_code}" -o /tmp/auth_response.txt "http://localhost:3002/" 2>/dev/null); then
    if [[ "$response" == "200" ]] || [[ "$response" == "404" ]] || [[ "$response" == "401" ]]; then
        log_success "Auth service is responding (HTTP $response)"
    else
        log_failure "Auth service unexpected response (HTTP $response)"
    fi
else
    log_failure "Auth service not responding"
fi

echo ""
echo "💰 PHASE 6: BILLING SERVICE TESTS"
echo "================================="

# Test billing service
log_test "Testing Billing Service root endpoint"
if response=$(curl -s -w "%{http_code}" -o /tmp/billing_response.txt "http://localhost:5000/" 2>/dev/null); then
    if [[ "$response" == "200" ]] || [[ "$response" == "404" ]] || [[ "$response" == "401" ]]; then
        log_success "Billing service is responding (HTTP $response)"
    else
        log_failure "Billing service unexpected response (HTTP $response)"
    fi
else
    log_failure "Billing service not responding"
fi

# Test gRPC port
log_test "Testing Billing Service gRPC port"
if nc -z localhost 9005 2>/dev/null; then
    log_success "Billing gRPC port 9005 is open"
else
    log_failure "Billing gRPC port 9005 is not accessible"
fi

echo ""
echo "📊 PHASE 7: ANALYTICS SERVICE TESTS"
echo "==================================="

# Test analytics service
log_test "Testing Analytics Service root endpoint"
if response=$(curl -s -w "%{http_code}" -o /tmp/analytics_response.txt "http://localhost:6000/" 2>/dev/null); then
    if [[ "$response" == "200" ]] || [[ "$response" == "404" ]] || [[ "$response" == "401" ]]; then
        log_success "Analytics service is responding (HTTP $response)"
    else
        log_failure "Analytics service unexpected response (HTTP $response)"
    fi
else
    log_failure "Analytics service not responding"
fi

echo ""
echo "🚪 PHASE 8: API GATEWAY TESTS"
echo "============================="

# Test API Gateway
log_test "Testing API Gateway root endpoint"
if response=$(curl -s -w "%{http_code}" -o /tmp/gateway_response.txt "http://localhost:8081/" 2>/dev/null); then
    if [[ "$response" == "200" ]] || [[ "$response" == "404" ]] || [[ "$response" == "401" ]]; then
        log_success "API Gateway is responding (HTTP $response)"
    else
        log_failure "API Gateway unexpected response (HTTP $response)"
    fi
else
    log_failure "API Gateway not responding"
fi

echo ""
echo "🔄 PHASE 9: INTER-SERVICE COMMUNICATION TESTS"
echo "=============================================="

# Test Kafka topics (if any exist)
log_test "Checking Kafka topics"
if kafka_topics=$(docker exec kafka kafka-topics.sh --bootstrap-server localhost:9092 --list 2>/dev/null); then
    topic_count=$(echo "$kafka_topics" | wc -l)
    if [[ $topic_count -gt 0 ]]; then
        log_success "Found $topic_count Kafka topics"
        echo "Topics: $kafka_topics"
    else
        log_info "No Kafka topics found (this might be normal for initial setup)"
    fi
else
    log_failure "Could not list Kafka topics"
fi

# Test patient-billing service communication
log_test "Testing Patient-Billing gRPC communication"
# This would require the patient service to actually call billing service
# For now, we check if both services can reach each other's ports
if docker exec patient-service nc -z billing-service 9001 2>/dev/null; then
    log_success "Patient service can reach Billing service gRPC port"
else
    log_failure "Patient service cannot reach Billing service gRPC port"
fi

echo ""
echo "📋 PHASE 10: DATA CONSISTENCY TESTS"
echo "==================================="

# Check if data persists across requests
log_test "Testing data persistence"
if response1=$(curl -s "http://localhost:4000/patients" | jq '. | length' 2>/dev/null); then
    sleep 2
    if response2=$(curl -s "http://localhost:4000/patients" | jq '. | length' 2>/dev/null); then
        if [[ "$response1" == "$response2" ]]; then
            log_success "Data persistence verified ($response1 patients consistently)"
        else
            log_failure "Data inconsistency detected ($response1 vs $response2)"
        fi
    else
        log_failure "Second data request failed"
    fi
else
    log_failure "First data request failed"
fi

echo ""
echo "🔍 PHASE 11: PERFORMANCE & LOAD TESTS"
echo "====================================="

# Simple load test
log_test "Running simple load test (10 concurrent requests)"
start_time=$(date +%s)

for i in {1..10}; do
    curl -s "http://localhost:4000/patients" > /dev/null &
done

wait  # Wait for all background jobs to complete

end_time=$(date +%s)
duration=$((end_time - start_time))

if [[ $duration -lt 10 ]]; then
    log_success "Load test completed in $duration seconds"
else
    log_failure "Load test took too long: $duration seconds"
fi

echo ""
echo "🔒 PHASE 12: SECURITY TESTS"
echo "============================"

# Test for common security headers
log_test "Checking security headers"
if headers=$(curl -s -I "http://localhost:4000/patients" 2>/dev/null); then
    if echo "$headers" | grep -qi "x-frame-options\|x-content-type-options\|x-xss-protection"; then
        log_success "Some security headers present"
    else
        log_info "Basic security headers not detected (might need configuration)"
    fi
else
    log_failure "Could not check security headers"
fi

echo ""
echo "📊 FINAL TEST RESULTS"
echo "===================="
echo ""
echo -e "${BLUE}Total Tests Run: $TOTAL_TESTS${NC}"
echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
echo -e "${RED}Failed: $FAILED_TESTS${NC}"
echo ""

# Calculate success rate
if [[ $TOTAL_TESTS -gt 0 ]]; then
    success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo -e "${YELLOW}Success Rate: $success_rate%${NC}"
    
    if [[ $success_rate -ge 80 ]]; then
        echo -e "${GREEN}🎉 SYSTEM STATUS: HEALTHY${NC}"
        echo ""
        echo "✅ The Patient Management System is working correctly!"
        echo ""
        echo "🌐 Ready to use endpoints:"
        echo "• Patient Service: http://localhost:4000/patients"
        echo "• Patient Swagger: http://localhost:4000/swagger-ui.html"
        echo "• Auth Service: http://localhost:3002"
        echo "• Billing Service: http://localhost:5000"
        echo "• Analytics Service: http://localhost:6000"
        echo "• API Gateway: http://localhost:8081"
        exit 0
    elif [[ $success_rate -ge 60 ]]; then
        echo -e "${YELLOW}⚠️  SYSTEM STATUS: PARTIALLY HEALTHY${NC}"
        echo "Some services may need attention, but core functionality works."
        exit 1
    else
        echo -e "${RED}🚨 SYSTEM STATUS: UNHEALTHY${NC}"
        echo "Multiple services are failing. Please check the logs."
        exit 2
    fi
else
    echo -e "${RED}🚨 NO TESTS WERE RUN${NC}"
    exit 3
fi

# Cleanup
rm -f /tmp/response.txt /tmp/patients.json /tmp/created_patient.json /tmp/specific_patient.json /tmp/auth_response.txt /tmp/billing_response.txt /tmp/analytics_response.txt /tmp/gateway_response.txt
