
It rquires flink client (v.1.18) installed (for example: into /opt/Flink directory) and add Flinks bin/ directory added in $PATH. 
You can take flink client (with some connectors) here: https://disk.yandex.ru/d/Zg1AbWEjOEjRLg

Please check your docker, docker-compose, java installation.
Check Makefile. 
According to documentation https://ververica.github.io/flink-cdc-connectors/master/content/quickstart/mysql-postgres-tutorial.html

**How to start the project**


*cd* into project folder.


Then, using Makefile  put these commandt in different trminal vindow:

make 1
make 2 
make 3

You also could use .sh scripts.


Then, check interfaces:
http://localhost:8081/ - flink
http://localhost:5601/ - kibana


Then insert data into:

-- MySQL

SET GLOBAL time_zone = '+3:00';


CREATE DATABASE mydb;
USE mydb;
CREATE TABLE products (
  id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description VARCHAR(512)
); ALTER TABLE products AUTO_INCREMENT = 101;

INSERT INTO products
VALUES (default,"scooter","Small 2-wheel scooter"),
       (default,"car battery","12V car battery"),
       (default,"12-pack drill bits","12-pack of drill bits with sizes ranging from #40 to #3"),
       (default,"hammer","12oz carpenter's hammer"),
       (default,"hammer","14oz carpenter's hammer"),
       (default,"hammer","16oz carpenter's hammer"),
       (default,"rocks","box of assorted rocks"),
       (default,"jacket","water resistent black wind breaker"),
       (default,"spare tire","24 inch spare tire");

CREATE TABLE orders (
  order_id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
  order_date DATETIME NOT NULL,
  customer_name VARCHAR(255) NOT NULL,
  price DECIMAL(10, 5) NOT NULL,
  product_id INTEGER NOT NULL,
  order_status BOOLEAN NOT NULL -- Whether order has been placed
) AUTO_INCREMENT = 10001;

INSERT INTO orders
VALUES (default, '2020-07-30 10:08:22', 'Jark', 50.50, 102, false),
       (default, '2020-07-30 10:11:09', 'Sally', 15.00, 105, false),
       (default, '2020-07-30 12:00:30', 'Edward', 25.25, 106, false);




-- PG
CREATE TABLE shipments (
  shipment_id SERIAL NOT NULL PRIMARY KEY,
  order_id SERIAL NOT NULL,
  origin VARCHAR(255) NOT NULL,
  destination VARCHAR(255) NOT NULL,
  is_arrived BOOLEAN NOT NULL
);

ALTER SEQUENCE public.shipments_shipment_id_seq RESTART WITH 1001;


ALTER TABLE public.shipments REPLICA IDENTITY FULL;


INSERT INTO shipments
VALUES (default,10001,'Beijing','Shanghai',false), (default,10002,'Hangzhou','Shanghai',false), (default,10003,'Shanghai','Hangzhou',false);





-- Flink SQL
--SET table.local-time-zone = Europe/Moscow;

SET execution.checkpointing.interval = 3s;


CREATE TABLE products (
    id INT,
    name STRING,
    description STRING,
    PRIMARY KEY (id) NOT ENFORCED
  ) WITH (
    'connector' = 'mysql-cdc',
    'hostname' = 'localhost',
    'port' = '3306',
    'username' = 'root',
    'password' = '123456',
    'database-name' = 'mydb',
    'table-name' = 'products'
  );


CREATE TABLE orders (
   order_id INT,
   order_date TIMESTAMP(0),
   customer_name STRING,
   price DECIMAL(10, 5),
   product_id INT,
   order_status BOOLEAN,
   PRIMARY KEY (order_id) NOT ENFORCED
 ) WITH (
   'connector' = 'mysql-cdc',
   'hostname' = 'localhost',
   'port' = '3306',
   'username' = 'root',
   'password' = '123456',
   'database-name' = 'mydb',
   'table-name' = 'orders'
 );


CREATE TABLE shipments (
   shipment_id INT,
   order_id INT,
   origin STRING,
   destination STRING,
   is_arrived BOOLEAN,
   PRIMARY KEY (shipment_id) NOT ENFORCED
 ) WITH (
   'connector' = 'postgres-cdc',
   'hostname' = 'localhost',
   'port' = '5432',
   'username' = 'postgres',
   'password' = 'postgres',
   'database-name' = 'postgres',
   'schema-name' = 'public',
   'table-name' = 'shipments'
 );


 CREATE TABLE enriched_orders (
    order_id INT,
    order_date TIMESTAMP(0),
    customer_name STRING,
    price DECIMAL(10, 5),
    product_id INT,
    order_status BOOLEAN,
    product_name STRING,
    product_description STRING,
    shipment_id INT,
    origin STRING,
    destination STRING,
    is_arrived BOOLEAN,
    PRIMARY KEY (order_id) NOT ENFORCED
  ) WITH (
      'connector' = 'elasticsearch-7',
      'hosts' = 'http://localhost:9200',
      'index' = 'enriched_orders'
  );



INSERT INTO enriched_orders
 SELECT o.*, p.name, p.description, s.shipment_id, s.origin, s.destination, s.is_arrived
 FROM orders AS o
 LEFT JOIN products AS p ON o.product_id = p.id
 LEFT JOIN shipments AS s ON o.order_id = s.order_id;
 
 
 --Lets do some example queries:

--MySQL
INSERT INTO orders
VALUES (default, '2020-07-30 15:22:00', 'Jark', 29.71, 104, false);

--PG
INSERT INTO shipments
VALUES (default,10004,'Shanghai','Beijing',false);

--MySQL
UPDATE orders SET order_status = true WHERE order_id = 10004;

--PG
UPDATE shipments SET is_arrived = true WHERE shipment_id = 1004;


--MySQL (automatically deleted in enriched_orders)
DELETE FROM orders WHERE order_id = 10004;


--Another examples

--MySQL
INSERT INTO orders
VALUES (default, '2022-07-30 10:08:22', 'Danil', 50.50, 102, false),
(default, '2022-07-30 10:11:09', 'fff', 15.00, 105, false),
(default, '2022-07-30 12:00:30', 'ggg', 25.25, 106, false);

--PG
INSERT INTO shipments
VALUES (default,10005,'Moscow','Balashikha',false);

--PG
UPDATE shipments SET is_arrived = true WHERE shipment_id = 1005;

--MySQL (automatically deleted in enriched_orders)
DELETE FROM orders WHERE order_id = 10005;















How to create a JDBC table #
The JDBC table can be defined as following:

-- register a MySQL table 'users' in Flink SQL
CREATE TABLE MyUserTable (
id BIGINT,
name STRING,
age INT,
status BOOLEAN,
PRIMARY KEY (id) NOT ENFORCED
) WITH (
'connector' = 'jdbc',
'url' = 'jdbc:mysql://localhost:3306/mydatabase',
'table-name' = 'users'
);

-- write data into the JDBC table from the other table "T"
INSERT INTO MyUserTable
SELECT id, name, age, status FROM T;

-- scan data from the JDBC table
SELECT id, name, age, status FROM MyUserTable;

-- temporal join the JDBC table as a dimension table
SELECT * FROM myTopic
LEFT JOIN MyUserTable FOR SYSTEM_TIME AS OF myTopic.proctime
ON myTopic.key = MyUserTable.id;