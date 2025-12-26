# SanJose-SafeZones
Police Calls Data Engineering, Analytics & Interactive Dashboard

# ✨ OVERVIEW
San José Safe Zones is an end-to-end data engineering and analytics project that transforms raw San José Police Calls for Service (2025) data into a fully cleaned, normalized, and query-optimized relational database. It then applies advanced SQL analytics to identify safer residential zones, detect incident hotspots, and uncover temporal and spatial patterns in police activity. An interactive Streamlit dashboard brings these insights to life with dynamic visualizations powered by Plotly.

# 🧱 Tech Stack
    Database - MySQL 
    Data Processing - SQL, Python
    Visualization - Plotly, Streamlit
    Backend - MySQL Connector
    Modeling - Window Functions, Statistical Analysis
    Deployment - Streamlit

 # 📂 Repository structure
    SanJose-SafeZones/
    │
    ├── README.md
    │
    ├── sql/
    │   ├── 01_schema_creation.sql
    │   ├── 02_data_cleaning.sql
    │   ├── 03_dimension_tables.sql
    │   ├── 04_fact_table_load.sql
    │   ├── 05_indexes.sql
    │   ├── 06_basic_queries.sql
    │   ├── 07_advanced_queries.sql 
    │   └── 08_views_and_optimization.sql 
    │
    ├── dashboard/
    │   ├── app.py
    │   ├── requirements.txt
    │   └── utils/
    │       └── db_connection.py
    │
    ├── docs/
    │   ├── final_report.pdf
    │   ├── ERD.png
    │   └── schema_diagram.png
    │
    ├── images/
    │   ├── dashboard_screenshots/
    │   └── visualizations/
    │
    └── data/
    ├── raw/ (optional sample)
    └── processed/

# Database Architecture

  ⭐ Star Schema (3NF‑aligned)
      
      Fact Table: fact_calls_2025
      Stores measurable events (each police call)
      Includes standardized timestamps, priority, address, and foreign keys

      Dimension Tables:
      dim_calltype — call type code → description
      dim_disposition — disposition code → description

  # 🧹 Data Cleaning and Processing

Issues Identified
    - Inconsistent date-time formats
    - Leading/trailing whitespace
    - Empty strings vs NULL
    - Mixed data types (e.g., priority stored as text)
    - Redundant descriptive fields

Cleaning Steps
    - Standardized all timestamps using STR_TO_DATE + regex
    - Trimmed whitespace across all text fields
    - Converted empty strings → NULL
    - Casted numeric fields
    - Extracted unique call types & dispositions into dimension tables

# 📈 SQL Analytics

Basic Queries
    - Daily call volume
    - Top 10 call types
    - Average priority by disposition
    - Call volume by zip code
    - Average response time by priority

Advanced Queries
    - Hotspot detection (Top 15 severe addresses)
    - 7‑day rolling averages
    - Month‑over‑month trends with running totals
    - Reusable disposition performance view
    - Index optimization analysis
    - Predictive risk scoring (180‑day weighted model)
    - Percentile analysis (P50–P99)
    - Cross‑tab heatmap (hour × day)
    - Pareto analysis (80/20 rule)
    - Incident co‑occurrence detection

# 📊 Interactive Dashboard (Streamlit)

1. Install dependencies

       pip install -r dashboard/requirements.txt

2. Launch Streamlit

        streamlit run dashboard/app.py


# 📘 Documentation

Full project report:
    
    /docs/final_report.pdf

ER Diagram:
    
    /docs/ERD.png


# 👨‍💻 Author
Sai Teja Sri Sanjana Thummalapalli

For questions or feedback about this project, please contact through GitHub issues.




