// package com.example.demo;

// import org.springframework.http.ResponseEntity; // <-- Missing import
// import org.springframework.web.bind.annotation.PostMapping;
// import org.springframework.web.bind.annotation.RequestBody;
// import org.springframework.web.bind.annotation.RestController;

// @RestController
// public class PersonController {

//     private final PersonRepo personRepo;

//     public PersonController(PersonRepo personRepo) {
//         this.personRepo = personRepo;
//     }

//     @PostMapping("/addPerson")
//     public ResponseEntity<Person> createPerson(@RequestBody Person person) {
//         Person savedPerson = personRepo.save(person);
//         return ResponseEntity.ok(savedPerson);
//     }
// }


package com.example.demo.controller;

import com.example.demo.model.Person;
import com.example.demo.repository.PersonRepo;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@CrossOrigin(origins = "*") // allow Flutter requests
@RestController
@RequestMapping("/api/person")
public class PersonController {

    
    @Autowired
    private PersonRepo personRepo;

    @PostMapping
    public Person createPerson(@RequestBody Person person) {
        return personRepo.save(person);
    }
}
    