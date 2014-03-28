module Commendo

  class WeightedGroup

    attr_accessor :content_sets

    def initialize(*content_sets)
      @content_sets = content_sets
    end

    def similar_to(resource)
      results = []
      content_sets.each do |cs|
        similar_resources = cs[:cs].similar_to(resource)
        similar_resources.each do |similar_resource|
          existing_results = results.select { |er| er[:resource] == similar_resource[:resource] }
          existing_results.first[:similarity] += similar_resource[:similarity] * cs[:weight] unless existing_results.empty?
          results << similar_resource if existing_results.empty?
        end
      end
      results
    end

  end

end