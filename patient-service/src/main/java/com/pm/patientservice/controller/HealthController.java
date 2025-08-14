package com.pm.patientservice.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.time.LocalDateTime;
import java.util.Map;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@Tag(name = "Health", description = "Health Check API")
public class HealthController {

  @GetMapping("/health")
  @Operation(summary = "Basic Health Check")
  public ResponseEntity<Map<String, Object>> health() {
    return ResponseEntity.ok().body(Map.of(
        "status", "UP",
        "service", "patient-service",
        "timestamp", LocalDateTime.now(),
        "version", "1.0.0"
    ));
  }

  @GetMapping("/actuator/health")
  @Operation(summary = "Actuator-style Health Check")
  public ResponseEntity<Map<String, Object>> actuatorHealth() {
    return ResponseEntity.ok().body(Map.of(
        "status", "UP",
        "components", Map.of(
            "db", Map.of("status", "UP"),
            "diskSpace", Map.of("status", "UP"),
            "ping", Map.of("status", "UP")
        )
    ));
  }

  @GetMapping("/info")
  @Operation(summary = "Service Information")
  public ResponseEntity<Map<String, Object>> info() {
    return ResponseEntity.ok().body(Map.of(
        "app", Map.of(
            "name", "Patient Management Service",
            "description", "Microservice for managing patient data",
            "version", "1.0.0"
        ),
        "build", Map.of(
            "time", "2025-07-15T06:00:00Z",
            "artifact", "patient-service",
            "group", "com.pm"
        )
    ));
  }
}
