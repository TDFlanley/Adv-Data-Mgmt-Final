--section B Provide code for function that preforms the transformation described in A4
CREATE OR REPLACE FUNCTION summarize()
      RETURNS TRIGGER
      LANGUAGE PLPGSQL
AS $$
BEGIN

      DELETE FROM summary_table;
      INSERT INTO summary_table
      SELECT rating, SUM(rental_cost) AS total_rental_cost
      FROM detailed_table
      GROUP BY rating
      ORDER BY rating;
      RETURN NEW;
END;
$$;
--section C Create detailed and summary tables
CREATE TABLE detailed_table(
payment_id INTEGER,
rating mpaa_rating,
rental_cost numeric(4,2)
);

CREATE TABLE summary_table(
rating mpaa_rating,
total_rental_cost numeric(8,2)
);
--section D Extract raw data into detailed table
INSERT INTO detailed_table(payment_id, rating, rental_cost)
SELECT DISTINCT payment_id, f.rating, p.amount
FROM payment p
INNER JOIN rental r ON p.customer_id = r.customer_id
INNER JOIN inventory i ON r.inventory_id = i.inventory_id
INNER JOIN film f ON i.film_id = f.film_id
WHERE p.amount != 0
ORDER BY f.rating, p.payment_id;

--section E Creates trigger on detailed table that will update summary table when new data is added
CREATE TRIGGER summarize_details
AFTER INSERT
ON detailed_table
FOR EACH STATEMENT
EXECUTE PROCEDURE summarize();
--section F Refresh data in both detailed and summary tables
CREATE OR REPLACE PROCEDURE refresh_data()
LANGUAGE PLPGSQL
AS $$
BEGIN

      DELETE FROM detailed_table;
      INSERT INTO detailed_table(payment_id, rating, rental_cost)
      SELECT DISTINCT payment_id, f.rating, p.amount
      FROM payment p
      INNER JOIN rental r ON p.customer_id = r.customer_id
      INNER JOIN inventory i ON r.inventory_id = i.inventory_id
      INNER JOIN film f ON i.film_id = f.film_id
      WHERE p.amount != 0
      ORDER BY f.rating, p.payment_id;
      RETURN;
END;
$$

--check data
CALL refresh_data();
select * from detailed_table;
select * from summary_table;

