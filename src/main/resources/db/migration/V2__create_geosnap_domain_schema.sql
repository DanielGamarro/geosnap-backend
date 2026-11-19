ALTER TABLE companies
    ADD COLUMN active BOOLEAN NOT NULL DEFAULT true,
    ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX uq_users_email_lower
    ON users (LOWER(email));

CREATE TABLE company_memberships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    user_id UUID NOT NULL,
    role VARCHAR(30) NOT NULL,
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_company_memberships_company_user
        UNIQUE (company_id, user_id),
    CONSTRAINT chk_company_memberships_role
        CHECK (role IN ('EMPLOYEE', 'SUPERVISOR', 'COMPANY_ADMIN', 'SYSTEM_ADMIN')),
    CONSTRAINT fk_company_memberships_company
        FOREIGN KEY (company_id)
        REFERENCES companies(id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_company_memberships_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE RESTRICT
);

CREATE INDEX idx_company_memberships_user_active
    ON company_memberships(user_id, active);

CREATE INDEX idx_company_memberships_company_active
    ON company_memberships(company_id, active);

CREATE TABLE work_locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    name VARCHAR(150) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    radius_meters INTEGER NOT NULL,
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_work_locations_latitude
        CHECK (latitude BETWEEN -90 AND 90),
    CONSTRAINT chk_work_locations_longitude
        CHECK (longitude BETWEEN -180 AND 180),
    CONSTRAINT chk_work_locations_radius
        CHECK (radius_meters BETWEEN 1 AND 100000),
    CONSTRAINT fk_work_locations_company
        FOREIGN KEY (company_id)
        REFERENCES companies(id)
        ON DELETE RESTRICT
);

CREATE INDEX idx_work_locations_company_active
    ON work_locations(company_id, active);

CREATE TABLE devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    platform VARCHAR(20) NOT NULL,
    device_model VARCHAR(100),
    os_version VARCHAR(50),
    device_identifier_hash VARCHAR(64) NOT NULL,
    push_token_hash VARCHAR(64),
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_seen_at TIMESTAMPTZ,
    CONSTRAINT uq_devices_user_identifier
        UNIQUE (user_id, device_identifier_hash),
    CONSTRAINT chk_devices_platform
        CHECK (platform IN ('ANDROID', 'IOS', 'WEB')),
    CONSTRAINT chk_devices_identifier_hash
        CHECK (device_identifier_hash ~ '^[0-9a-fA-F]{64}$'),
    CONSTRAINT fk_devices_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE RESTRICT
);

CREATE INDEX idx_devices_user_active
    ON devices(user_id, active);

CREATE TABLE attendance_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    user_id UUID NOT NULL,
    work_location_id UUID,
    device_id UUID,
    type VARCHAR(20) NOT NULL,
    status VARCHAR(30) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    distance_meters INTEGER,
    accuracy_meters DOUBLE PRECISION,
    mock_location_detected BOOLEAN,
    camera_capture_valid BOOLEAN,
    occurred_at TIMESTAMPTZ NOT NULL,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    synced_at TIMESTAMPTZ,
    client_request_id VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_attendance_records_company_request
        UNIQUE (company_id, client_request_id),
    CONSTRAINT chk_attendance_records_type
        CHECK (type IN ('CHECK_IN', 'CHECK_OUT', 'BREAK_START', 'BREAK_END')),
    CONSTRAINT chk_attendance_records_status
        CHECK (status IN (
            'VALID',
            'OUTSIDE_RADIUS',
            'MOCK_LOCATION',
            'INVALID_CAPTURE',
            'INVALID_DEVICE',
            'PENDING_REVIEW',
            'REJECTED'
        )),
    CONSTRAINT chk_attendance_records_latitude
        CHECK (latitude BETWEEN -90 AND 90),
    CONSTRAINT chk_attendance_records_longitude
        CHECK (longitude BETWEEN -180 AND 180),
    CONSTRAINT chk_attendance_records_distance
        CHECK (distance_meters IS NULL OR distance_meters >= 0),
    CONSTRAINT chk_attendance_records_accuracy
        CHECK (accuracy_meters IS NULL OR accuracy_meters >= 0),
    CONSTRAINT fk_attendance_records_company
        FOREIGN KEY (company_id)
        REFERENCES companies(id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_attendance_records_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_attendance_records_location
        FOREIGN KEY (work_location_id)
        REFERENCES work_locations(id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_attendance_records_device
        FOREIGN KEY (device_id)
        REFERENCES devices(id)
        ON DELETE RESTRICT
);

CREATE INDEX idx_attendance_records_company_occurred
    ON attendance_records(company_id, occurred_at DESC);

CREATE INDEX idx_attendance_records_user_occurred
    ON attendance_records(user_id, occurred_at DESC);

CREATE INDEX idx_attendance_records_location_occurred
    ON attendance_records(work_location_id, occurred_at DESC);

CREATE INDEX idx_attendance_records_status
    ON attendance_records(status);

CREATE INDEX idx_attendance_records_device_occurred
    ON attendance_records(device_id, occurred_at DESC);

CREATE TABLE attendance_evidences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    attendance_record_id UUID NOT NULL,
    s3_bucket VARCHAR(255) NOT NULL,
    s3_object_key VARCHAR(500) NOT NULL,
    content_type VARCHAR(100) NOT NULL,
    file_size_bytes BIGINT,
    sha256 VARCHAR(64),
    upload_status VARCHAR(20) NOT NULL,
    presigned_url_expires_at TIMESTAMPTZ,
    uploaded_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_attendance_evidences_object_key
        UNIQUE (s3_bucket, s3_object_key),
    CONSTRAINT uq_attendance_evidences_attendance
        UNIQUE (attendance_record_id),
    CONSTRAINT chk_attendance_evidences_file_size
        CHECK (file_size_bytes IS NULL OR file_size_bytes > 0),
    CONSTRAINT chk_attendance_evidences_upload_status
        CHECK (upload_status IN ('PENDING', 'UPLOADED', 'FAILED', 'DELETED')),
    CONSTRAINT chk_attendance_evidences_sha256
        CHECK (sha256 IS NULL OR sha256 ~ '^[0-9a-fA-F]{64}$'),
    CONSTRAINT fk_attendance_evidences_attendance
        FOREIGN KEY (attendance_record_id)
        REFERENCES attendance_records(id)
        ON DELETE RESTRICT
);

