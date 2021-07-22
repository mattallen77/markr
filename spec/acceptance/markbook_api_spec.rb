require 'rack/test'
require_relative '../../app/api'
require_relative '../../config/sequel'

module MarkBook
  RSpec.describe 'Markr API', :aggregate_failures, :db do
    include Rack::Test::Methods

    def app
      MarkBook::API.new
    end

    results_xml = File.read('spec/resources/sample_result.xml')

    it 'aggregates submitted result' do
      header 'Content-Type', 'text/xml+markr'
      post '/import', results_xml

      expect(last_response.status).to eq(200)

      get '/results/1234/aggregate'

      expect(last_response.status).to eq(200)
      stats = JSON.parse(last_response.body)
      expect(stats['mean']).to eq(65.0)
      expect(stats['stddev']).to eq(0.0)
      expect(stats['min']).to eq(65.0)
      expect(stats['max']).to eq(65.0)
      expect(stats['p25']).to eq(65.0)
      expect(stats['p50']).to eq(65.0)
      expect(stats['p75']).to eq(65.0)
      expect(stats['count']).to eq(1)
    end

    it 'does not accept content-type other than text/xml+markr' do
      header 'Content-Type', 'text/xml'
      post '/import', results_xml

      expect(last_response.status).to eq(415)
    end

    context 'when no data for test-id' do
      it 'responds with 404' do
        get '/results/4567/aggregate'

        expect(last_response.status).to eq(404)
        stats = JSON.parse(last_response.body)
        expect(stats['mean']).to eq(0.0)
        expect(stats['stddev']).to eq(0.0)
        expect(stats['min']).to eq(0.0)
        expect(stats['max']).to eq(0.0)
        expect(stats['p25']).to eq(0.0)
        expect(stats['p50']).to eq(0.0)
        expect(stats['p75']).to eq(0.0)
        expect(stats['count']).to eq(0)
      end
    end
  end
end
