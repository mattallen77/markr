require 'sinatra/base'
require 'ox'
require 'json'
require_relative 'aggregator'

module MarkBook
  class API < Sinatra::Base
    def initialize(aggregator: Aggregator.new)
      @aggregator = aggregator
      super()
    end

    post '/import' do
      unless request.content_type == 'text/xml+markr'
        return [
          415,
          JSON.generate('error' => 'content-type must be text/xml+makr')
        ]
      end

      request.body.rewind
      results = Ox.load(request.body.read, mode: :hash)
      result = @aggregator.record(results)

      if result.success?
        JSON.generate('count' => result.count)
      else
        status 422
        JSON.generate('error' => result.error_message)
      end
    end

    get '/results/:id/aggregate' do
      aggregates = @aggregator.aggregate(params['id'])

      status 404 if aggregates[:count] == 0
      JSON.generate(aggregates.to_h)
    end
  end
end
