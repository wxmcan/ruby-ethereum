require 'minitest/autorun'
require 'ethereum'
require 'json'

def fixture_root
  File.expand_path('../../fixtures', __FILE__)
end

def fixture_path(path)
  File.join fixture_root, path
end

def load_fixture(path)
  fixture = {}
  name = File.basename(path).sub(/#{File.extname(path)}$/, '')

  json = File.open(fixture_path(path)) {|f| JSON.load f }
  json.each do |k, v|
    fixture["#{name}_#{k}"] = v
  end

  to_bytes fixture
end

def to_bytes(obj)
  case obj
  when String
    obj.b
  when Array
    obj.map {|x| to_bytes(x) }
  when Hash
    h = {}
    obj.each do |k, v|
      k = k.b if k.instance_of?(String) && (k.size == 40 || k[0,2] == '0x')
      h[k] = to_bytes(v)
    end
    h
  else
    obj
  end
end

def encode_hex(s)
  RLP::Utils.encode_hex s
end

def decode_hex(x)
  x.instance_of?(String) && x[0,2] == '0x' ? RLP::Utils.decode_hex(x) : x
end

class Minitest::Test
  class <<self
    def run_fixture(path)
      fixture = load_fixture path

      fixture.each do |name, pairs|
        define_method("test_fixture_#{name}") do
          on_fixture_test name, pairs
        end
      end
    end
  end

  def on_fixture_test(name, pairs)
    raise NotImplementedError, "override this method to customize fixture testing"
  end
end
