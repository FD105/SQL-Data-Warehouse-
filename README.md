# SQL-Data-Warehouse

Project about building a data warehouse with SQL-Server, using ETL processes, data modeling, and analytics.

---

## Project Requirements:
Building the Data Warehouse

This step includes the developement of the data warehouse using SQL-Server where the sales data will be combined. Analyzing this data enables analytical reporting and sound decision-making based on the results.

#### Specifications
Data Sources: Data is imported from two source systems (ERP and CRM) provided as CSV files.
Data Quality: Data quality issues are resolved prior to analysis by cleaning the data.
Integration: The two sources are being merged into one. This source is intended to be a user-friendly data model that will be used for analytical queries.
Scope: Historization is not used, as only the latest data is processed.
Documentation: The documentation should provide a clear overview of the data model for both non-experts and experts.

#### Analytics and Reporting

The second step includes the developement of SQL-based analytics to deliver detailed insights into:
Customer Behavior
Product Performance
Sales Trends
The purpose of these insights is to provide stakeholders with key business metrics, which are intended to lead to a strategic decision-making.

---

## Data Architekture:
The data architekture for this project follows the Medallion Architekture with the following layers:

(Scetch for Archtekture insert here)

- **Bronze Layer: Stores the raw data as-is from the source systems. Data is ingested from CSV Files into SQL Server Database.**
- **Silver Layer: The focus of this layer is on cleaning, standardizing, and normalizing the data. This prepares the data for analysis.**
- **Gold Layer: Includes business-ready data that is key for analytics and reporting.**

---







