if ENV.delete('COVERAGE')
  require 'simplecov'

  SimpleCov.start do
    enable_coverage :branch
    add_filter "/test/"
    add_group('Missing'){|src| src.covered_percent < 100}
    add_group('Covered'){|src| src.covered_percent == 100}
  end
end

$: << File.dirname(File.dirname(File.expand_path(__FILE__)))
require 'cicphash'
ENV['MT_NO_PLUGINS'] = '1' # Work around stupid autoloading of plugins
require 'rubygems'
gem 'minitest'
require 'minitest/autorun'

class CICPHashTest < Minitest::Test
  def setup
    @h = CICPHash[]
    @fh = CICPHash['AB'=>1, :cd=>2, 3=>4]
  end

  def test_public_interface
    cicphash_methods = CICPHash.public_instance_methods.sort
    hash_methods = Hash.public_instance_methods.sort
    assert_empty(cicphash_methods - hash_methods)
    if defined?(JRUBY_VERSION) && JRUBY_VERSION >= '9.4'
      hash_methods -= [:index, :ruby2_keywords_hash, :ruby2_keywords_hash?]
    end
    assert_empty(hash_methods - cicphash_methods) 
  end
  
  def test_constructors_and_equality
    # Test CICPHash.[]
    assert_equal Hash[], CICPHash[]
    assert_equal Hash[1=>2], CICPHash[1=>2]
    assert_equal Hash[1=>2, 3=>4], CICPHash[1=>2, 3=>4]
    assert_equal Hash[1,2,3,4], CICPHash[1,2,3,4]
    assert_equal Hash[:ab,:c,:de,:f], CICPHash[:ab,:c,:de,:f]
    refute_equal Hash[:AB,:c,:de,:f], CICPHash[:ab,:c,:de,:f]
    assert_raises(ArgumentError){CICPHash[1]}
    assert_raises(ArgumentError){CICPHash[1,2,3]}
    
    # Test CICPHash.new
    h, ch = Hash.new, CICPHash.new
    assert_equal h, ch
    h, ch = Hash.new(1), CICPHash.new(1)
    assert_equal h, ch
    assert_equal h[3], ch[3]
    h[3], ch[3] = [2, 2]
    assert_equal h[3], ch[3]
    h, ch = Hash.new{|h,k| k*2}, CICPHash.new{|h,k| k*2}
    assert_equal h[3], ch[3]
    h[3], ch[3] = [2, 2]
    assert_equal h[3], ch[3]
    assert_raises(ArgumentError){CICPHash.new(1){|hash,k| key}}
  end
  
  def test_latest_assignment_wins
    assert_equal Hash[], @h
    @h['a'] = 1
    assert_equal Hash['a'=>1], @h
    @h['A'] = 2
    assert_equal Hash['A'=>2], @h
    @h[:ab] = 3
    assert_equal Hash['A'=>2, :ab=>3], @h
    @h['AB'] = 4
    assert_equal Hash['A'=>2, 'AB'=>4], @h
    @h[1] = 5
    assert_equal Hash['A'=>2, 'AB'=>4, 1=>5], @h
    @h['1'] = 6
    assert_equal Hash['A'=>2, 'AB'=>4, '1'=>6], @h
  end
  
  def test_store_and_retrieve
    assert_nil  @h[1]
    @h[1] = 2
    assert_equal 2, @h[1]
    assert_equal 2, @h[:'1']
    assert_equal 2, @h['1']
    @h['a'] = 3
    assert_equal 3, @h['a']
    assert_equal 3, @h['A']
    assert_equal 3, @h[:a]
    assert_equal 3, @h[:A]
    @h['AB'] = 5
    assert_equal 5, @h['ab']
    assert_equal 5, @h['AB']
    assert_equal 5, @h['aB']
    assert_equal 5, @h['Ab']
    assert_equal 5, @h[:ab]
    assert_equal 5, @h[:AB]
    assert_equal 5, @h[:aB]
    assert_equal 5, @h[:Ab]
    @h.store(7, 8)
    assert_equal 8, @h[7]
    assert_equal 8, @h[:'7']
    assert_equal 8, @h['7']
  end
  
  def test_clear
    assert_equal 3, @fh.length
    @fh.clear
    assert_equal Hash[], @fh
    assert_equal 0, @fh.length
  end
  
  def test_defaults
    assert_nil  @fh.default
    assert_nil  @fh.default_proc
    assert_nil  @fh[55]
    assert_equal 3, CICPHash.new(3).default
    assert_nil  CICPHash.new(3).default_proc
    assert_equal 3, CICPHash.new(3)[1]
    
    @fh.default = 4
    assert_equal 4, @fh.default
    assert_nil  @fh.default_proc
    assert_equal 4, @fh[55]
    
    h = CICPHash.new(5)
    assert_equal 5, h.default
    assert_nil  h.default_proc
    assert_equal 5, h[55]
    
    h = CICPHash.new{|hash, key| 1234}
    assert_nil  h.default
    refute_equal nil, h.default_proc
    assert_equal 1234, h[55]
    
    h = CICPHash.new{|hash, key| hash[key] = 1234; nil}
    assert_nil  h.default
    refute_equal nil, h.default_proc
    assert_nil  h[55]
    assert_equal 1234, h[55]
  end
  
  def test_delete
    assert_equal 3, @fh.length
    assert_equal 1, @fh.delete(:ab)
    assert_equal 2, @fh.length
    assert_nil  @fh.delete(:ab)
    assert_equal 2, @fh.length
  end
  
  def test_delete_if_and_reject
    assert_equal 3, @fh.length
    hash = @fh.reject{|key, value| key.to_s.length >= 2}
    assert_equal 1, hash.length
    assert_equal Hash[3=>4], hash
    assert_equal 3, @fh.length
    hash = @fh.delete_if{|key, value| key.to_s.length >= 2}
    assert_equal 1, hash.length
    assert_equal Hash[3=>4], hash
    assert_equal 1, @fh.length
    assert_equal Hash[3=>4], @fh
    assert_nil  @fh.reject!{|key, value| key.to_s.length >= 2}
    hash = @fh.reject!{|key, value| key.to_s.length == 1}
    assert_equal 0, hash.length
    assert_equal Hash[], hash
    assert_equal 0, @fh.length
    assert_equal Hash[], @fh
  end

  def test_dup_and_clone
    def @h.foo; 1; end
    h2 = @h.dup
    h3 = @h.clone
    h2[1] = 2
    h3[1] = 2
    assert_equal CICPHash[], @h
    assert_raises NoMethodError do h2.foo end
    assert_equal 1, h3.foo
  end
  
  def test_each
    i = 0
    @h.each{i+=1}
    assert_equal 0, i
    items = [['AB',1], [:cd,2], [3,4]]
    @fh.each do |k,v| 
      assert items.include?([k,v])
      items -= [[k,v]]
    end
    assert_equal [], items
  end
  
  def test_each_key
    i = 0
    @h.each{i+=1}
    assert_equal 0, i
    keys = ['AB', :cd, 3]
    @fh.each_key do |k| 
      assert keys.include?(k)
      keys -= [k]
    end
    assert_equal [], keys
  end
  
  def test_each_value
    i = 0
    @h.each{i+=1}
    assert_equal 0, i
    values = [1, 2, 4]
    @fh.each_value do |v| 
      assert values.include?(v)
      values -= [v]
    end
    assert_equal [], values
  end
  
  def test_empty
    assert @h.empty?
    assert !@fh.empty?
  end
  
  def test_fetch
    assert_raises(ArgumentError){@h.fetch(1,2,3)}
    assert_raises(ArgumentError){@h.fetch(1,2,3){4}}
    assert_raises(IndexError){@h.fetch(1)}
    @h.default = 33
    assert_raises(IndexError){@h.fetch(1)}
    @h[1] = 2
    assert_equal 2, @h.fetch(1)
    assert_equal 3, @h.fetch(2, 3)
    assert_equal 4, @h.fetch(2, 3){4}
    assert_equal 6, @h.fetch(2, 3){|k| k*3}
    assert_equal 1, @fh.fetch(:ab)
    assert_equal 2, @fh.fetch(:CD, 3)
    assert_equal 4, @fh.fetch("3", 3){8}
    assert_equal 4, @fh.fetch("3", 3){|k| k*3}
    assert_raises(IndexError){CICPHash.new{34}.fetch(1)}
  end
  
  def test_has_key
    'include? has_key? key? member?'.split.each do |meth|
      assert !@h.send(meth,1)
      assert @fh.send(meth,'AB')
      assert @fh.send(meth,:cd)
      assert @fh.send(meth,3)
      assert @fh.send(meth,:ab)
      assert @fh.send(meth,'CD')
      assert @fh.send(meth,'3')
      assert !@fh.send(meth,1)
    end
  end
  
  def test_has_value
    'value? has_value?'.split.each do |meth|
      assert !@h.send(meth,1)
      assert @fh.send(meth,1)
      assert @fh.send(meth,2)
      assert @fh.send(meth,4)
      assert !@fh.send(meth,3)
    end
  end
  
  if RUBY_VERSION < '3'
    def test_index
      assert_nil  @h.index(1)
      assert_equal 'AB', @fh.index(1)
      assert_equal :cd, @fh.index(2)
      assert_nil  @fh.index(3)
      assert_equal 3, @fh.index(4)
    end
  end
  
  def test_inspect
    assert_equal '{}', CICPHash[].inspect
    if RUBY_VERSION >= '3.4'
      assert_equal '{1 => 2}', CICPHash[1=>2].inspect
      assert_equal '{ab: "CD", [:"3"] => 4}', CICPHash[:ab=>'CD', [:'3']=>4].inspect
    else
      assert_equal '{1=>2}', CICPHash[1=>2].inspect
      assert ['{:ab=>"CD", [:"3"]=>4}', '{[:"3"]=>4, :ab=>"CD"}'].include?(CICPHash[:ab=>'CD', [:'3']=>4].inspect)
    end
  end
  
  if RUBY_VERSION >= '1.9'
    def test_to_s
      assert_equal '{}', CICPHash[].to_s
      if RUBY_VERSION >= '3.4'
        assert_equal '{1 => 2}', CICPHash[1=>2].to_s
        assert_equal '{ab: "CD", [:"3"] => 4}', CICPHash[:ab=>'CD', [:'3']=>4].to_s
      else
        assert_equal '{1=>2}', CICPHash[1=>2].to_s
        assert_equal '{:ab=>"CD", [:"3"]=>4}', CICPHash[:ab=>'CD', [:'3']=>4].to_s
      end
    end
  else
    def test_to_s
      assert_equal '', CICPHash[].to_s
      assert_equal '12', CICPHash[1=>2].to_s
      assert ['abCD34', '34abCD'].include?(CICPHash[:ab=>'CD', [:'3']=>4].to_s)
    end
  end
  
  def test_invert
    assert_equal Hash[].invert, CICPHash[].invert
    assert_equal Hash[1=>2].invert, CICPHash[1=>2].invert
    assert_equal Hash[1=>2, 3=>4].invert, CICPHash[1=>2, 3=>4].invert
    assert_equal Hash[1,2,3,4].invert, CICPHash[1,2,3,4].invert
    assert_equal Hash[:ab,:c,:de,:f].invert, CICPHash[:ab,:c,:de,:f].invert
    refute_equal Hash[:ab,:c,:de,:f].invert, CICPHash[:aB,:c,:de,:f].invert
    assert [{2=>1},{2=>3}].include?(CICPHash[1,2,3,2].invert)
  end
  
  def test_keys
    assert_equal [], @h.keys
    assert [[:aB, 1],[1, :aB]].include?(CICPHash[:aB,:c,1,:f].keys)
  end
  
  def test_length
    assert_equal 0, @h.length
    assert_equal 0, @h.size
    assert_equal 3, @fh.length
    assert_equal 3, @fh.size
    @h[1] = 2
    assert_equal 1, @h.length
    assert_equal 1, @h.size
    @fh.delete(:AB)
    assert_equal 2, @fh.length
    assert_equal 2, @fh.size
  end
  
  def test_merge_and_update
    assert_equal @h, @h.merge({})
    assert_equal @fh, @fh.merge({})
    assert_equal CICPHash[:ab=>55], @h.merge({:ab=>55})
    assert_equal CICPHash[], @h
    assert_equal CICPHash[:ab=>55], @h.update({:ab=>55})
    assert_equal CICPHash[:ab=>55], @h
    assert_equal CICPHash[:ab=>55, :cd=>2, 3=>4], @fh.merge({:ab=>55})
    assert_equal CICPHash['AB'=>1, :cd=>2, 3=>4], @fh
    assert_equal CICPHash[:ab=>55, :cd=>2, 3=>4], @fh.merge!({:ab=>55})
    assert_equal CICPHash[:ab=>55, :cd=>2, 3=>4], @fh
    assert_equal CICPHash[:ab=>'abss55', :cd=>2, 3=>4], @fh.merge({:ab=>'ss'}){|k,ov,nv| [k,nv,ov].join}
    assert_equal CICPHash[:ab=>55, :cd=>2, 3=>4], @fh
    assert_equal CICPHash[:ab=>'abss55', :cd=>2, 3=>4], @fh.update({:ab=>'ss'}){|k,ov,nv| [k,nv,ov].join}
    assert_equal CICPHash[:ab=>'abss55', :cd=>2, 3=>4], @fh
    assert_equal CICPHash[:ab=>'abssabss55', :cd=>2, 3=>4], @fh.merge!({:ab=>'ss'}){|k,ov,nv| [k,nv,ov].join}
    assert_equal CICPHash[:ab=>'abssabss55', :cd=>2, 3=>4], @fh
  end
  
  def test_update
    assert_equal Hash[], @h.update({})
    assert_equal Hash[:ab,2], @h.update({:ab=>2})
    assert_equal Hash[:ab,2], @h
    assert_equal Hash['AB',2], @h.update({'AB'=>2})
    assert_equal Hash['AB',2], @h
    assert_equal Hash[:aB,6,4,5], @h.update(:aB=>3, 4=>5){|k,ov,nv| 
      assert_equal :aB, k
      assert_equal 2, ov
      assert_equal 3, nv
      6
    }
    assert_equal Hash[:aB,6,4,5], @h
  end
  
  def test_rehash
    assert_equal @h, @h.rehash
    assert_equal @fh, @fh.rehash
    x = 'BLAH'.dup
    @fh[x] = 23
    assert_equal CICPHash['AB'=>1, :cd=>2, 3=>4, 'BLAH'=>23], @fh
    assert_equal CICPHash['AB'=>1, :cd=>2, 3=>4, 'BLAH'=>23], @fh.rehash
    x.downcase!
    assert_equal CICPHash['AB'=>1, :cd=>2, 3=>4, 'blah'=>23], @fh
    assert_equal CICPHash['AB'=>1, :cd=>2, 3=>4, 'blah'=>23], @fh.rehash
    x.replace("DIFF")
    assert_equal 23, @fh['blah']
    assert_nil  @fh['DIFF']
    assert_equal CICPHash['AB'=>1, :cd=>2, 3=>4, 'DIFF'=>23], @fh
    assert_equal CICPHash['AB'=>1, :cd=>2, 3=>4, 'DIFF'=>23], @fh.rehash
    assert_nil  @fh['blah']
    assert_equal 23, @fh['DIFF']
  end
  
  def test_replace
    assert_equal @h, @h.replace(@h)
    assert_equal @fh, @fh.replace(@fh)
    assert_equal @fh, @h.replace(@fh)
    assert_equal Hash[], @fh.replace(Hash[])
  end
  
  if RUBY_VERSION >=  '1.9'
    def test_select
      assert_equal({}, @h.select{true})
      assert_equal({}, @h.select{false})
      assert_equal({3 => 4, "AB" => 1, :cd => 2}, @fh.select{true})
      assert_equal({}, @fh.select{false})
      assert_equal({:cd => 2}, @fh.select{|k,v| k.is_a?(Symbol)})
      assert_equal({3 => 4}, @fh.select{|k,v| v == 4})
    end
  else
    def test_select
      assert_equal [], @h.select{true}
      assert_equal [], @h.select{false}
      assert_equal [[3, 4], ["AB", 1], [:cd, 2]], @fh.select{true}.sort_by{|k,v| k.to_s}
      assert_equal [], @fh.select{false}
      assert_equal [[:cd,2]], @fh.select{|k,v| k.is_a?(Symbol)}
      assert_equal [[3,4]], @fh.select{|k,v| v == 4}
    end
  end
  
  def test_shift
    assert_nil  @h.shift
    array = @fh.to_a
    i = 3
    while true
      assert i >= 0
      kv = @fh.shift
      if kv.nil?
        assert_equal [], array
        break
      else
        i -= 1
        assert array.include?(kv)
        array -= [kv]
      end
    end
    assert_equal [], array
    assert_equal 0, i
  end
  
  def test_sort
    assert_equal [], @h.sort
    assert_equal [], @h.sort{|a,b| a.to_s<=>b.to_s}
    assert_equal [['AB',1], ['CD',4], ['EF',2]], CICPHash['CD',4,'AB',1,'EF',2].sort
    assert_equal [[3,4], ['AB',1], [:cd,2]], @fh.sort{|(ak,av),(bk,bv)| ak.to_s<=>bk.to_s}
  end
  
  def test_to_a
    assert_equal [], @h.to_a
    assert_equal [[3,4], ['AB',1], [:cd,2]], @fh.to_a.sort_by{|k,v| k.to_s}
  end
  
  def test_to_hash
    assert_equal Hash[], @h.to_hash
    assert_equal Hash[3,4,'AB',1,:cd,2], @fh.to_hash
  end
  
  def test_values
    assert_equal [], @h.values
    assert_equal [:c, :f], CICPHash[:aB,:f,1,:c].values.sort_by{|x|x.to_s}
  end
  
  def test_values_at
    assert_equal [], @h.values_at()
    assert_equal [nil], @h.values_at(1)
    assert_equal [nil, nil], @h.values_at(1, 1)
    assert_equal [], @fh.values_at()
    assert_equal [1], @fh.values_at(:ab)
    assert_equal [2, 1], @fh.values_at('CD', :ab)
    assert_equal [2, nil, 1], @fh.values_at('CD', 32, :ab)
    assert_equal [4, 2, nil, 1], @fh.values_at('3', 'CD', 32, :ab)
  end

  if RUBY_VERSION < '1.9'
    def test_indexes_indices
      [:indexes, :indices].each do |meth|
        assert_equal [], @h.send(meth)
        assert_equal [nil], @h.send(meth, 1)
        assert_equal [nil, nil], @h.send(meth, 1, 1)
        assert_equal [], @fh.send(meth)
        assert_equal [1], @fh.send(meth, :ab)
        assert_equal [2, 1], @fh.send(meth, 'CD', :ab)
        assert_equal [2, nil, 1], @fh.send(meth, 'CD', 32, :ab)
        assert_equal [4, 2, nil, 1], @fh.send(meth, '3', 'CD', 32, :ab)
      end
    end
  end

  if RUBY_VERSION >= '1.9'
    def test_assoc
      assert_nil  @h.assoc(1)
      assert_equal ['AB', 1], @fh.assoc(:Ab)
      assert_equal [:cd, 2], @fh.assoc('CD')
      assert_nil  @fh.assoc(4)
      assert_equal [3, 4], @fh.assoc('3')
    end

    def test_default_proc=
      @h.default_proc = proc{|h, k| k * 2}
      assert_equal 'aa', @h['a']
      @h[:a] = 2
      assert_equal 2, @h['a']
    end

    def test_flatten
      assert_equal [], @h.flatten
      assert_equal ['AB', 1, :cd, 2, 3, 4], @fh.flatten
      @fh[:X] = [5, 6]
      assert_equal ['AB', 1, :cd, 2, 3, 4, :X, [5, 6]], @fh.flatten
      assert_equal ['AB', 1, :cd, 2, 3, 4, :X, 5, 6], @fh.flatten(2)
    end

    def test_keep_if
      assert_equal @h, @h.keep_if{|k, v| true}
      assert_equal @fh, @fh.keep_if{|k, v| true}
      assert_equal @h, @fh.dup.keep_if{|k, v| false}
      assert_equal CICPHash["AB"=>1], @fh.keep_if{|k, v| k == "AB"}
    end

    def test_key
      assert_nil  @h.key(1)
      assert_equal 'AB', @fh.key(1)
      assert_equal :cd, @fh.key(2)
      assert_nil  @fh.key(3)
      assert_equal 3, @fh.key(4)
    end

    def test_rassoc
      assert_nil  @h.rassoc(1)
      assert_equal ['AB', 1], @fh.rassoc(1)
      assert_equal [:cd, 2], @fh.rassoc(2)
      assert_nil  @fh.rassoc(3)
      assert_equal [3, 4], @fh.rassoc(4)
    end

    def test_select!
      assert_nil  @h.select!{|k, v| true}
      assert_nil  @fh.select!{|k, v| true}
      assert_equal @h, @fh.dup.select!{|k, v| false}
      assert_equal CICPHash["AB"=>1], @fh.select!{|k, v| k == "AB"}
    end

    def test_compare_by_identity
      assert_raises(TypeError){@fh.compare_by_identity}
    end

    def test_compare_by_identity?
      assert_equal(false, @fh.compare_by_identity?)
    end
  end

  if RUBY_VERSION >= '2.0'
    def test_to_h
      assert_equal Hash[], @h.to_h
      assert_equal Hash[3,4,'AB',1,:cd,2], @fh.to_h
    end
  end

  if RUBY_VERSION >= '2.3'
    def test_gt
      assert_equal(false, @fh > @fh)
      assert_equal(true, @fh > CICPHash['AB'=>1, :cd=>2])
      assert_equal(false, @fh > CICPHash['AB'=>1, :cd=>2, 3=>4, 5=>6])
      assert_equal(false, @fh > CICPHash[:AB=>1, :cd=>2, 3=>4])
      assert_equal(false, @fh > CICPHash[:AB=>1, :cd=>2])
      assert_equal(false, @fh > CICPHash[:AB=>1, :cd=>2, 3=>4, 5=>6])
    end

    def test_gte
      assert_equal(true, @fh >= @fh)
      assert_equal(true, @fh >= CICPHash['AB'=>1, :cd=>2])
      assert_equal(false, @fh >= CICPHash['AB'=>1, :cd=>2, 3=>4, 5=>6])
      assert_equal(false, @fh >= CICPHash[:AB=>1, :cd=>2, 3=>4])
      assert_equal(false, @fh >= CICPHash[:AB=>1, :cd=>2])
      assert_equal(false, @fh >= CICPHash[:AB=>1, :cd=>2, 3=>4, 5=>6])
    end

    def test_lt
      assert_equal(false, @fh < @fh)
      assert_equal(false, @fh < CICPHash['AB'=>1, :cd=>2])
      assert_equal(true, @fh < CICPHash['AB'=>1, :cd=>2, 3=>4, 5=>6])
      assert_equal(false, @fh < CICPHash[:AB=>1, :cd=>2, 3=>4])
      assert_equal(false, @fh < CICPHash[:AB=>1, :cd=>2])
      assert_equal(false, @fh < CICPHash[:AB=>1, :cd=>2, 3=>4, 5=>6])
    end

    def test_lte
      assert_equal(true, @fh <= @fh)
      assert_equal(false, @fh <= CICPHash['AB'=>1, :cd=>2])
      assert_equal(true, @fh <= CICPHash['AB'=>1, :cd=>2, 3=>4, 5=>6])
      assert_equal(false, @fh <= CICPHash[:AB=>1, :cd=>2, 3=>4])
      assert_equal(false, @fh <= CICPHash[:AB=>1, :cd=>2])
      assert_equal(false, @fh <= CICPHash[:AB=>1, :cd=>2, 3=>4, 5=>6])
    end

    def test_dig
      assert_equal(1, @fh.dig(:AB))
      assert_equal(2, @fh.dig('cd'))
      assert_equal(4, @fh.dig('3'))
      assert_nil(@fh.dig(4))

      assert_raises(TypeError){@fh.dig(:AB, 1)}
      assert_raises(TypeError){@fh.dig('cd', 2)}
      assert_raises(TypeError){@fh.dig('3', 3)}
      assert_nil(@fh.dig(4, 5))

      fh = CICPHash['AB'=>{1=>2}, 3=>CICPHash['CD'=>4]]
      assert_equal(2, fh.dig(:AB, 1))
      assert_nil(fh.dig(:AB, 2))
      assert_raises(TypeError){fh.dig(:AB, 1, 3)}
      assert_nil(fh.dig(:AB, 2, 3))

      assert_equal(4, fh.dig('3', :cd))
      assert_nil(fh.dig(3, 2))
      assert_nil(fh.dig(4))
    end

    def test_fetch_values
      assert_equal([1], @fh.fetch_values(:AB))
      assert_equal([1, 2, 4], @fh.fetch_values(:AB, 'cd', '3'))
      assert_raises(KeyError){@fh.fetch_values(:AB, 'cd', 4)}
    end

    def test_to_proc
      pr = @fh.to_proc
      assert_equal(1, pr[:AB])
      assert_equal(2, pr['cd'])
      assert_equal(4, pr['3'])
      assert_nil(pr[4])
    end
  end

  if RUBY_VERSION >= '2.4'
    def test_compact
      assert_equal(false, @fh.compact.equal?(@fh))
      assert_equal(@fh, @fh.compact)
      assert_equal(CICPHash['AB'=>1], CICPHash['AB'=>1, :cd=>nil].compact)
    end

    def test_compact!
      fh = @fh.dup
      assert_nil(@fh.compact!)
      assert_equal(fh, @fh)

      h = CICPHash['AB'=>1, :cd=>nil]
      assert_equal(CICPHash['AB'=>1], h.compact!)
      assert_equal(CICPHash['AB'=>1], h)
    end

    def test_transform_values
      fh = @fh.transform_values{|v| v.to_s*2}
      assert_equal(1, @fh[:AB])
      assert_equal(CICPHash['AB'=>'11', :cd=>'22', 3=>'44'], fh)
      assert_equal('11', fh[:AB])
    end

    def test_transform_values!
      @fh.transform_values!{|v| v.to_s*2}
      assert_equal('11', @fh[:AB])
      assert_equal(CICPHash['AB'=>'11', :cd=>'22', 3=>'44'], @fh)
      assert_equal('11', @fh[:AB])
    end
  end

  if RUBY_VERSION >= '2.5'
    def test_slice
      assert_equal(CICPHash[:AB=>1, 'CD'=>2, '3'=>4], @fh.slice(:AB, 'CD', '3'))
      assert_equal(CICPHash[:AB=>1, 'CD'=>2], @fh.slice(:AB, 'CD'))
      assert_equal(CICPHash[], @fh.slice(:BA, 'DC'))
      assert_equal(1, @fh.slice(:AB, 'CD')['AB'])
    end

    def test_transform_keys
      map = {'AB'=>:XY, :cd=>'DC', 3=>'5'}
      dh = @fh.dup
      fh = @fh.transform_keys{|k| map[k]}
      assert_equal(dh, @fh)
      assert_equal(1, fh['XY'])
      assert_equal(2, fh[:dc])
      assert_equal(4, fh[5])
    end

    def test_transform_keys!
      map = {'AB'=>:XY, :cd=>'DC', 3=>'5'}
      dh = @fh.dup
      @fh.transform_keys!{|k| map[k]}
      assert_equal(false, dh == @fh)
      assert_equal(1, @fh['XY'])
      assert_equal(2, @fh[:dc])
      assert_equal(4, @fh[5])
    end
  end

  if RUBY_VERSION >= '2.6'
    def test_filter!
      assert_nil  @h.filter!{|k, v| true}
      assert_nil  @fh.filter!{|k, v| true}
      assert_equal @h, @fh.dup.filter!{|k, v| false}
      assert_equal CICPHash["AB"=>1], @fh.filter!{|k, v| k == "AB"}
    end
  end

  if RUBY_VERSION >= '2.7'
    def test_deconstruct_keys
      assert_equal(@fh.to_hash, @fh.deconstruct_keys([]))
      assert_equal(Hash, @fh.deconstruct_keys([]).class)
    end
  end

  if RUBY_VERSION >= '3.0'
    def test_except
      @fh = CICPHash['AB'=>1, :cd=>2, 3=>4]
      assert_equal(@fh, @fh.except)
      assert_equal(CICPHash[:cd=>2, 3=>4], @fh.except('AB', 5))
      assert_equal(CICPHash['AB'=>1], @fh.except('CD', '3'))
    end
  end
end
