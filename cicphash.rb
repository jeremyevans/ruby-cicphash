# Case Insensitive Case Preserving Hash
#
# CICPHash has the same interface as Hash, but is case insensitive
# and case preserving.  Any value can be used as a key.  However, you
# cannot have two keys in the same CICPHash that would be the same if when
# converted to strings would be equal or differing only in case.
#
# For example, all of the following keys would be considered equalivalent:
# 'ab', 'Ab', 'AB', 'aB', :ab, :Ab, :AB, :aB
#
# CICPHash uses a last match wins policy.  If an key-value pair is added to
# a CICPHash and a case insensitive variant of the key is already in the hash
# the instance of the key in the hash becomes the same the most recently added
# key (and the value is updated to reflect the new value).
#
# You can change the rules determining which keys are equal by modifying the
# private convert_key method.  By default, it is set to key.to_s.downcase.
# This method should produce the same output for any keys that you want to
# consider equal.  For example, if you want :a and :A to be equal but :a to be
# different than "a", maybe key.inspect.downcase would work for you.
class CICPHash
  include Enumerable
  
  def self.[](*items)
    if items.length % 2 != 0
      if items.length == 1 && items.first.is_a?(Hash)
        new.merge(items.first)
      else
        raise ArgumentError, "odd number of arguments for CICPHash"
      end
    else
      hash = new
      loop do
        break if items.length == 0
        key = items.shift
        value = items.shift
        hash[key] = value
      end
      hash
    end
  end
  
  def initialize(*default, &block)
    if default.length > 1 || default.length == 1 && block_given?
      raise ArgumentError, "wrong number of arguments"
    end
    @name_hash = {}
    @hash = {}
    @default = default.first unless block_given?
    @default_proc = Proc.new(&block) if block_given?
  end
  
  def ==(hash)
    to_hash == hash.to_hash
  end
  
  def [](key)
    new_key = convert_key(key)
    if @hash.include?(new_key)
      @hash[new_key]
    elsif @default_proc
      @default_proc.call(self, key)
    else
      @default
    end
  end

  def []=(key, value)
    new_key = convert_key(key)
    @name_hash[new_key] = key
    @hash[new_key] = value
  end
  alias store :[]=
  
  def clear
    @name_hash.clear
    @hash.clear
  end
  
  def clone
    s = super
    s.instance_variable_set(:@hash, @hash.clone)
    s.instance_variable_set(:@name_hash, @name_hash.clone)
    s
  end
  
  def default
    @default
  end
  
  def default=(value)
    @default = value
  end
  
  def default_proc
    @default_proc
  end
  
  def delete(key)
    new_key = convert_key(key)
    @name_hash.delete(new_key)
    @hash.delete(new_key)
  end
  
  def delete_if
    hash = self.class.new
    each{|key, value| yield(key, value) ? delete(key) : (hash[key] = value)}
    hash
  end

  def dup
    s = super
    s.instance_variable_set(:@hash, @hash.dup)
    s.instance_variable_set(:@name_hash, @name_hash.dup)
    s
  end
  
  def each
    @hash.each{|key, value| yield @name_hash[key], value }
  end
  alias each_pair each
  
  def each_key
    @hash.each_key{|key| yield @name_hash[key] }
  end
  
  def each_value
    @hash.each_value{|value| yield value }
  end
  
  def empty?
    @hash.empty?
  end
  
  def fetch(key, *default)
    raise ArgumentError, "wrong number of arguments (#{default.length+1} for 2)" if default.length > 1
    if include?(key)
      self[key]
    elsif block_given?
      yield key
    elsif default.length == 1
      default.first
    else
      # :nocov:
      error_class = RUBY_VERSION < '1.9' ? IndexError : KeyError
      # :nocov:
      raise error_class, "key not found"
    end
  end
  
  def has_key?(key)
    @hash.has_key?(convert_key(key))
  end
  alias include? has_key?
  alias key? has_key?
  alias member? has_key?
  
  def has_value?(value)
    @hash.has_value?(value)
  end
  alias value? has_value?
  
  if RUBY_VERSION >= '1.9'
    def key(value)
      @name_hash[@hash.key(value)]
    end

  # :nocov:
    if RUBY_VERSION < '3'
      alias index key
    end
  else
    def index(value)
      @name_hash[@hash.index(value)]
    end
  # :nocov:
  end
  
  def inspect
    to_hash.inspect
  end
  
  def invert
    hash = self.class.new
    each{|key, value| hash[value] = key}
    hash
  end
  
  def keys
    @name_hash.values
  end
  
  def length
    @hash.length
  end
  alias size length
  
  def merge(hash)
    new_hash = self.class.new.merge!(self)
    hash.each do |key, value| 
      new_hash[key] = if block_given? && new_hash.include?(key)
         yield key, new_hash[key], hash[key]
      else 
        value
      end
    end
    new_hash
  end
  
  def rehash
    @name_hash.keys.each do |key|
      new_key = @name_hash[key].to_s.downcase 
      if new_key != key
        @name_hash[new_key] = @name_hash.delete(key)
        @hash[new_key] = @hash.delete(key)
      end
    end
    self
  end
  
  def reject
    hash = self.class.new
    each{|key, value| hash[key] = self[key] unless yield(key, value)}
    hash
  end
  
  def reject!
    hash = self.class.new
    changes = false
    each{|key, value| yield(key, value) ? (changes = true; delete(key)) : (hash[key] = value)}
    changes ? hash : nil
  end
    
  def replace(hash)
    clear
    update(hash)
  end
  
  if RUBY_VERSION >= '1.9'
    def select
      hash = self.class.new
      each{|key, value| hash[key] = value if yield(key, value)}
      hash 
    end
  # :nocov:
  else
    def select
      array = []
      each{|key, value| array << [key, value] if yield(key, value)}
      array
    end
  # :nocov:
  end
  
  def shift
    return nil if @name_hash.length == 0
    key, value = @name_hash.shift
    [value, @hash.delete(key)]
  end
  
  def sort(&block)
    block_given? ? to_a.sort(&block) : to_a.sort
  end
  
  def to_a
    array = []
    each{|key, value| array << [key, value]}
    array
  end
  
  def to_hash
    hash = {}
    each{|key, value| hash[key] = value}
    hash
  end
  
  if RUBY_VERSION >= '1.9'
    alias to_s inspect
  # :nocov:
  else
    def to_s
      to_a.join
    end
  # :nocov:
  end
  
  def update(hash)
    hash.each do |key, value| 
      self[key] = if block_given? && include?(key)
        yield key, self[key], hash[key]
      else 
        value
      end
    end
    self
  end
  alias merge! update
  
  def values
    @hash.values
  end
  
  def values_at(*keys)
    keys.collect{|key| self[key]}
  end

  if RUBY_VERSION >= '1.9'
    def compare_by_identity
      raise TypeError, "CICPHash cannot compare by identity, use regular Hash"
    end

    def compare_by_identity?
      false
    end

    def assoc(obj)
      obj = convert_key(obj)
      each do |k, v|
        if convert_key(k) == obj
          return [k, v]
        end
      end
      nil
    end

    attr_writer :default_proc

    def flatten(*a)
      if a.empty?
        to_a.flatten(1)
      else
        to_a.flatten(*a)
      end
    end

    def keep_if(&block)
      to_a.each do |k, v|
        delete(k) unless yield(k, v)
      end
      self
    end

    def rassoc(obj)
      each do |k, v|
        if v == obj
          return [k, v]
        end
      end
      nil
    end

    def select!(&block)
      mod = false
      to_a.each do |k, v|
        unless yield(k, v)
          mod = true
          delete(k)
        end
      end
      self if mod
    end
  # :nocov:
  else
    alias indexes values_at
    alias indices values_at
  # :nocov:
  end

  # :nocov:
  if RUBY_VERSION >= '2.0'
  # :nocov:
    alias to_h to_hash
  end
  
  # :nocov:
  if RUBY_VERSION >= '2.3'
  # :nocov:
    def >(other)
      to_hash > other.to_hash
    end

    def >=(other)
      to_hash >= other.to_hash
    end

    def <(other)
      to_hash < other.to_hash
    end

    def <=(other)
      to_hash <= other.to_hash
    end

    def dig(arg, *a)
      h = self[arg]
      if a.empty?
        h
      elsif !h.nil?
        raise TypeError, "#{h.class} does not have #dig method" unless h.respond_to?(:dig)
        h.dig(*a) 
      end
    end

    def fetch_values(*a)
      a.map{|x| fetch(x)}
    end

    def to_proc
      lambda{|x| self[x]}
    end
  end

  # :nocov:
  if RUBY_VERSION >= '2.4'
  # :nocov:
    def compact
      hash = dup
      hash.compact!
      hash
    end

    def compact!
      hash = to_hash
      replace(hash) if hash.compact!
    end

    def transform_values(&block)
      dup.transform_values!(&block)
    end

    def transform_values!(&block)
      replace(to_hash.transform_values!(&block))
    end
  end

  # :nocov:
  if RUBY_VERSION >= '2.5'
  # :nocov:
    def slice(*a)
      h = self.class.new
      a.each{|k| h[k] = self[k] if has_key?(k)}
      h
    end

    def transform_keys(&block)
      dup.transform_keys!(&block)
    end

    def transform_keys!(&block)
      replace(to_hash.transform_keys!(&block))
    end
  end

  # :nocov:
  if RUBY_VERSION >= '2.6'
  # :nocov:
    alias filter! select!
  end

  # :nocov:
  if RUBY_VERSION >= '2.7'
  # :nocov:
    def deconstruct_keys(keys)
      to_hash
    end
  end

  # :nocov:
  if RUBY_VERSION >= '3.0'
  # :nocov:
    def except(*a)
      h = dup
      a.each{|k| h.delete(k)}
      h
    end
  end

  private

  def convert_key(key)
    key.to_s.downcase
  end
end
