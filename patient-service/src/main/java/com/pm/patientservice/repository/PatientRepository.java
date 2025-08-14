package com.pm.patientservice.repository;

import com.pm.patientservice.model.Patient;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface PatientRepository extends JpaRepository<Patient, UUID> {
  boolean existsByEmail(String email);
  boolean existsByEmailAndIdNot(String email, UUID id);
  
  // Search functionality
  List<Patient> findByNameContainingIgnoreCase(String name);
  
  @Query("SELECT p FROM Patient p WHERE " +
         "LOWER(p.name) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
         "LOWER(p.email) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
         "LOWER(p.address) LIKE LOWER(CONCAT('%', :searchTerm, '%'))")
  List<Patient> searchPatients(@Param("searchTerm") String searchTerm);
}
