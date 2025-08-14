package com.pm.patientservice.controller;

import com.pm.patientservice.dto.PatientRequestDTO;
import com.pm.patientservice.dto.PatientResponseDTO;
import com.pm.patientservice.service.PatientService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/patients")
@Tag(name = "Patient", description = "API for managing Patients")
public class PatientController {

  private final PatientService patientService;

  public PatientController(PatientService patientService) {
    this.patientService = patientService;
  }

  @GetMapping
  @Operation(summary = "Get Patients")
  public ResponseEntity<List<PatientResponseDTO>> getPatients() {
    List<PatientResponseDTO> patients = patientService.getPatients();
    return ResponseEntity.ok().body(patients);
  }

  // Get patient by ID
  @GetMapping("/{id}")
  @Operation(summary = "Get Patient by ID")
  public ResponseEntity<PatientResponseDTO> getPatientById(@PathVariable UUID id) {
    PatientResponseDTO patient = patientService.getPatientById(id);
    return ResponseEntity.ok().body(patient);
  }

  // Search functionality
  @GetMapping("/search")
  @Operation(summary = "Search Patients")
  public ResponseEntity<List<PatientResponseDTO>> searchPatients(
      @RequestParam(required = false) String name,
      @RequestParam(required = false) String q) {
    
    List<PatientResponseDTO> patients;
    if (name != null && !name.trim().isEmpty()) {
      patients = patientService.searchPatientsByName(name);
    } else if (q != null && !q.trim().isEmpty()) {
      patients = patientService.searchPatients(q);
    } else {
      patients = patientService.getPatients();
    }
    
    return ResponseEntity.ok().body(patients);
  }

  // Count functionality
  @GetMapping("/count")
  @Operation(summary = "Get Patient Count")
  public ResponseEntity<Map<String, Long>> getPatientCount() {
    long count = patientService.getPatientCount();
    return ResponseEntity.ok().body(Map.of("count", count, "total", count));
  }

  @PostMapping
  @Operation(summary = "Create a new Patient")
  public ResponseEntity<PatientResponseDTO> createPatient(
      @Validated @RequestBody PatientRequestDTO patientRequestDTO) {

    PatientResponseDTO patientResponseDTO = patientService.createPatient(
        patientRequestDTO);

    return ResponseEntity.ok().body(patientResponseDTO);
  }

  @PutMapping("/{id}")
  @Operation(summary = "Update a new Patient")
  public ResponseEntity<PatientResponseDTO> updatePatient(@PathVariable UUID id,
      @Validated @RequestBody PatientRequestDTO patientRequestDTO) {

    PatientResponseDTO patientResponseDTO = patientService.updatePatient(id,
        patientRequestDTO);

    return ResponseEntity.ok().body(patientResponseDTO);
  }

  @DeleteMapping("/{id}")
  @Operation(summary = "Delete a Patient")
  public ResponseEntity<Void> deletePatient(@PathVariable UUID id) {
    patientService.deletePatient(id);
    return ResponseEntity.noContent().build();
  }
}
