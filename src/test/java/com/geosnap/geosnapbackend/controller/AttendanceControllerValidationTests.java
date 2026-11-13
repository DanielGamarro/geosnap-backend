package com.geosnap.geosnapbackend.controller;

import com.geosnap.geosnapbackend.service.GeofencingService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.validation.beanvalidation.LocalValidatorFactoryBean;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class AttendanceControllerValidationTests {

    private LocalValidatorFactoryBean validator;
    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        validator = new LocalValidatorFactoryBean();
        validator.afterPropertiesSet();
        mockMvc = MockMvcBuilders
                .standaloneSetup(new AttendanceController(new GeofencingService()))
                .setValidator(validator)
                .build();
    }

    @AfterEach
    void tearDown() {
        validator.close();
    }

    @Test
    void validateAttendanceAcceptsValidCoordinates() throws Exception {
        mockMvc.perform(post("/api/v1/attendance/validate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"latitude": 37.2831, "longitude": -5.9250}
                                """))
                .andExpect(status().isOk());
    }

    @Test
    void validateAttendanceRejectsMissingCoordinates() throws Exception {
        mockMvc.perform(post("/api/v1/attendance/validate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"latitude": 37.2831}
                                """))
                .andExpect(status().isBadRequest());
    }

    @Test
    void validateAttendanceRejectsCoordinatesOutsideValidRanges() throws Exception {
        mockMvc.perform(post("/api/v1/attendance/validate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"latitude": 91.0, "longitude": -5.9250}
                                """))
                .andExpect(status().isBadRequest());
    }
}
