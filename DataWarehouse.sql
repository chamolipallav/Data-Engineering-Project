-- CREATE TABLE dimDate, DimCustomer, DimMovie, DimStore
--DimDate
CREATE TABLE dimDate
(
	date_key integer NOT NULL PRIMARY KEY,
	date date NOT NULL,
	year smallint NOT NULL,
	quater smallint NOT NULL,
	month smallint NOT NULL,
	day smallint NOT NULL,
	week smallint NOT NULL,
	is_weekend boolean
);

--DimCustomer
CREATE TABLE dimCustomer
(
	customer_key SERIAL PRIMARY KEY,
	customer_id smallint NOT Null,
	first_name varchar(45) NOT Null,
	last_name varchar(45) NOT Null,
	email varchar(50),
	address varchar(50) NOT Null,
	address2 varchar(50),
	district varchar(20) NOT Null,
	city varchar(50) NOT Null,
	country varchar(50) NOT Null,
	postal_code varchar(10),
	phone varchar(10) NOT Null,
	active smallint NOT Null,
	create_date timestamp NOT Null,
	start_date date NOT Null,
	end_date date NOT Null
);

--DimMovie
CREATE TABLE dimMovie
(
	movie_key SERIAL PRIMARY KEY,
	film_id smallint NOT Null,
	title varchar(255) NOT Null,
	description text,
	release_year year,
	language varchar(50) NOT Null,
	original_language varchar(50) NOT Null,
	rental_duration smallint NOT Null,
	length smallint NOT Null,
	rating varchar(50) NOT Null,
	special_features varchar(10) NOT Null
);

--DimStore
CREATE TABLE dimStore
(
	store_key SERIAL PRIMARY KEY,
	store_id smallint NOT Null,
	address varchar(50) NOT Null,
	address2 varchar(50),
	district varchar(20) NOT Null,
	city varchar(50) NOT Null,
	country varchar(50) NOT Null,
	postal_code varchar(10),
	manager_first_name varchar(45) NOT Null,
	manager_last_name varchar(45) NOT Null,
	start_date date NOT Null,
	end_date date NOT Null
);

--FactSales
CREATE TABLE factSales
(

	sales_key SERIAL PRIMARY KEY, 
	date_key integer REFERENCES dimDate (date_key), 
	custom_key integer REFERENCES dimCustomer (customer_key), 
	movie_key integer REFERENCES dimMovie (movie_key), 
	store_key integer REFERENCES dimStore (store_key), 
	sales amount numeric
)

--INSERING data and joining tables to populate the the STAR Schema table with DATA.
--DimDate
INSERT INTO dimdate (date_key, date, year, quater, month, day, week, is_weekend)
SELECT DISTINCT (TO_CHAR (payment_date :: DATE, 'YYYYMMDD'):: integer) as date_key, 
				date (payment_date) as date,
				EXTRACT (year from payment_date) as year,
				EXTRACT (quarter FROM payment_date) AS quater,
				EXTRACT (month FROM payment_date) AS month,
				EXTRACT (day FROM payment_date) AS day,
				EXTRACT (week FROM payment_date) AS week,
				CASE WHEN EXTRACT (ISODOW FROM payment_date) IN (6, 7) THEN true ELSE false END 
FROM payment;

--DimCustomer
INSERT INTO dimCustomer (customer_key, customer_id, first_name, last_name, email, address,
						 address2,district,city, country, postal_code, phone, active, create_date, start_date, end_date)
SELECT c.customer_id as customer_key,
	   c. customer_id, 
	   c.first_name, 
	   c.last_name, 
	   c.email, 
	   a.address, 
	   a.address2, 
	   a.district, 
	   ci.city, 
	   co.country, 
	   a.postal_code, 
	   a.phone, 
	   c.active, 
	   c.create_date, 
	   now() as start_date,
	   now() as end_date

FROM customer c
JOIN address a ON (c.address_id = a address_id)
JOIN city ci ON (a.city_id = ci.city_id)
JOIN country co ON (ci.country_id = co.country_id);

--DimMovie
INSERT INTO dimmovie (movie_key, film_id, title, description, release_year, language, 
					  original_language, rental_duration, length, rating, special_features)
SELECT f. film_id as movie_key,
	   f. film_id, 
	   f.title,
	   f. description, 
	   f.release_year,
	   l.name as language,
	   orig_lang.name as original_language,
	   f. rental_duration, 
	   f.length, 
	   f.rating, 
	   f.special_features
	   
From film f
JOIN language ON (f.language_id = l.language_id)
LEFT JOIN language orig_lang ON (f.language_id = orig_lang.language_id);

--DimStore
INSERT INTO dimstore (store_key, store_id, address, address2, district, city, country, 
					  postal_code, manager_first_name, manager_last_name ‚start_date, end_date)
SELECT s.store_id as store_key, 
	   s.store_id, 
	   a.address, 
	   a.address2, 
	   a.district, 
	   c.city, 
	   co.country, 
	   a.postal_code,
	   st.first_name as manager_first_name, 
	   st.last_name as manager_last_name, 
	   now() AS start_date, 
	   now() AS end_date
	   
FROM store s
JOIN staff st ON (s.manager_staff_id = st.staff_id)
JOIN address a ON (s.address_id = a.address_id)
JOIN city c ON (a.city_id = c.city_id)
JOIN country co ON (c.country_id = co.country_id)

--FactSales
INSERT INTO factsales (date_key, customer_key, movie_key, 
					   store_key, sales_amount)
SELECT 
		TO_CHAR (payment_date :: DATE, 'YYYYMMDD'):: integer AS date_key,
		p. customer_id as customer_key, 
		i.film_id as movie_key, 
		i.store_id as store_key, 
		p.amount as sales_amount
FROM payment p
JOIN rental r ON (p.rental_id = r.rental_id)
JOIN inventory i ON (r.inventory_id = ¡.inventory_id);

-- 3NF Schema ( takes longer time to produce the result)
SELECT f.title, EXTRACT(month FROM p.payment_date) as month, ci.city, sum(p.amount) as revenue
FROM payment p
JOIN rental r ON (p.rental_id = r.rental_id)
JOIN inventory i ON (r.inventory_id = i.inventory_id)
JOIN film f ON (i.film_id = f.film_id)
JOIN customer c ON (p.customer_id = c.customer_id)
JOIN address a ON (c.address_id = a.address_id)
JOIN city ci ON (a.city_id = ci.city_id)
GROUP BY (f.title, month, ci.city)
order BY f.title, month, ci.city, revenue desc;

--STAR Schema ( takes less time to produce the same result)
SELECT dimMovie.title, dimDate.month, dimCustomer.city, sum(sales_amount) as revenue
FROM factSales
JOIN dimMovie ON (dimMovie.movie_key = factsales.movie_key)
JOIN dimDate ON (dimDate.date_key = factsales.date_key)
JOIN dimCustomer ON (dimCustomer.customer_key = factsales.customer_key)
group by (dimMovie.title, dimDate.month, dimCustomer.city)
order by dimMovie.title, dimDate.month, dimCustomer.city, revenue desc;