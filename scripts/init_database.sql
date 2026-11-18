/*
===============================================================================
Script Name   : init_database.sql
Description   : Initializes the Enterprise Data Warehouse environment and 
                Medallion Architecture schemas.
===============================================================================
Purpose:
    This script provisions a clean 'DataWarehouseProject112026' database on Microsoft SQL 
    Server. If an existing instance is detected, active connections are safely 
    terminated and the database is recreated from scratch. It also configures 
    the three logical Medallion schemas:
      - bronze : Raw, untransformed source data ingestion
      - silver : Cleansed, validated, and standardized operational data
      - gold   : Business-ready dimensional models (Star Schema) & views

Operational Warning:
    DESTRUCTIVE OPERATION — Executing this script will permanently drop the 
    existing 'DataWarehouseProject112026' database and all underlying objects/data. Ensure 
    verified backups exist before running in any shared or staging environment.
===============================================================================
*/

USE master;
GO

-- Safely terminate active sessions and drop existing database if present
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = N'DataWarehouseProject112026')
BEGIN
    ALTER DATABASE [DataWarehouseProject112026] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [DataWarehouseProject112026];
END;
GO

-- Provision clean Data Warehouse database
CREATE DATABASE [DataWarehouseProject112026];
GO

USE [DataWarehouseProject112026];
GO

-- Provision Medallion Architecture schemas
CREATE SCHEMA [bronze];
GO

CREATE SCHEMA [silver];
GO

CREATE SCHEMA [gold];
GO
