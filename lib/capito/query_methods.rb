module Capito
  module QueryMethods

    attr_accessor :translations_reload_needed

    class WhereChain < ::ActiveRecord::QueryMethods::WhereChain
      def not(opts, *rest)
        if parsed = @scope.parse_translated_conditions(opts)
          @scope.translations_reload_needed = true
          @scope.where.not(parsed, *rest).includes(:translations).references(:translations)
        else
          super
        end
      end
    end

    def where(opts = :chain, *rest)
      if opts == :chain
        WhereChain.new(spawn)
      elsif parsed = parse_translated_conditions(opts)
        self.translations_reload_needed = true
        super(parsed, *rest).includes(:translations).references(:translations)
      else
        super
      end
    end

    def exists?(conditions = :none)
      if parsed = parse_translated_conditions(conditions)
        exists?(parsed)
      else
        super
      end
    end

    %w[ first last take ].each do |method_name|
      eval <<-END_RUBY
        def #{method_name}
          super.tap do |f|
            if f && translations_reload_needed
              f.translations.reload
              translations_reload_needed = false
            end
          end
        end
      END_RUBY
    end

    def parse_translated_conditions(opts)
      if opts.is_a?(Hash) && respond_to?(:translated_attribute_names) && (keys = opts.symbolize_keys.keys & translated_attribute_names.to_a).present?
        opts = opts.dup
        keys.each { |key| opts[translated_column_name(key)] = opts.delete(key) || opts.delete(key.to_s) }
        opts
      end
    end

    def where_values_hash
      equalities = respond_to?(:with_default_scope) ? with_default_scope.where_values : where_values
      equalities = equalities.grep(Arel::Nodes::Equality).find_all { |node|
        node.left.relation.name == translations_table_name
      }

      binds = Hash[bind_values.find_all(&:first).map { |column, v| [column.name, v] }]

      super.merge(Hash[equalities.map { |where|
            name = where.left.name
            [name, binds.fetch(name.to_s) { where.right }]
          }])
    end
  end
end
