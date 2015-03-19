require_relative '../spec_helper'
require_relative '../helpers/bmap_helpers'

describe 'Convert list of bit numbers to hierarchical bitmap' do

  include_context 'shared bitmap builder'

  it 'should return empty bitmap if empty list parameter given' do
    expect( encode_bitmap( nil ) ).to eq( [] )
  end

  it 'should ignore if NULL parameter present on list' do
    result = encode_bitmap(1, nil, 3)
    expect( result ).to eq( [[5],[1],[1],[1],[1]] )
  end

  it 'should return a bitmap for given parameters' do
    result = encode_bitmap(1,2,3,4)
    expect( result ).to eq( [[15],[1],[1],[1],[1]] )
  end

  it 'should fail if bit number is exceeds maximum allowed number' do
    expect{
      encode_bitmap(@max_bit_number + 1)
    }.to raise_exception
  end

  it 'should not fail if bit number is equal to maximum allowed number' do
    expect{
      encode_bitmap(@max_bit_number)
    }.not_to raise_exception
  end

  it 'should create bitmap with multiple segments on first two levels' do
    result = encode_bitmap( 1, @bits_in_segment**2+1 )
    expect( result ).to eq( [ ([1,1]),[1,1],[3],[1],[1]] )
  end

  it 'should create bitmap with multiple segments on different levels' do
    result = encode_bitmap( set_bit_in_segment(1,1), set_bit_in_segment(3,5), set_bit_in_segment(2,10) )
    expect( result ).to eq( [ [1,4,2], [(1 + 2**4 + 2**9)],[1],[1],[1]] )
  end

  it 'should create bitmap with second segment set on second level' do
    result = encode_bitmap(set_bit_in_segment(1,2))
    expect( result ).to eq( [ [1],[2],[1],[1],[1]] )
  end

  it 'should create bitmap with last segment fully set' do
    result = encode_bitmap( (1..@bits_in_segment).to_a)
    expect( result ).to eq( [ [(2**@bits_in_segment)-1],[1],[1],[1],[1]] )
  end

  it 'should create bitmap with last segment set' do
    result = encode_bitmap( ((@max_bit_number-(@bits_in_segment-1))..@max_bit_number).to_a )
    last_element = (2**(@bits_in_segment-1))
    expect( result ).to eq( [ [(2**@bits_in_segment)-1],[last_element],[last_element],[last_element],[last_element]] )
  end

end
