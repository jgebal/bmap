RSpec.shared_context 'shared bitmap builder' do

  before(:all) do
    plsql.dbms_output_stream = STDOUT
    @bits_in_segment = plsql.bmap_builder.C_ELEMENT_CAPACITY
    @max_bit_number = plsql.bmap_builder.C_SEGMENT_CAPACITY
    plsql.execute <<-SQL
      CREATE OR REPLACE FUNCTION to_bin_int_list(p_bit_numbers_list INT_LIST) RETURN bmap_builder.BIN_INT_LIST IS
        result bmap_builder.BIN_INT_LIST := bmap_builder.BIN_INT_LIST();
      BEGIN
        IF p_bit_numbers_list IS NULL THEN RETURN NULL; END IF;
        FOR i IN 1 .. CARDINALITY(p_bit_numbers_list) LOOP
          result.EXTEND; result(result.LAST) := p_bit_numbers_list(i);
        END LOOP;
        RETURN result;
      END;
    SQL
    plsql.execute <<-SQL
      CREATE OR REPLACE FUNCTION to_int_list(p_bit_numbers_list bmap_builder.BIN_INT_LIST) RETURN INT_LIST IS
        result INT_LIST := INT_LIST();
      BEGIN
        FOR i IN 1 .. CARDINALITY(p_bit_numbers_list) LOOP
          result.EXTEND; result(result.LAST) := p_bit_numbers_list(i);
        END LOOP;
        RETURN result;
      END;
    SQL
    plsql.execute <<-SQL
      CREATE OR REPLACE FUNCTION encode_decode_test(p_bit_numbers_list INT_LIST) RETURN INT_LIST IS
      BEGIN
        RETURN to_int_list(bmap_builder.decode_bmap_segment( bmap_builder.encode_bmap_segment( to_bin_int_list(p_bit_numbers_list) ) ));
      END;
    SQL

    plsql.execute <<-SQL
      CREATE OR REPLACE FUNCTION encode_bitand_test(p_left INT_LIST, p_right INT_LIST) RETURN INT_LIST IS
      BEGIN
        RETURN to_int_list(
                 bmap_builder.decode_bmap_segment(
                   bmap_builder.segment_bit_and(
                     bmap_builder.encode_bmap_segment( to_bin_int_list(p_left) ),
                     bmap_builder.encode_bmap_segment( to_bin_int_list(p_right) )
                   )
                 )
               );
      END;
    SQL

    plsql.execute <<-SQL
      CREATE OR REPLACE FUNCTION encode_bitor_test(p_left INT_LIST, p_right INT_LIST) RETURN INT_LIST IS
      BEGIN
        RETURN to_int_list(
                 bmap_builder.decode_bmap_segment(
                   bmap_builder.segment_bit_or(
                     bmap_builder.encode_bmap_segment( to_bin_int_list(p_left) ),
                     bmap_builder.encode_bmap_segment( to_bin_int_list(p_right) )
                   )
                 )
               );
      END;
    SQL

    plsql.execute <<-SQL
      CREATE OR REPLACE FUNCTION set_bits_in_bmap_segment_test(p_bit_numbers_list INT_LIST, p_bit_map_to_build INT_LIST) RETURN INT_LIST IS
        bit_map bmap_builder.BMAP_SEGMENT;
      BEGIN
        bit_map := bmap_builder.encode_bmap_segment( to_bin_int_list(p_bit_map_to_build) );
        bmap_builder.set_bits_in_bmap_segment( to_bin_int_list(p_bit_numbers_list), bit_map );
        RETURN to_int_list(bmap_builder.decode_bmap_segment( bit_map ));
      END;
    SQL

    plsql.execute <<-SQL
      CREATE OR REPLACE FUNCTION encode_bitminus_test(p_left INT_LIST, p_right INT_LIST) RETURN INT_LIST IS
      BEGIN
        RETURN to_int_list(
                 bmap_builder.decode_bmap_segment(
                   bmap_builder.segment_bit_minus(
                     bmap_builder.encode_bmap_segment( to_bin_int_list(p_left) ),
                     bmap_builder.encode_bmap_segment( to_bin_int_list(p_right) )
                   )
                 )
               );
      END;
    SQL

    plsql.execute <<-SQL
      CREATE OR REPLACE FUNCTION encode_and_insert_bmap( p_bit_numbers_list INT_LIST ) RETURN INTEGER IS
      BEGIN
        RETURN bmap_persist.insertBitmapLst( bmap_builder.encode_bmap_segment( to_bin_int_list(p_bit_numbers_list) ) );
      END;
    SQL

    plsql.execute <<-SQL
      CREATE OR REPLACE FUNCTION encode_and_update_bmap( p_key_id INTEGER, p_bit_numbers_list INT_LIST ) RETURN INTEGER IS
      BEGIN
        RETURN bmap_persist.updateBitmapLst( p_key_id, bmap_builder.encode_bmap_segment( to_bin_int_list(p_bit_numbers_list) ) );
      END;
    SQL

    plsql.execute <<-SQL
      CREATE OR REPLACE FUNCTION encode_and_set_bmap( p_bitmap_key IN OUT INTEGER, p_bit_numbers_list INT_LIST ) RETURN INTEGER IS
      BEGIN
        RETURN bmap_persist.setBitmapLst( p_bitmap_key, bmap_builder.encode_bmap_segment( to_bin_int_list(p_bit_numbers_list) ) );
      END;
    SQL

    plsql.execute <<-SQL
      CREATE OR REPLACE FUNCTION select_and_decode_bmap( p_bitmap_key INTEGER  ) RETURN INT_LIST IS
      BEGIN
        RETURN to_int_list(bmap_builder.decode_bmap_segment( bmap_persist.getBitmapLst(  p_bitmap_key ) ));
      END;
    SQL


  end

  after(:all) do
    plsql.execute('DROP FUNCTION to_bin_int_list')
    plsql.execute('DROP FUNCTION to_int_list')
    plsql.execute('DROP FUNCTION encode_decode_test')
    plsql.execute('DROP FUNCTION encode_bitand_test')
    plsql.execute('DROP FUNCTION encode_bitor_test')
    plsql.execute('DROP FUNCTION set_bits_in_bmap_segment_test')
    plsql.execute('DROP FUNCTION encode_bitminus_test')
    plsql.execute('DROP FUNCTION encode_and_insert_bmap')
    plsql.execute('DROP FUNCTION encode_and_update_bmap')
    plsql.execute('DROP FUNCTION select_and_decode_bmap')
  end

  def encode_and_decode_bmap(bit_number_list)
    plsql.encode_decode_test(bit_number_list)
  end

  def segment_bit_and( left, right )
    plsql.encode_bitand_test(left, right)
  end

  def segment_bit_minus( left, right )
    plsql.encode_bitminus_test(left, right)
  end

  def segment_bit_or( left, right )
    plsql.encode_bitor_test(left, right)
  end

  def set_bits_in_bmap_segment(bit_list, bit_map)
    plsql.set_bits_in_bmap_segment_test(bit_list, bit_map)
  end

  def encode_and_insert_bmap(bit_number_list)
    plsql.encode_and_insert_bmap(bit_number_list)
  end

  def encode_and_update_bmap(key_id, bit_number_list)
    plsql.encode_and_update_bmap(key_id, bit_number_list)
  end

  def encode_and_set_bmap(key_id, bit_number_list)
    plsql.encode_and_set_bmap(key_id, bit_number_list)
  end

  def select_and_decode_bmap(bitmap_key)
    plsql.select_and_decode_bmap(bitmap_key)
  end

end

  def encode_bmap_segment(*bit_number_list)
    if bit_number_list.is_a?(Array) && bit_number_list[0].is_a?(Array) then
      plsql.bmap_builder.encode_bmap_segment(bit_number_list[0])
    else
      plsql.bmap_builder.encode_bmap_segment(bit_number_list)
    end
  end

  def decode_bmap_segment(bitmap)
    plsql.bmap_builder.decode_bmap_segment(bitmap)
  end


  def set_bit_in_segment(bit,segment)
    @bits_in_segment*(segment-1)+bit
  end
