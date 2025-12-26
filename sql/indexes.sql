USE sanjose_police_calls;

-- Add indexes to improve performance
ALTER TABLE fact_calls_2025 ADD INDEX idx_offense_at (offense_at);
ALTER TABLE fact_calls_2025 ADD INDEX idx_priority (PRIORITY);
ALTER TABLE fact_calls_2025 ADD INDEX idx_calltype (CALLTYPE_CODE);
ALTER TABLE fact_calls_2025 ADD INDEX idx_city_state (CITY_NORM, STATE_NORM);

-- Composite indexes (optional)
ALTER TABLE fact_calls_2025 ADD INDEX idx_priority_offense (PRIORITY, offense_at);
ALTER TABLE fact_calls_2025 ADD INDEX idx_offense_calltype (offense_at, CALLTYPE_CODE);
ALTER TABLE fact_calls_2025 ADD INDEX idx_address_priority (ADDRESS, PRIORITY);
