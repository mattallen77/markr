require_relative '../../../app/api'
require 'rack/test'

module MarkBook
  RSpec.describe API do
    include Rack::Test::Methods

    def app
      API.new(aggregator: aggregator)
    end

    let(:aggregator) { instance_double('MarkBook::Aggregator') }

    describe 'POST /import' do
      context 'when the results are successfully recorded' do
        let(:results) { '<dummy>3</dummy>' }

        before do
          allow(aggregator).to receive(:record)
            .with({ dummy: '3' })
            .and_return(RecordResult.new(true, 1, nil))
        end

        it 'returns the count of records' do
          header 'Content-Type', 'text/xml+markr'
          post '/import', results

          parsed = JSON.parse(last_response.body)

          expect(parsed).to include('count' => 1)
        end

        it 'responds with a 200 (OK)' do
          header 'Content-Type', 'text/xml+markr'
          post '/import', results

          expect(last_response.status).to eq(200)
        end
      end

      context 'when the results validation fails' do
        let(:results) { '<dummy>3</dummy>' }

        before do
          allow(aggregator).to receive(:record)
            .with({ dummy: '3' })
            .and_return(RecordResult.new(false, 0, 'Results incomplete'))
        end

        it 'returns an error mesage' do
          header 'Content-Type', 'text/xml+markr'
          post '/import', results

          parsed = JSON.parse(last_response.body)

          expect(parsed).to include('error' => 'Results incomplete')
        end

        it 'responds with a 422 (Unprocessable entity)' do
          header 'Content-Type', 'text/xml+markr'
          post '/import', results

          parsed = JSON.parse(last_response.body)

          expect(last_response.status).to eq(422)
        end
      end
    end

    describe 'GET /results/:test-id/aggregate' do
      context 'when records exist for the given test-id' do
        before do
          allow(aggregator).to receive(:aggregate)
            .with('1234')
            .and_return(
              Aggregates.new(18, 3.0, 17.0, 24.0, 18.0, 20.0, 22.0, 8),
            )
        end

        it 'returns the aggregates for that test-id as JSON' do
          get '/results/1234/aggregate'

          parsed = JSON.parse(last_response.body)
          expect(parsed).to eq(
            {
              'mean' => 18,
              'stddev' => 3.0,
              'min' => 17.0,
              'max' => 24.0,
              'p25' => 18.0,
              'p50' => 20.0,
              'p75' => 22.0,
              'count' => 8,
            },
          )
        end

        it 'responds with a 200 (OK)' do
          get '/results/1234/aggregate'

          expect(last_response.status).to eq(200)
        end
      end

      context 'when there are no records for the given test-id' do
        before do
          allow(aggregator).to receive(:aggregate)
            .with('4567')
            .and_return(Aggregates.new(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0))
        end

        it 'returns 0 aggregates as JSON' do
          get '/results/4567/aggregate'

          parsed = JSON.parse(last_response.body)
          expect(parsed).to eq(
            {
              'mean' => 0.0,
              'stddev' => 0.0,
              'min' => 0.0,
              'max' => 0.0,
              'p25' => 0.0,
              'p50' => 0.0,
              'p75' => 0.0,
              'count' => 0,
            },
          )
        end

        it 'responds with a 404 (Not Found)' do
          get '/results/4567/aggregate'

          expect(last_response.status).to eq(404)
        end
      end
    end
  end
end
