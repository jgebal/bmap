CREATE OR REPLACE PACKAGE BODY BMAP_UTIL AS

  E_SUBSCRIPT_BEYOND_COUNT EXCEPTION;
  PRAGMA EXCEPTION_INIT( E_SUBSCRIPT_BEYOND_COUNT, -6533 );

  FUNCTION deduplicate_bit_numbers_list(p_bit_numbers_list int_list) RETURN int_list IS
    bit_no_set     int_list := int_list();
    BEGIN
      SELECT DISTINCT COLUMN_VALUE
      BULK COLLECT INTO bit_no_set
      FROM TABLE(p_bit_numbers_list)
      WHERE COLUMN_VALUE IS NOT NULL
      ORDER BY 1 DESC;

      RETURN bit_no_set;
    END;

  PROCEDURE build_leaf_level(bit_map_leaves IN OUT NOCOPY BMAP_NODE_LIST, bit_numbers_set IN INT_LIST) IS
    bit_number     SIMPLE_INTEGER := 0;
    segment_number SIMPLE_INTEGER := 0;
    BEGIN
      FOR idx IN bit_numbers_set.FIRST .. bit_numbers_set.LAST LOOP
        bit_number :=     MOD( bit_numbers_set(idx) - 1, C_INDEX_LENGTH );
        segment_number := CEIL( bit_numbers_set(idx) / C_INDEX_LENGTH );
        IF NOT bit_map_leaves.exists(segment_number) THEN
          bit_map_leaves.EXTEND(segment_number - bit_map_leaves.LAST);
          bit_map_leaves(segment_number) := POWER(2,bit_number);
        ELSE
          bit_map_leaves(segment_number) := bit_map_leaves(segment_number) + POWER(2,bit_number);
        END IF;
      END LOOP;
    END build_leaf_level;

  PROCEDURE build_level(bit_map_tree IN OUT NOCOPY BMAP_LEVEL_LIST, bit_map_level_number IN INTEGER, bit_numbers_set IN INT_LIST) IS
    first_node     NUMBER;
    last_node      NUMBER;
    bit_number     SIMPLE_INTEGER := 0;
    segment_number SIMPLE_INTEGER := 0;
    BEGIN
      first_node := CEIL( bit_map_tree(bit_map_level_number - 1).FIRST / C_INDEX_LENGTH);
      last_node := CEIL( bit_map_tree(bit_map_level_number - 1).LAST / C_INDEX_LENGTH);
      FOR node IN first_node .. last_node LOOP
        IF bit_map_tree(bit_map_level_number - 1)(node) IS NULL THEN
          CONTINUE;
        END IF;
        bit_number := MOD(node - 1, C_INDEX_LENGTH);
        segment_number := CEIL(node / C_INDEX_LENGTH);
        IF NOT bit_map_tree(bit_map_level_number).exists(segment_number) THEN
          bit_map_tree(bit_map_level_number).EXTEND(segment_number - bit_map_tree(bit_map_level_number).LAST);
          bit_map_tree(bit_map_level_number)(segment_number) := POWER(2,bit_number);
        ELSE
          bit_map_tree(bit_map_level_number)(segment_number) := bitor(bit_map_tree(bit_map_level_number)(segment_number), POWER(2,bit_number));
        END IF;
      END LOOP;
    END build_level;

  FUNCTION bit_no_lst_to_bit_map(
    p_bit_numbers_list INT_LIST
  ) RETURN BMAP_LEVEL_LIST IS
    bit_numbers_set INT_LIST := INT_LIST();
    bit_map_tree    BMAP_LEVEL_LIST := BMAP_LEVEL_LIST();
    max_bit_number  NUMBER;
  BEGIN
    IF p_bit_numbers_list IS NULL OR CARDINALITY(p_bit_numbers_list) = 0 THEN
      RETURN bit_map_tree;
    END IF;

    SELECT MAX(COLUMN_VALUE)
    INTO max_bit_number
    FROM TABLE(p_bit_numbers_list);

    IF max_bit_number > C_MAX_BITS THEN
      RAISE_APPLICATION_ERROR(-20000, 'Index size overflow');
    END IF;

    bit_numbers_set := deduplicate_bit_numbers_list(p_bit_numbers_list);

    IF bit_numbers_set.COUNT = 0 THEN
      RETURN bit_map_tree;
    END IF;

    FOR bit_map_level_number IN 1 .. C_INDEX_DEPTH LOOP
      bit_map_tree.extend;
      bit_map_tree( bit_map_level_number ) := BMAP_NODE_LIST(0);
      IF bit_map_level_number = 1 THEN
        build_leaf_level( bit_map_tree(bit_map_level_number), bit_numbers_set);
      ELSE
        build_level(bit_map_tree, bit_map_level_number, bit_numbers_set);
      END IF;
    END LOOP;

    RETURN bit_map_tree;
  END bit_no_lst_to_bit_map;

  FUNCTION bitor(
    left  SIMPLE_INTEGER ,
    right SIMPLE_INTEGER ) RETURN SIMPLE_INTEGER
  IS
  BEGIN
    RETURN left + right - BITAND( left, right );
  END bitor;

END BMAP_UTIL;
/

ALTER PACKAGE BMAP_UTIL COMPILE DEBUG BODY;
/
