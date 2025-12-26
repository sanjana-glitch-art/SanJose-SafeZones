USE sanjose_police_calls;

-- Load cleaned + parsed data into fact table (3NF)
INSERT INTO fact_calls_2025
  (EID, CALL_NUMBER, offense_at, PRIORITY,
   CALLTYPE_CODE, FINAL_DISPO_CODE, ADDRESS)
SELECT
  r.EID,
  r.CALL_NUMBER,
  CASE
     WHEN r.offense_dt IS NOT NULL AND r.offense_tm IS NOT NULL
       THEN TIMESTAMP(r.offense_dt, r.offense_tm)
     WHEN r.offense_dt IS NOT NULL
       THEN r.offense_dt
     ELSE NULL
   END AS offense_at,
   CAST(NULLIF(r.PRIORITY,'') AS SIGNED),
   r.CALLTYPE_CODE,
   r.FINAL_DISPO_CODE,
   r.ADDRESS
FROM policecalls2025_2 r;