CREATE INDEX idx_attendance_evidences_upload_status
    ON attendance_evidences(upload_status);

CREATE TABLE sync_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    attendance_record_id UUID NOT NULL,
    device_id UUID,
    sync_attempt INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL,
    http_status INTEGER,
    error_code VARCHAR(100),
    error_message TEXT,
    attempted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at TIMESTAMPTZ,
    CONSTRAINT uq_sync_events_record_attempt
        UNIQUE (attendance_record_id, sync_attempt),
    CONSTRAINT chk_sync_events_attempt
        CHECK (sync_attempt >= 1),
    CONSTRAINT chk_sync_events_status
        CHECK (status IN ('IN_PROGRESS', 'SUCCESS', 'REJECTED', 'FAILED')),
    CONSTRAINT chk_sync_events_http_status
        CHECK (http_status IS NULL OR http_status BETWEEN 100 AND 599),
    CONSTRAINT fk_sync_events_attendance
        FOREIGN KEY (attendance_record_id)
        REFERENCES attendance_records(id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_sync_events_device
        FOREIGN KEY (device_id)
        REFERENCES devices(id)
        ON DELETE RESTRICT
);

CREATE INDEX idx_sync_events_attendance_attempt
    ON sync_events(attendance_record_id, sync_attempt DESC);

CREATE INDEX idx_sync_events_status
    ON sync_events(status);

CREATE TABLE attendance_audit_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    attendance_record_id UUID,
    user_id UUID,
    event_type VARCHAR(50) NOT NULL,
    passed BOOLEAN NOT NULL,
    details JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_attendance_audit_events_event_type
        CHECK (event_type IN (
            'GEOFENCE_CHECK',
            'MOCK_LOCATION_CHECK',
            'REAL_TIME_CAPTURE_CHECK',
            'DUPLICATE_REQUEST_CHECK',
            'DEVICE_CHECK',
            'MEMBERSHIP_CHECK',
            'S3_UPLOAD_CHECK',
            'MANUAL_REVIEW',
            'STATUS_CHANGE'
        )),
    CONSTRAINT fk_attendance_audit_events_attendance
        FOREIGN KEY (attendance_record_id)
        REFERENCES attendance_records(id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_attendance_audit_events_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE RESTRICT
);

CREATE INDEX idx_attendance_audit_events_attendance
    ON attendance_audit_events(attendance_record_id, created_at DESC);

CREATE INDEX idx_attendance_audit_events_user
    ON attendance_audit_events(user_id, created_at DESC);

CREATE INDEX idx_attendance_audit_events_type
    ON attendance_audit_events(event_type);
