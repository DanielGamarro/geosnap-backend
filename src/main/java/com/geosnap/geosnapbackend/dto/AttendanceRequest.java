package com.geosnap.geosnapbackend.dto;

public class AttendanceRequest {
    private Double latitude;
    private Double longitude;



    public AttendanceRequest(Double latitude, Double longitude) {
        this.latitude = latitude;
        this.longitude = longitude;
    }

    public AttendanceRequest() {}





    public Double getLatitude() {
        return latitude;
    }

    public void setLatitude(double latitude) {
        this.latitude = latitude;
    }

    public Double getLongitude() {
        return longitude;
    }

    public void setLongitude(double longitude) {
        this.longitude = longitude;
    }



}
