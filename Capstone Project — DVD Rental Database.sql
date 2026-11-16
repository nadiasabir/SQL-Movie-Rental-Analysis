-- Section 1: DDL and DML (Scenario-Based)
-- Scenario 1: A new customer walks into the store to rent a movie.

SELECT * FROM customer

-- 1. Write the DDL to create a new temporary table called new_customer with appropriate fields 
--(first_name, last_name, email, address_id, active, etc.)

CREATE TEMPORARY TABLE  new_customer(
first_name CHARACTER VARYING(45),
last_name CHARACTER VARYING(45),
email CHARACTER VARYING(50),
address_id INT,
active INT DEFAULT 1
)

SELECT * FROM new_customer

-- 2. Insert a record for the new customer into the new_customer table.
INSERT INTO new_customer(first_name, last_name, email, address_id, active)
VALUES ('Hasset', 'Markos', 'markoshasset@gmail.com',5,1)

-- 3. Insert the customer into the main customer table based on the record in new_customer.

INSERT INTO customer(store_id, first_name, last_name, email, address_id, active)
SELECT 1, first_name, last_name, email, address_id, active
FROM new_customer

SELECT * FROM customer
WHERE first_name='Hasset'

-- 4. Simulate a new rental: Insert a new record into the rental table for this customer, including 
--rental date, inventory_id (assume it's available), and staff_id.
SELECT * FROM rental
SELECT * FROM inventory

INSERT INTO rental(rental_date,inventory_id,customer_id,staff_id)
VALUES(NOW(),100,600,1)

SELECT * FROM rental
WHERE customer_id=600
-- 5. Insert a corresponding payment record into the payment table for this rental, 
--recording the amount and payment date.

SELECT * FROM payment

INSERT INTO payment(customer_id,staff_id,rental_id,amount,payment_date)
VALUES (600,1,16050,9.99,NOW())

SELECT * FROM payment
WHERE customer_id=600

-- Scenario 2: A new film is released and needs to be added to the system.
-- 6. Create a temporary table new_film with fields such as title, description, release_year, language_id, 
--rental_duration, rental_rate, length, replacement_cost, and rating.
SELECT * FROM film

CREATE TABLE new_film(
title CHARACTER VARYING(255), 
description TEXT, 
release_year YEAR, 
language_id SMALLINT, 
rental_duration SMALLINT, 
rental_rate NUMERIC(4,2), 
length SMALLINT, 
replacement_cost NUMERIC(5,2), 
rating MPAA_RATING
)
-- 7. Insert a record for the new film into new_film table.

INSERT INTO new_film (
    title, description, release_year, language_id,
    rental_duration, rental_rate, length,
    replacement_cost, rating
)
VALUES (
    'APEX',
    'She is Nobodys Prey',
    2026,
    1,
    5,
    4.99,
    97,
    19.99,
    'PG-13'
);

SELECT * FROM new_film

-- 8. Insert the new film into the main film table using the data from new_film.

INSERT INTO film (
    title, description, release_year, language_id,
    rental_duration, rental_rate, length,
    replacement_cost, rating
)
SELECT title, description, release_year, language_id,
    rental_duration, rental_rate, length,
    replacement_cost, rating
FROM new_film

SELECT * FROM film
WHERE title='APEX'

-- 9. Add inventory: insert 3 available copies of this new film into the inventory table, 
--assigning them to different store locations.

SELECT * FROM inventory

INSERT INTO inventory (film_id, store_id)
VALUES 
    (1001, 1),
    (1001, 2),
    (1001, 3)

SELECT * FROM inventory
WHERE film_id=1001

-- Section 2: DQL — Data Query Language (SELECT, WHERE, Aggregates, GROUP BY, HAVING, ORDER BY, JOINS, Subqueries)
-- General Analysis
-- 8. List the top 10 longest movies along with their length and title.

SELECT title, length
FROM film
ORDER BY length DESC
LIMIT 10

-- 9. Find all customers who have rented more than 10 movies.
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(r.rental_id) AS total_rentals
FROM customer c
JOIN rental r
ON c.customer_id = r.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(r.rental_id) > 10;

-- 10. Get the average rental rate for each movie rating (G, PG, R, etc.).

SELECT rating, AVG(rental_rate)
FROM film
GROUP BY rating

-- 11. Find the top 5 cities with the most customers.

SELECT 
    ci.city,
    COUNT(c.customer_id) AS total_customers
FROM customer c
JOIN address a
ON c.address_id = a.address_id
JOIN city ci
ON a.city_id = ci.city_id
GROUP BY ci.city
ORDER BY total_customers DESC
LIMIT 5;

-- 12. Show the total revenue (payment amount) collected by each staff member.

SELECT 
    s.staff_id,
    s.first_name,
    s.last_name,
    SUM(p.amount) AS total_revenue
FROM staff s
JOIN payment p
ON s.staff_id = p.staff_id
GROUP BY s.staff_id, s.first_name, s.last_name;

-- 13. Retrieve the 10 most rented films along with how many times each was rented.

SELECT 
    f.title,
    COUNT(r.rental_id) AS rental_count
FROM film f
JOIN inventory i
ON f.film_id = i.film_id
JOIN rental r
ON i.inventory_id = r.inventory_id
GROUP BY f.title
ORDER BY rental_count DESC
LIMIT 10;

-- 14. Find the customer who has spent the most in total payments.

SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(p.amount) AS total_spent
FROM customer c
JOIN payment p
ON c.customer_id = p.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC
LIMIT 1;

-- 15. List all movies that have never been rented.

SELECT title
FROM film
WHERE film_id NOT IN (
    SELECT DISTINCT i.film_id
    FROM inventory i
    JOIN rental r
    ON i.inventory_id = r.inventory_id
);

-- DQL Case Study Questions
-- Case Study 1: Customer Behavior Analysis
--  A marketing team wants to identify loyal customers to send special discount offers.

-- Write a query to find customers who rented more than 20 movies and spent more than $100 in total.
-- Return their full name, email, total rentals, and total amount paid.
-- Sort the results by the total amount spent, highest first.

SELECT 
    c.first_name || ' ' || c.last_name AS full_name,
    c.email,
    COUNT(r.rental_id) AS total_rentals,
    SUM(p.amount) AS total_amount_paid
FROM customer c
JOIN rental r
ON c.customer_id = r.customer_id
JOIN payment p
ON c.customer_id = p.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.email
HAVING COUNT(r.rental_id) > 20
   AND SUM(p.amount) > 100
ORDER BY total_amount_paid DESC;

-- Case Study 2: Film Performance Review
--  The store manager wants to know which movies are underperforming and might be removed from inventory.

-- Find all films that have been rented fewer than 5 times.
-- Return the film title, rental count, and average rental rate for each.
-- Sort the result by rental count, lowest first, and limit to 20 films.

SELECT 
    f.title,
    COUNT(r.rental_id) AS rental_count,
    AVG(f.rental_rate) AS average_rental_rate
FROM film f
LEFT JOIN inventory i
ON f.film_id = i.film_id
LEFT JOIN rental r
ON i.inventory_id = r.inventory_id
GROUP BY f.film_id, f.title
HAVING COUNT(r.rental_id) < 5
ORDER BY rental_count ASC
LIMIT 20;
