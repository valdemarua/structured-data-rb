# frozen_string_literal: true

require "json"
require "net/http"
require "fileutils"

# Checks entity declarations and JSON-LD documents against a pinned Schema.org release.
# Development tooling only: it is not part of the gem.
class Vocabulary
  VERSION = "30.1"
  SOURCE = "https://schema.org/version/#{VERSION}/schemaorg-current-https.jsonld".freeze

  # Downloads the vocabulary into dir once and returns the file path.
  def self.fetch(dir)
    path = File.join(dir, "schemaorg-#{VERSION}.jsonld")
    return path if File.exist?(path)

    FileUtils.mkdir_p(dir)
    File.write(path, download(URI(SOURCE)))
    path
  end

  def self.download(uri, redirects = 3)
    response = Net::HTTP.get_response(uri)
    return response.body if response.is_a?(Net::HTTPSuccess)

    redirect = response.is_a?(Net::HTTPRedirection) && redirects.positive?
    raise "Could not download #{uri}: #{response.code}" unless redirect

    download(URI.join(uri, response["location"]), redirects - 1)
  end

  def initialize(path)
    @types = {}
    @properties = {}
    @instances = {}
    JSON.parse(File.read(path))["@graph"].each { index(_1) }
  end

  # Problems with an entity class: unknown type, unknown properties, properties not allowed
  # on the type, date properties without a date range, unknown enum members.
  def check_entity(klass)
    type = klass.schema_type
    return ["#{klass}: #{type} is not a Schema.org type"] unless @types.key?(type)

    klass.declared_properties.values.flat_map { |property| check_property(klass, type, property) }
  end

  # Problems with a JSON-LD document: unknown types and properties, properties used on the
  # wrong type, and nested entities whose type is not allowed for the property.
  def check_document(document, label)
    nodes = document["@graph"] || [document]
    nodes.each_with_index.flat_map { |node, i| check_node(node, "#{label}[#{i}]") }
  end

  private

  def index(node)
    name = short(node["@id"])
    node_types = Array(node["@type"])
    if node_types.include?("rdfs:Class") then @types[name] = ids(node["rdfs:subClassOf"])
    elsif node_types.include?("rdf:Property") then @properties[name] = property_spec(node)
    else @instances[name] = node_types.map { short(_1) }
    end
  end

  def property_spec(node)
    { domain: ids(node["schema:domainIncludes"]), range: ids(node["schema:rangeIncludes"]) }
  end

  def ids(value) = (value.is_a?(Hash) ? [value] : Array(value)).map { short(_1["@id"]) }

  def short(id) = id.to_s.delete_prefix("schema:")

  def ancestors(type, seen = [])
    return [] if seen.include?(type)

    [type, *(@types[type] || []).flat_map { ancestors(_1, seen + [type]) }].uniq
  end

  def check_property(klass, type, property)
    spec = @properties[property.key]
    return ["#{klass}##{property.name}: #{property.key} is not a Schema.org property"] unless spec

    errors = []
    errors << "#{klass}##{property.name}: #{property.key} is not allowed on #{type}" unless allowed?(spec, type)
    errors.concat(check_kind(klass, property, spec))
  end

  def check_kind(klass, property, spec)
    case property.kind
    when :date
      return [] if spec[:range].intersect?(%w[Date DateTime])

      ["#{klass}##{property.name}: range of #{property.key} is #{spec[:range].join(", ")}, not a date"]
    when :enum
      property.allowed.reject { member_of?(_1, spec[:range]) }
              .map { "#{klass}##{property.name}: #{_1} is not a valid #{spec[:range].join("/")}" }
    else []
    end
  end

  def allowed?(spec, type) = spec[:domain].intersect?(ancestors(type))

  def member_of?(name, range) = (@instances[name] || []).any? { ancestors(_1).intersect?(range) }

  def check_node(node, path)
    return [] unless node.is_a?(Hash) && node.key?("@type")

    type = node["@type"]
    return ["#{path}: #{type} is not a Schema.org type"] unless @types.key?(type)

    node.flat_map do |key, value|
      key.start_with?("@") ? [] : check_value(type, key, value, "#{path}.#{key}")
    end
  end

  def check_value(type, key, value, path)
    spec = @properties[key]
    return ["#{path}: #{key} is not a Schema.org property"] unless spec
    return ["#{path}: #{key} is not allowed on #{type}"] unless allowed?(spec, type)

    items = value.is_a?(Array) ? value.each_with_index.map { |item, i| [item, "#{path}[#{i}]"] } : [[value, path]]
    items.flat_map { |item, item_path| check_item(key, spec, item, item_path) }
  end

  def check_item(key, spec, item, path)
    return [] unless item.is_a?(Hash) && item.key?("@type")

    type = item["@type"]
    return ["#{path}: #{type} is not allowed in #{key}"] unless ancestors(type).intersect?(spec[:range])

    check_node(item, path)
  end
end
