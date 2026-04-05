CREATE DATABASE IF NOT EXISTS exp8_hive;
USE exp8_hive;

DROP TABLE IF EXISTS employee;
DROP TABLE IF EXISTS movies;

CREATE TABLE employee (
  id INT,
  name STRING,
  film STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ',';

CREATE TABLE movies (
  name STRING,
  film STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ',';

LOAD DATA LOCAL INPATH '${hiveconf:PROJECT_DIR}/data/employee.csv' OVERWRITE INTO TABLE employee;
LOAD DATA LOCAL INPATH '${hiveconf:PROJECT_DIR}/data/movies.csv' OVERWRITE INTO TABLE movies;

SHOW TABLES;
SELECT * FROM movies;
SELECT * FROM employee;

SELECT name, film
FROM movies
WHERE film LIKE '%a%';

SELECT id, name, film
FROM employee
WHERE id >= 3;

DROP TABLE employee;
SHOW TABLES;
