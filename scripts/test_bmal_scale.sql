SET TIMING ON

CREATE OR REPLACE FUNCTION bmap_list_generator(p_bits INTEGER, p_density INTEGER) RETURN INT_LIST PIPELINED IS
  v_rows INTEGER := p_bits*p_density;
  i      INTEGER := 1;
  BEGIN
    LOOP
      PIPE ROW(TRUNC(i/p_density));
      EXIT WHEN i > v_rows;
      i := i + 1;
    END LOOP;
    RETURN;
  END bmap_list_generator;
/

DECLARE
  c                       bmap_builder.BIT_LIST_REF_C;
  X                       INT_LIST;
  t                       NUMBER := dbms_utility.get_time;
  C_DATASET_SIZE CONSTANT INTEGER := 500000;
  C_OFFSET       CONSTANT INTEGER := 100000000000;
BEGIN
  OPEN c FOR SELECT
               COLUMN_VALUE + C_OFFSET                              bit_no,
               ceil( ( COLUMN_VALUE + C_OFFSET ) / power( 30, 3 ) ) bit_segment_no
             FROM TABLE ( bmap_list_generator( C_DATASET_SIZE, 1) );
  bmap_builder.build_bitmap( c, 100 );
  CLOSE c;
  dbms_output.put_line( 'Took: ' || ( dbms_utility.get_time - t ) / 100 || ' sec, with dataset:' || C_DATASET_SIZE );
END;
/

--Took: 12,68 sec, with dataset:2000000

SET TIMING ON
DECLARE
  c                       SYS_REFCURSOR;
  X                       INT_LIST;
  t                       NUMBER := dbms_utility.get_time;
  C_DATASET_SIZE CONSTANT INTEGER := 500000;
  C_OFFSET       CONSTANT INTEGER := 100000000000;
BEGIN
  OPEN c FOR SELECT COLUMN_VALUE + C_OFFSET bit_no FROM TABLE ( bmap_list_generator( C_DATASET_SIZE, 1) );
  bmap_builder.build_bitmap_nopipe( c, 100 );
  CLOSE c;
  dbms_output.put_line( 'Took: ' || ( dbms_utility.get_time - t ) / 100 || ' sec, with dataset:' || C_DATASET_SIZE );
END;
/

