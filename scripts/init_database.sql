/*
Erstellung der Database und der Schamas
----------------------------------------
Funktionsweise des Scripts:
  Die Datenbank namens "DataWarehouse" wird erzeugt, nachdem überprüft wurde, ob nicht bereits eine vorhanden ist. 
  Falls dem der Fall ist, wird diese gelöscht und an ihrer Stelle eine neue erzeugt. Darauf folgt das Erstellen der Schemas 
  (Bronze, silver, gold)
----------------------------------------
Zu beachten:
  Durch die Ausführung dieses Scripts wird eine möglicherweise bestehende Datenbank namens "DataWarehouse" für immer gelöscht.
  Alle in dieser Datenbank enthaltenen Daten gehen daher verloren. 
  Um das zu vermeiden, sollte darauf geachtet werden, dass für den Fall der Fälle funktionierende Backups erstellt 
  wurden.
*/


USE master;
GO

-- DROP and recreate the "DataWarehouse" database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
	ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE DataWarehouse;
END;
GO

--create database
CREATE DATABASE DataWarehouse;
GO

USE DataWarehouse;
GO

-- create schemas
CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
GO
