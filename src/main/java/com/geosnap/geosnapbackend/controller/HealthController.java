package com.geosnap.geosnapbackend.controller;


import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/health")
public class HealthController {

    @GetMapping
    public Map<String,Object> checkHealth() {

        return Map.of("status","up",
                "service","geosnapAPI",
                "timestamp", LocalDateTime.now());
    }



}
