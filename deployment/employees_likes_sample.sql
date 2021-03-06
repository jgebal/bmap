--------------------------------------------------------
--  DDL for Table EMPLOYEES
--------------------------------------------------------

CREATE TABLE employees_likes
(	employee_id NUMBER(6,0),
   like_id NUMBER(10,0)
) ;

CREATE UNIQUE INDEX employees_likes_pk ON employees_likes (employee_id, like_id)
;

ALTER TABLE employees_likes ADD CONSTRAINT employees_likes_pk PRIMARY KEY (employee_id,like_id) ENABLE;

INSERT INTO employees_likes
  WITH random_dataset (row_num,row_value, rows_to_generate) as
  ( SELECT 1 AS row_num,
           trunc(abs(dbms_random.NORMAL) * &NUMBER_OF_LIKES) row_value,
           trunc( dbms_random.VALUE( 1, &NUMBER_OF_LIKES/&MIN_NUMBER_OF_LIKES_FOR_EMP ) * &MIN_NUMBER_OF_LIKES_FOR_EMP ) rows_to_generate
      FROM dual
    UNION ALL
    SELECT row_num+1 AS row_num,
           TRUNC(dbms_random.VALUE( 1, &NUMBER_OF_LIKES)) row_value,
           rows_to_generate
      FROM random_dataset
     WHERE row_num <= rows_to_generate
  )
    --the hint is needed to force oracle to execute the RANDOM_DATASET query for each row of EMPLOYEES
    -- this way, a separate random dataset is generated for each employee
  SELECT /*+ USE_NL(employees, random_dataset) LEADING(employees) */
         DISTINCT employee_id, row_value
    FROM employees
   CROSS JOIN random_dataset
 WHERE employee_id IN (101,102,103,104);


COMMIT;

