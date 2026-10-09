package com.geosnap.geosnapbackend.controller;

import com.geosnap.geosnapbackend.dto.AttendanceRequest;
import com.geosnap.geosnapbackend.service.GeofencingService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/attendance")
public class AttendanceController {

    // Mock target location (headquarters / site)
    private static final double TARGET_LATITUDE = 37.2831;
    private static final double TARGET_LONGITUDE = -5.9250;
    private static final double ALLOWED_RADIUS_METERS = 50.0;

    private final GeofencingService geofencingService;

    public AttendanceController(GeofencingService geofencingService) {
        this.geofencingService = geofencingService;
    }

    @PostMapping("/validate")
    public ResponseEntity<?> validateAttendance(@RequestBody AttendanceRequest request) {

        double distance = geofencingService.calculateDistanceInMeters(
                request.getLatitude(),
                request.getLongitude(),
                TARGET_LATITUDE,
                TARGET_LONGITUDE
        );

        if (distance <= ALLOWED_RADIUS_METERS) {
            return ResponseEntity.ok(Map.of(
                    "status", "VALID",
                    "message", "Attendance registered within allowed area.",
                    "distanceMeters", Math.round(distance)
            ));
        } else {
            return ResponseEntity.badRequest().body(Map.of(
                    "status", "REJECTED",
                    "message", "Outside the authorized radius.",
                    "distanceMeters", Math.round(distance),
                    "allowedRadiusMeters", ALLOWED_RADIUS_METERS
            ));
        }
    }
}