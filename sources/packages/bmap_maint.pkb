CREATE OR REPLACE PACKAGE BODY bmap_maint AS

  C_KEY_POSITION_MAP_TAB_SUFFIX CONSTANT VARCHAR2(5) := '$KP_T';
  C_KEY_POSITION_MAP_SEQ_SUFFIX CONSTANT VARCHAR2(5) := '$KP_S';
  C_KEY_POSITION_MAP_PK_SUFFIX  CONSTANT VARCHAR2(5) := '$KP_P';
  C_KEY_POSITION_MAP_UK_SUFFIX  CONSTANT VARCHAR2(5) := '$KP_U';
  C_BITMAP_STORAGE_TAB_SUFFIX   CONSTANT VARCHAR2(5) := '$BS_T';
  
  C_SOURCE_TABLE                CONSTANT VARCHAR2(30) := 'EMPLOYEES_LIKES';
  C_BITMAP_KEY                  CONSTANT VARCHAR2(30) := 'EMPLOYEE_ID';

  CURSOR c_bmap_crsr IS (
    SELECT CAST(NULL AS VARCHAR2(4000)) bitmap_key,
           CAST(NULL AS INTEGER) bit_no
    FROM DUAL WHERE 0 = 1
  );
  TYPE t_bmap_cursor IS REF CURSOR RETURN c_bmap_crsr%ROWTYPE;

  PROCEDURE create_index
  IS
    v_crsr SYS_REFCURSOR;
    v_sql  VARCHAR2(32767);
    v_t    NUMBER := DBMS_UTILITY.GET_TIME;
    BEGIN
      EXECUTE IMMEDIATE 'CREATE SEQUENCE '||C_SOURCE_TABLE||C_KEY_POSITION_MAP_SEQ_SUFFIX;
      v_sql :=
        'CREATE TABLE '||C_SOURCE_TABLE||C_KEY_POSITION_MAP_TAB_SUFFIX||'(
            BIT_POS INTEGER NOT NULL,
            LIKE_ID NUMBER(10,0),
            CONSTRAINT '||C_SOURCE_TABLE||C_KEY_POSITION_MAP_PK_SUFFIX||' PRIMARY KEY (BIT_POS)
         ) ORGANIZATION INDEX';
      DBMS_OUTPUT.PUT_LINE(v_sql);
      EXECUTE IMMEDIATE v_sql;
      DBMS_OUTPUT.PUT_LINE('Took: '||(DBMS_UTILITY.GET_TIME-v_t)/100||' sec.'); v_t := DBMS_UTILITY.GET_TIME;

      v_sql :=
        'INSERT INTO '||C_SOURCE_TABLE||C_KEY_POSITION_MAP_TAB_SUFFIX||'
          (BIT_POS, LIKE_ID)
         SELECT '||C_SOURCE_TABLE||C_KEY_POSITION_MAP_SEQ_SUFFIX||'.NEXTVAL, LIKE_ID
           FROM (SELECT DISTINCT LIKE_ID FROM '||C_SOURCE_TABLE||')
        ';
      DBMS_OUTPUT.PUT_LINE(v_sql);
      EXECUTE IMMEDIATE v_sql;
      DBMS_OUTPUT.PUT_LINE('Took: '||(DBMS_UTILITY.GET_TIME-v_t)/100||' sec.'); v_t := DBMS_UTILITY.GET_TIME;

      v_sql :=
        'ALTER TABLE '||C_SOURCE_TABLE||C_KEY_POSITION_MAP_TAB_SUFFIX||'
          ADD CONSTRAINT '||C_SOURCE_TABLE||C_KEY_POSITION_MAP_TAB_SUFFIX||' UNIQUE (LIKE_ID, BIT_POS)';
      DBMS_OUTPUT.PUT_LINE(v_sql);
      EXECUTE IMMEDIATE v_sql;
      DBMS_OUTPUT.PUT_LINE('Took: '||(DBMS_UTILITY.GET_TIME-v_t)/100||' sec.'); v_t := DBMS_UTILITY.GET_TIME;

      v_sql :=
        'CREATE TABLE '||C_SOURCE_TABLE||C_BITMAP_STORAGE_TAB_SUFFIX||'(
            BITMAP_KEY NUMBER(6,0),
            BMAP_V_POS INTEGER,
            BMAP_H_POS INTEGER,
            BMAP       STOR_BMAP_SEGMENT)';
      DBMS_OUTPUT.PUT_LINE(v_sql);
      EXECUTE IMMEDIATE v_sql;
      DBMS_OUTPUT.PUT_LINE('Took: '||(DBMS_UTILITY.GET_TIME-v_t)/100||' sec.'); v_t := DBMS_UTILITY.GET_TIME;

      v_sql :=
        'SELECT DISTINCT t.'||C_BITMAP_KEY||' bitmap_key, bit_pos
         FROM '||C_SOURCE_TABLE||C_KEY_POSITION_MAP_TAB_SUFFIX||' m
         JOIN '||C_SOURCE_TABLE||' t ON (t.like_id = m.like_id)
        ORDER BY bitmap_key, bit_pos';
      DBMS_OUTPUT.PUT_LINE(v_sql);

      OPEN v_crsr FOR v_sql;
      bmap_builder.build_bitmaps( v_crsr, C_SOURCE_TABLE||C_BITMAP_STORAGE_TAB_SUFFIX );
      CLOSE v_crsr;
      DBMS_OUTPUT.PUT_LINE('Took: '||(DBMS_UTILITY.GET_TIME-v_t)/100||' sec.'); v_t := DBMS_UTILITY.GET_TIME;
      COMMIT;
    END;

  PROCEDURE drop_index
  IS
      e_seq_not_exists EXCEPTION;
      e_tab_not_exists EXCEPTION;
      e_idx_not_exists EXCEPTION;
  PRAGMA EXCEPTION_INIT (e_seq_not_exists, -2289);
  PRAGMA EXCEPTION_INIT (e_tab_not_exists, -942);
  PRAGMA EXCEPTION_INIT (e_idx_not_exists, -1418);
    v_raise BOOLEAN := FALSE;
    BEGIN
      BEGIN
        EXECUTE IMMEDIATE 'DROP SEQUENCE '||C_SOURCE_TABLE||C_KEY_POSITION_MAP_SEQ_SUFFIX;
        EXCEPTION
        WHEN e_seq_not_exists THEN v_raise := TRUE;
      END;
      BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE '||C_SOURCE_TABLE||C_KEY_POSITION_MAP_TAB_SUFFIX;
        EXCEPTION
        WHEN e_tab_not_exists THEN v_raise := TRUE;
      END;
      BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE '||C_SOURCE_TABLE||C_BITMAP_STORAGE_TAB_SUFFIX;
        EXCEPTION
        WHEN e_tab_not_exists THEN v_raise := TRUE;
      END;
      IF v_raise THEN
        RAISE e_idx_not_exists;
      END IF;
    END;

END bmap_maint;
/

SHOW ERRORS
/
