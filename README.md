# SanJose-SafeZones
Police Calls Data Engineering, Analytics & Interactive Dashboard

# OVERVIEW
San José Safe Zones is an end-to-end data engineering and analytics project that transforms raw San José Police Calls for Service (2025) data into a fully cleaned, normalized, and query-optimized relational database. It then applies advanced SQL analytics to identify safer residential zones, detect incident hotspots, and uncover temporal and spatial patterns in police activity. An interactive Streamlit dashboard brings these insights to life with dynamic visualizations powered by Plotly.

# Tech Stack
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
    ├── LICENSE
    ├── .gitignore
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

  


