--------------------------------------------------------
--  DDL for Table EMPLOYEES
--------------------------------------------------------
CREATE SEQUENCE LIKE_SEQ CACHE 20;

CREATE TABLE LIKES
(
  LIKE_ID NUMBER(10,0),
  LIKE_NAME VARCHAR2(100)
);

CREATE UNIQUE INDEX LIKES_PK ON LIKES (LIKE_ID)
;
CREATE UNIQUE INDEX LIKES_UK ON LIKES (LIKE_NAME)
;

ALTER TABLE LIKES ADD CONSTRAINT LIKES_PK PRIMARY KEY (LIKE_ID) ENABLE;
ALTER TABLE LIKES ADD CONSTRAINT LIKES_UK UNIQUE (LIKE_NAME) ENABLE;
ALTER TABLE LIKES MODIFY (LIKE_ID CONSTRAINT LIKE_NAME_NN NOT NULL ENABLE);

INSERT INTO LIKES
SELECT LIKE_SEQ.NEXTVAL, DBMS_RANDOM.string('l',30)
  FROM DUAL
 CONNECT BY LEVEL <= &NUMBER_OF_LIKES;

COMMIT;