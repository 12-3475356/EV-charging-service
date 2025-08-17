// package com.example.demo;

// import org.springframework.data.jpa.repository.JpaRepository;

// public interface PersonRepo extends JpaRepository<Person, Long> {
// }


package com.example.demo.repository;

import com.example.demo.model.Person;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PersonRepo extends JpaRepository<Person, Long> {
}

