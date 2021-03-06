SET SERVEROUPTUT ON;
SET TIMING ON;

DECLARE
  a            SIMPLE_INTEGER := 0;
  bit_map      bmap_builder.BMAP_SEGMENT;
  result       bmap_builder.BMAP_SEGMENT;
  storage_bitmap STORAGE_BMAP_LEVEL_LIST;
  int_lst      INT_LIST;
  t            NUMBER;
  loops        SIMPLE_INTEGER := 1;
  bmap_density NUMBER := 1;
  BITS         INTEGER := 1000000;
  x            INTEGER;
BEGIN

  DBMS_OUTPUT.PUT_LINE('Running with parameters:');
  DBMS_OUTPUT.PUT_LINE('        loops = '||loops);
  DBMS_OUTPUT.PUT_LINE(' bmap_density = '||bmap_density);
  DBMS_OUTPUT.PUT_LINE('         BITS = '||BITS);
  t := DBMS_UTILITY.get_time;
  SELECT column_value BULK COLLECT INTO int_lst FROM TABLE( bmap_list_generator(bits, bmap_density) );
  DBMS_OUTPUT.PUT_LINE( 'build a list of bits secs: ' || ( DBMS_UTILITY.get_time - t )/100 );

  t := DBMS_UTILITY.get_time;
  FOR i IN 1 .. loops LOOP
    bit_map := bmap_builder.encode_bmap_segment( int_lst );
  END LOOP;
  DBMS_OUTPUT.PUT_LINE( 'bmap_builder.encode_bmap_segment secs: ' || ( DBMS_UTILITY.get_time - t )/100 );

  t := DBMS_UTILITY.get_time;
  FOR i IN 1 .. loops LOOP
    int_lst := bmap_builder.decode_bmap_segment( bit_map );
  END LOOP;
  DBMS_OUTPUT.PUT_LINE( 'bmap_builder.decode_bmap_segment secs: ' || ( DBMS_UTILITY.get_time - t )/100 );

  t := DBMS_UTILITY.get_time;
  FOR i IN 1 .. loops LOOP
    result := bmap_builder.segment_bit_and( bit_map, bit_map );
  END LOOP;
  DBMS_OUTPUT.PUT_LINE( 'bmap_builder.segment_bit_and secs: ' || ( DBMS_UTILITY.get_time - t )/100 );

  t := DBMS_UTILITY.get_time;
  FOR i IN 1 .. loops LOOP
    result := bmap_builder.segment_bit_or( bit_map, bit_map );
  END LOOP;
  DBMS_OUTPUT.PUT_LINE( 'bmap_builder.segment_bit_or secs: ' || ( DBMS_UTILITY.get_time - t )/100 );

  t := DBMS_UTILITY.get_time;
  FOR i IN 1 .. loops LOOP
    result := bmap_builder.segment_bit_minus( bit_map, bit_map );
  END LOOP;
  DBMS_OUTPUT.PUT_LINE( 'bmap_builder.segment_bit_minus secs: ' || ( DBMS_UTILITY.get_time - t )/100 );

  t := DBMS_UTILITY.get_time;
  FOR i IN 1 .. loops LOOP
    storage_bitmap := bmap_builder.convert_for_storage(bit_map);
  END LOOP;
  DBMS_OUTPUT.PUT_LINE( 'bmap_builder.convert_for_storage secs: ' || ( DBMS_UTILITY.get_time - t )/100 );

  t := DBMS_UTILITY.get_time;
  FOR i IN 1 .. loops LOOP
    bit_map := bmap_builder.convert_for_processing(storage_bitmap);
  END LOOP;
  DBMS_OUTPUT.PUT_LINE( 'bmap_builder.convert_for_processing secs: ' || ( DBMS_UTILITY.get_time - t )/100 );

  ROLLBACK;
END;
/

DROP FUNCTION bmap_list_generator;