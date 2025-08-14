package com.pm.patientservice.service;

import com.pm.patientservice.dto.PatientRequestDTO;
import com.pm.patientservice.dto.PatientResponseDTO;
import com.pm.patientservice.exception.EmailAlreadyExistsException;
import com.pm.patientservice.exception.PatientNotFoundException;
import com.pm.patientservice.grpc.BillingServiceGrpcClient;
import com.pm.patientservice.kafka.KafkaProducer;
import com.pm.patientservice.mapper.PatientMapper;
import com.pm.patientservice.model.Patient;
import com.pm.patientservice.repository.PatientRepository;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;

@Service
public class PatientService {

  private final PatientRepository patientRepository;
  private final BillingServiceGrpcClient billingServiceGrpcClient;
  private final KafkaProducer kafkaProducer;

  public PatientService(PatientRepository patientRepository,
      BillingServiceGrpcClient billingServiceGrpcClient,
      KafkaProducer kafkaProducer) {
    this.patientRepository = patientRepository;
    this.billingServiceGrpcClient = billingServiceGrpcClient;
    this.kafkaProducer = kafkaProducer;
  }

  public List<PatientResponseDTO> getPatients() {
    List<Patient> patients = patientRepository.findAll();

    return patients.stream().map(PatientMapper::toDTO).toList();
  }

  public PatientResponseDTO createPatient(PatientRequestDTO patientRequestDTO) {
    if (patientRepository.existsByEmail(patientRequestDTO.getEmail())) {
      throw new EmailAlreadyExistsException(
          "A patient with this email " + "already exists"
              + patientRequestDTO.getEmail());
    }

    Patient newPatient = patientRepository.save(
        PatientMapper.toModel(patientRequestDTO));

    billingServiceGrpcClient.createBillingAccount(newPatient.getId().toString(),
        newPatient.getName(), newPatient.getEmail());

    kafkaProducer.sendEvent(newPatient);

    return PatientMapper.toDTO(newPatient);
  }

  public PatientResponseDTO updatePatient(UUID id,
      PatientRequestDTO patientRequestDTO) {

    Patient patient = patientRepository.findById(id).orElseThrow(
        () -> new PatientNotFoundException("Patient not found with ID: " + id));

    if (patientRepository.existsByEmailAndIdNot(patientRequestDTO.getEmail(),
        id)) {
      throw new EmailAlreadyExistsException(
          "A patient with this email " + "already exists"
              + patientRequestDTO.getEmail());
    }

    patient.setName(patientRequestDTO.getName());
    patient.setAddress(patientRequestDTO.getAddress());
    patient.setEmail(patientRequestDTO.getEmail());
    patient.setDateOfBirth(LocalDate.parse(patientRequestDTO.getDateOfBirth()));

    Patient updatedPatient = patientRepository.save(patient);
    return PatientMapper.toDTO(updatedPatient);
  }

  public void deletePatient(UUID id) {
    patientRepository.deleteById(id);
  }

  // Search functionality
  public List<PatientResponseDTO> searchPatients(String searchTerm) {
    List<Patient> patients;
    if (searchTerm == null || searchTerm.trim().isEmpty()) {
      patients = patientRepository.findAll();
    } else {
      patients = patientRepository.searchPatients(searchTerm.trim());
    }
    return patients.stream().map(PatientMapper::toDTO).toList();
  }

  public List<PatientResponseDTO> searchPatientsByName(String name) {
    List<Patient> patients = patientRepository.findByNameContainingIgnoreCase(name);
    return patients.stream().map(PatientMapper::toDTO).toList();
  }

  // Count functionality
  public long getPatientCount() {
    return patientRepository.count();
  }

  // Get patient by ID
  public PatientResponseDTO getPatientById(UUID id) {
    Patient patient = patientRepository.findById(id).orElseThrow(
        () -> new PatientNotFoundException("Patient not found with ID: " + id));
    return PatientMapper.toDTO(patient);
  }
}
