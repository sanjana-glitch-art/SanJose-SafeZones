CREATE DATABASE IF NOT EXISTS sanjose_police_calls;
USE sanjose_police_calls;

-- Disable safe update mode
SET SQL_SAFE_UPDATES = 0;

-- Capture active DB
SET @db := DATABASE();

-- Create FACT table (1NF)
CREATE TABLE IF NOT EXISTS fact_calls_2025 (
  call_id      BIGINT AUTO_INCREMENT PRIMARY KEY,
  EID          BIGINT NULL,
  CALL_NUMBER  VARCHAR(50) NULL,
  offense_at   DATETIME NULL,
  PRIORITY     INT NULL,
  CALLTYPE_CODE     VARCHAR(20),
  FINAL_DISPO_CODE  VARCHAR(20),
  CITY_NORM         VARCHAR(100),
  STATE_NORM        VARCHAR(50),
  ADDRESS      VARCHAR(255),
  KEY idx_offense_at (offense_at),
  KEY idx_city_state (CITY_NORM, STATE_NORM),
  KEY idx_calltype   (CALLTYPE_CODE),
  KEY idx_priority   (PRIORITY)
) ENGINE=InnoDB;

-- Create DIM tables (2NF)
CREATE TABLE IF NOT EXISTS dim_calltype (
  CALLTYPE_CODE VARCHAR(20) PRIMARY KEY,
  CALL_TYPE     VARCHAR(150) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS dim_disposition (
  FINAL_DISPO_CODE VARCHAR(20) PRIMARY KEY,
  FINAL_DISPO      VARCHAR(150) NOT NULL
) ENGINE=InnoDB;
