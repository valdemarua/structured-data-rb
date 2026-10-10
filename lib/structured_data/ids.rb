# frozen_string_literal: true

module StructuredData
  # Builds @id values with a common convention. Optional: any absolute URI works as an id.
  #
  #   ids = StructuredData::Ids.new("https://example.com")
  #   ids.organization                         # => "https://example.com/#organization"
  #   ids.entity("/teams/rovers", :team)       # => "https://example.com/teams/rovers#team"
  class Ids
    URL = %r{\A(https?://[^\s/?#]+)(/\S*)?\z}
    KIND = /\A[\w-]+\z/

    attr_reader :base_url

    def initialize(base_url)
      match = URL.match(base_url.to_s) or
        raise ArgumentError, "expected an absolute http(s) base URL, got #{base_url.inspect}"

      @origin = match[1].freeze
      @base_url = base_url.to_s.delete_suffix("/").freeze
      freeze
    end

    def organization = site(:organization)

    def website = site(:website)

    # A site-wide node: "<base>/#<name>".
    def site(name) = "#{base_url}/##{kind!(name)}"

    # The absolute URL of a page, without a fragment. Paths starting with "/" resolve against the base origin.
    def page(url_or_path)
      value = url_or_path.to_s
      url = if URL.match?(value) then value
            elsif value.start_with?("/") then "#{@origin}#{value}"
            else raise ArgumentError, "expected an absolute URL or a path starting with /, got #{value.inspect}"
            end
      url.sub(/#.*\z/, "")
    end

    # The main entity of a page: "<page>#<kind>".
    def entity(url_or_path, kind) = "#{page(url_or_path)}##{kind!(kind)}"

    private

    def kind!(kind)
      kind = kind.to_s
      KIND.match?(kind) or raise ArgumentError, "expected letters, digits, _ or -, got #{kind.inspect}"
      kind
    end
  end
end
