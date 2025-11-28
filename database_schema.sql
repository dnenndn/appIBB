-- ========================================================================
-- IBB APP DATABASE SCHEMA
-- ========================================================================
-- This SQL script creates the complete database schema for the IBB Factory
-- Monitoring Application. It includes normalized tables for machines,
-- parameters, alerts, shifts, and related entities.
-- 
-- IMPORTANT: This script is optimized for PostgreSQL (Supabase)
-- ========================================================================

-- Drop existing tables if they exist (for development/testing)
-- Uncomment these lines if you need to reset the database
/*
DROP TABLE IF EXISTS alert_history CASCADE;
DROP TABLE IF EXISTS shift_machine_metrics CASCADE;
DROP TABLE IF EXISTS machine_parameters CASCADE;
DROP TABLE IF EXISTS parameter_thresholds CASCADE;
DROP TABLE IF EXISTS alerts CASCADE;
DROP TABLE IF EXISTS shifts CASCADE;
DROP TABLE IF EXISTS machines CASCADE;
DROP TABLE IF EXISTS parameters CASCADE;
DROP TABLE IF EXISTS users CASCADE;
*/

-- ========================================================================
-- USERS TABLE
-- ========================================================================
CREATE TABLE IF NOT EXISTS users (
  id VARCHAR(50) PRIMARY KEY,
  username VARCHAR(100) NOT NULL UNIQUE,
  email VARCHAR(100) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(50) DEFAULT 'operator',
  status VARCHAR(20) DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ========================================================================
-- MACHINES TABLE
-- ========================================================================
CREATE TABLE IF NOT EXISTS machines (
  id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  type VARCHAR(50) NOT NULL,
  status VARCHAR(20) DEFAULT 'normal',
  priority INT DEFAULT 0,
  production DOUBLE PRECISION DEFAULT 0.0,
  temperature DOUBLE PRECISION DEFAULT 0.0,
  downtime INT DEFAULT 0,
  flow DOUBLE PRECISION DEFAULT 0.0,
  burner_temp DOUBLE PRECISION DEFAULT 0.0,
  energy_consumption DOUBLE PRECISION DEFAULT 0.0,
  avg_cut_per_min DOUBLE PRECISION DEFAULT 0.0,
  last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ========================================================================
-- PARAMETERS TABLE
-- Defines all measurable parameters for machines
-- ========================================================================
CREATE TABLE IF NOT EXISTS parameters (
  id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  unit VARCHAR(20),
  description TEXT,
  parameter_type VARCHAR(50),
  min_value DOUBLE PRECISION,
  max_value DOUBLE PRECISION,
  is_critical BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ========================================================================
-- MACHINE PARAMETERS TABLE
-- Junction table linking machines to their parameters with real-time values
-- ========================================================================
CREATE TABLE IF NOT EXISTS machine_parameters (
  id VARCHAR(50) PRIMARY KEY,
  machine_id VARCHAR(50) NOT NULL,
  parameter_id VARCHAR(50) NOT NULL,
  current_value DOUBLE PRECISION,
  previous_value DOUBLE PRECISION,
  trend_status VARCHAR(20),
  last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (machine_id) REFERENCES machines(id) ON DELETE CASCADE,
  FOREIGN KEY (parameter_id) REFERENCES parameters(id) ON DELETE CASCADE,
  CONSTRAINT unique_machine_parameter UNIQUE (machine_id, parameter_id)
);

-- ========================================================================
-- PARAMETER THRESHOLDS TABLE
-- Stores min/max thresholds for each machine-parameter combination
-- ========================================================================
CREATE TABLE IF NOT EXISTS parameter_thresholds (
  id VARCHAR(50) PRIMARY KEY,
  machine_id VARCHAR(50) NOT NULL,
  parameter_id VARCHAR(50) NOT NULL,
  min_threshold DOUBLE PRECISION,
  max_threshold DOUBLE PRECISION,
  warning_threshold_low DOUBLE PRECISION,
  warning_threshold_high DOUBLE PRECISION,
  alert_type VARCHAR(20),
  is_active BOOLEAN DEFAULT TRUE,
  last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (machine_id) REFERENCES machines(id) ON DELETE CASCADE,
  FOREIGN KEY (parameter_id) REFERENCES parameters(id) ON DELETE CASCADE,
  CONSTRAINT unique_machine_parameter_threshold UNIQUE (machine_id, parameter_id)
);

-- ========================================================================
-- ALERTS TABLE
-- Stores all alert events with detailed information
-- ========================================================================
CREATE TABLE IF NOT EXISTS alerts (
  id VARCHAR(50) PRIMARY KEY,
  machine_id VARCHAR(50) NOT NULL,
  parameter VARCHAR(100) NOT NULL,
  alert_type VARCHAR(50) NOT NULL,
  type VARCHAR(20) NOT NULL,
  severity VARCHAR(20) DEFAULT 'info',
  title VARCHAR(200) NOT NULL,
  description TEXT,
  current_status TEXT,
  current_value DOUBLE PRECISION,
  expected_value DOUBLE PRECISION,
  is_resolved BOOLEAN DEFAULT FALSE,
  auto_dismiss_seconds INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  resolved_at TIMESTAMP NULL,
  FOREIGN KEY (machine_id) REFERENCES machines(id) ON DELETE CASCADE
);

-- ========================================================================
-- ALERT HISTORY TABLE
-- Tracks all alert state changes for auditing and analytics
-- ========================================================================
CREATE TABLE IF NOT EXISTS alert_history (
  id VARCHAR(50) PRIMARY KEY,
  alert_id VARCHAR(50) NOT NULL,
  old_status VARCHAR(20),
  new_status VARCHAR(20),
  old_value DOUBLE PRECISION,
  new_value DOUBLE PRECISION,
  changed_by VARCHAR(50),
  reason TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (alert_id) REFERENCES alerts(id) ON DELETE CASCADE,
  FOREIGN KEY (changed_by) REFERENCES users(id) ON DELETE SET NULL
);

-- ========================================================================
-- SHIFTS TABLE
-- Represents production shifts with metrics and performance data
-- ========================================================================
CREATE TABLE IF NOT EXISTS shifts (
  id VARCHAR(50) PRIMARY KEY,
  shift_date DATE NOT NULL,
  shift_type VARCHAR(50) NOT NULL,
  start_time TIMESTAMP,
  end_time TIMESTAMP,
  duration_minutes INT,
  status VARCHAR(20) DEFAULT 'normal',
  total_production INT DEFAULT 0,
  total_efficiency DOUBLE PRECISION DEFAULT 0.0,
  alert_count INT DEFAULT 0,
  critical_alerts INT DEFAULT 0,
  warning_alerts INT DEFAULT 0,
  info_alerts INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ========================================================================
-- SHIFT MACHINE METRICS TABLE
-- Stores per-machine performance metrics for each shift
-- ========================================================================
CREATE TABLE IF NOT EXISTS shift_machine_metrics (
  id VARCHAR(50) PRIMARY KEY,
  shift_id VARCHAR(50) NOT NULL,
  machine_id VARCHAR(50) NOT NULL,
  machine_name VARCHAR(100),
  efficiency DOUBLE PRECISION DEFAULT 0.0,
  downtime_minutes INT DEFAULT 0,
  production_units INT DEFAULT 0,
  start_time TIMESTAMP,
  end_time TIMESTAMP,
  status VARCHAR(20) DEFAULT 'normal',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (shift_id) REFERENCES shifts(id) ON DELETE CASCADE,
  FOREIGN KEY (machine_id) REFERENCES machines(id) ON DELETE CASCADE,
  CONSTRAINT unique_shift_machine UNIQUE (shift_id, machine_id)
);

-- ========================================================================
-- INDEXES FOR PERFORMANCE
-- ========================================================================
CREATE INDEX IF NOT EXISTS idx_machine_status ON machines(status);
CREATE INDEX IF NOT EXISTS idx_machine_type ON machines(type);
CREATE INDEX IF NOT EXISTS idx_machine_priority ON machines(priority);
CREATE INDEX IF NOT EXISTS idx_parameter_thresholds_machine ON parameter_thresholds(machine_id);
CREATE INDEX IF NOT EXISTS idx_machine_parameters_machine ON machine_parameters(machine_id);
CREATE INDEX IF NOT EXISTS idx_alert_machine_created ON alerts(machine_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_shift_machine_metrics_shift ON shift_machine_metrics(shift_id);
CREATE INDEX IF NOT EXISTS idx_alerts_resolved ON alerts(is_resolved);
CREATE INDEX IF NOT EXISTS idx_shifts_date ON shifts(shift_date DESC);

-- ========================================================================
-- SEED DATA
-- Insert initial reference data and sample machines
-- ========================================================================

-- Insert machines
INSERT INTO machines (id, name, type, status, priority, production, temperature, downtime, flow, burner_temp, energy_consumption, avg_cut_per_min) VALUES
('kiln_01', 'Kiln 1', 'kiln', 'normal', 0, 245.8, 1150.0, 5, 85.3, 1150.0, 245.6, 12.5),
('kiln_02', 'Kiln 2', 'kiln', 'normal', 1, 268.4, 1175.0, 0, 92.1, 1225.0, 312.5, 15.8),
('kiln_03', 'Kiln 3', 'kiln', 'warning', 2, 301.2, 980.0, 15, 78.9, 1020.0, 198.3, 9.7),
('dryer_01', 'Dryer 1', 'dryer', 'normal', 3, 289.5, 142.0, 8, 65.4, 185.0, 156.2, 8.4),
('dryer_02', 'Dryer 2', 'dryer', 'critical', 4, 312.5, 165.0, 45, 48.2, 180.0, 287.9, 11.2),
('dryer_03', 'Dryer 3', 'dryer', 'normal', 5, 275.6, 155.0, 2, 95.8, 210.0, 98.5, 6.3);

-- Insert parameters
INSERT INTO parameters (id, name, unit, description, parameter_type, min_value, max_value, is_critical) VALUES
('param_001', 'Burner Temperature', '°C', 'Temperature of the burner element', 'temperature', 0, 1300, TRUE),
('param_002', 'Zone 1 Temperature', '°C', 'Temperature in zone 1', 'temperature', 0, 1100, FALSE),
('param_003', 'Zone 2 Temperature', '°C', 'Temperature in zone 2', 'temperature', 0, 1200, FALSE),
('param_004', 'Cooling Zone Temp', '°C', 'Temperature in cooling zone', 'temperature', 0, 600, FALSE),
('param_005', 'Production Rate', 'units/hour', 'Number of units produced per hour', 'production', 0, 2000, FALSE),
('param_006', 'Average Cut/Min', 'cuts/min', 'Average cuts per minute', 'production', 0, 100, FALSE),
('param_007', 'Downtime', 'minutes', 'Machine downtime in minutes', 'production', 0, 1440, TRUE),
('param_008', 'Efficiency', '%', 'Machine efficiency percentage', 'production', 0, 100, FALSE),
('param_009', 'Flow Rate', 'm³/h', 'Flow rate measurement', 'flow', 0, 200, FALSE),
('param_010', 'Energy Consumption', 'kWh', 'Energy consumed by machine', 'energy', 0, 500, FALSE);

-- Insert parameter thresholds for machines
INSERT INTO parameter_thresholds (id, machine_id, parameter_id, min_threshold, max_threshold, warning_threshold_low, warning_threshold_high, alert_type, is_active) VALUES
('threshold_001', 'kiln_01', 'param_001', 700, 1200, 750, 1150, 'temperature', TRUE),
('threshold_002', 'kiln_01', 'param_005', 200, 1500, 400, 1300, 'production', TRUE),
('threshold_003', 'kiln_01', 'param_009', 50, 100, 60, 95, 'flow', TRUE),
('threshold_004', 'dryer_01', 'param_001', 100, 250, 120, 220, 'temperature', TRUE),
('threshold_005', 'dryer_01', 'param_009', 40, 120, 50, 100, 'flow', TRUE);

-- Insert shifts
INSERT INTO shifts (id, shift_date, shift_type, start_time, end_time, duration_minutes, status, total_production, total_efficiency, alert_count, critical_alerts, warning_alerts, info_alerts) VALUES
('shift_001', '2025-11-22', 'Morning', '2025-11-22 06:00:00', '2025-11-22 14:00:00', 480, 'normal', 12450, 92.0, 3, 0, 2, 1),
('shift_002', '2025-11-22', 'Afternoon', '2025-11-22 14:00:00', '2025-11-22 22:00:00', 480, 'warning', 11890, 88.0, 5, 1, 3, 1),
('shift_003', '2025-11-22', 'Night', '2025-11-22 22:00:00', '2025-11-23 06:00:00', 480, 'critical', 10230, 76.0, 8, 3, 4, 1),
('shift_004', '2025-11-21', 'Morning', '2025-11-21 06:00:00', '2025-11-21 14:00:00', 480, 'normal', 12680, 94.0, 2, 0, 1, 1),
('shift_005', '2025-11-21', 'Afternoon', '2025-11-21 14:00:00', '2025-11-21 22:00:00', 480, 'normal', 12340, 91.0, 2, 0, 1, 1);

-- Insert shift machine metrics
INSERT INTO shift_machine_metrics (id, shift_id, machine_id, machine_name, efficiency, downtime_minutes, production_units, status) VALUES
('shift_metric_001', 'shift_001', 'kiln_01', 'Kiln 1', 94, 2, 4150, 'normal'),
('shift_metric_002', 'shift_001', 'kiln_02', 'Kiln 2', 90, 5, 4100, 'normal'),
('shift_metric_003', 'shift_001', 'dryer_01', 'Dryer 1', 92, 3, 4200, 'normal'),
('shift_metric_004', 'shift_002', 'kiln_01', 'Kiln 1', 89, 8, 3950, 'warning'),
('shift_metric_005', 'shift_002', 'kiln_02', 'Kiln 2', 87, 10, 3900, 'warning'),
('shift_metric_006', 'shift_002', 'dryer_01', 'Dryer 1', 88, 6, 4040, 'normal');

-- Insert alerts
INSERT INTO alerts (id, machine_id, parameter, alert_type, type, severity, title, description, current_status, current_value, is_resolved) VALUES
('alert_001', 'kiln_01', 'burner_temperature', 'Temperature Exceeded', 'critical', 'critical', 'Temperature Exceeded', 'Burner temperature at 1250°C (Max: 1200°C)', 'Burner temperature at 1250°C (Max: 1200°C)', 1250.0, FALSE),
('alert_002', 'dryer_02', 'flow_rate', 'Low Flow Rate', 'warning', 'warning', 'Low Flow Rate', 'Flow rate at 45 m³/h (Min: 50 m³/h)', 'Flow rate at 45 m³/h (Min: 50 m³/h)', 45.0, FALSE),
('alert_003', 'kiln_02', 'machine_status', 'Machine Started', 'status', 'info', 'Machine Started', 'Machine resumed operation after maintenance', 'Machine resumed operation after maintenance', NULL, TRUE),
('alert_004', 'dryer_01', 'machine_status', 'Emergency Stop', 'critical', 'critical', 'Emergency Stop', 'Machine stopped due to safety sensor trigger', 'Machine stopped due to safety sensor trigger', NULL, FALSE),
('alert_005', 'kiln_03', 'energy_consumption', 'High Energy Consumption', 'warning', 'warning', 'High Energy Consumption', 'Energy usage at 125 kWh (Avg: 100 kWh)', 'Energy usage at 125 kWh (Avg: 100 kWh)', 125.0, TRUE),
('alert_006', 'dryer_03', 'maintenance', 'Maintenance Scheduled', 'status', 'info', 'Maintenance Scheduled', 'Routine maintenance scheduled for tomorrow', 'Routine maintenance scheduled for tomorrow', NULL, FALSE);

-- ========================================================================
-- VIEWS FOR COMMON QUERIES
-- ========================================================================

-- View for current machine status with alert counts
CREATE OR REPLACE VIEW v_machine_status AS
SELECT 
  m.id,
  m.name,
  m.type,
  m.status,
  m.production,
  m.temperature,
  m.downtime,
  COUNT(CASE WHEN a.is_resolved = FALSE AND a.type = 'critical' THEN 1 END) as critical_alerts,
  COUNT(CASE WHEN a.is_resolved = FALSE AND a.type = 'warning' THEN 1 END) as warning_alerts,
  COUNT(CASE WHEN a.is_resolved = FALSE THEN 1 END) as total_unresolved_alerts,
  m.last_updated
FROM machines m
LEFT JOIN alerts a ON m.id = a.machine_id
GROUP BY m.id, m.name, m.type, m.status, m.production, m.temperature, m.downtime, m.last_updated;

-- View for shift performance summary
CREATE OR REPLACE VIEW v_shift_summary AS
SELECT 
  s.id,
  s.shift_date,
  s.shift_type,
  s.status,
  s.total_production,
  s.total_efficiency,
  s.alert_count,
  s.critical_alerts,
  s.warning_alerts,
  COUNT(DISTINCT smm.machine_id) as machines_involved,
  AVG(smm.efficiency) as avg_machine_efficiency
FROM shifts s
LEFT JOIN shift_machine_metrics smm ON s.id = smm.shift_id
GROUP BY s.id, s.shift_date, s.shift_type, s.status, s.total_production, s.total_efficiency, s.alert_count, s.critical_alerts, s.warning_alerts;

-- View for active threshold violations
CREATE OR REPLACE VIEW v_threshold_violations AS
SELECT 
  mp.machine_id,
  m.name as machine_name,
  mp.parameter_id,
  p.name as parameter_name,
  p.unit,
  mp.current_value,
  pt.min_threshold,
  pt.max_threshold,
  CASE 
    WHEN mp.current_value < pt.min_threshold THEN 'Below Min'
    WHEN mp.current_value > pt.max_threshold THEN 'Above Max'
    ELSE 'Normal'
  END as violation_status,
  mp.last_updated
FROM machine_parameters mp
JOIN machines m ON mp.machine_id = m.id
JOIN parameters p ON mp.parameter_id = p.id
JOIN parameter_thresholds pt ON mp.machine_id = pt.machine_id AND mp.parameter_id = pt.parameter_id
WHERE (mp.current_value < pt.min_threshold OR mp.current_value > pt.max_threshold)
  AND pt.is_active = TRUE;

-- ========================================================================
-- END OF SCHEMA
-- ========================================================================
