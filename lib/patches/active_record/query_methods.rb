require 'active_record/relation/query_methods'

module ActiveRecord
  module QueryMethods

    def where(opts, *rest)
      if Hash === opts && @klass.respond_to?(:translated_attribute_names) && (translated_attributes = opts.keys & @klass.translated_attribute_names.to_a).present?
        opts = opts.dup
        translated_attributes.each { |attribute| opts[@klass.translated_column_name(attribute).to_sym] = opts.delete(attribute) }

        relation = clone
        relation.includes_values = (relation.includes_values + [:translations]).flatten.uniq
        relation.where_values += build_where(opts, rest)
        relation
      else
        return self if opts.blank?

        relation = clone
        relation.where_values += build_where(opts, rest)
        relation
      end
    end

  end
end
