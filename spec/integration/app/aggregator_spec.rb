require_relative '../../../app/aggregator'

module MarkBook
  RSpec.describe Aggregator, :aggregate_failures, :db do
    let(:aggregator) { Aggregator.new }
    let(:results) do
      {
        'mcq-test-results': {
          'mcq-test-result': [
            { 'scanned-on': '2017-12-04T12:12:10+11:00' },
            { 'first-name': 'Jane' },
            { 'last-name': 'Austen' },
            { 'student-number': '521585128' },
            { 'test-id': '1234' },
            { 'summary-marks': [{ available: '20', obtained: '13' }] },
          ],
        },
      }
    end

    describe '#record' do
      context 'with valid results data' do
        it 'successfullly saves the results in the DB' do
          result = aggregator.record(results)

          expect(result).to be_success
          expect(result.count).to eq(1)
          expect(DB[:results_summary].all).to match [
                  a_hash_including(
                    first_name: 'Jane',
                    last_name: 'Austen',
                    student_number: 521_585_128,
                    test_id: 1234,
                    available: 20,
                    obtained: 13,
                  ),
                ]
        end

        context 'with repeated result for a student and test' do
          before do
            aggregator.record(
              {
                'mcq-test-results': {
                  'mcq-test-result': [
                    { 'scanned-on': '2017-12-04T12:12:10+11:00' },
                    { 'first-name': 'Jane' },
                    { 'last-name': 'Austen' },
                    { 'student-number': '521585128' },
                    { 'test-id': '1234' },
                    { 'summary-marks': [{ available: '20', obtained: '13' }] },
                  ],
                },
              },
            )
          end

          context 'when the new obtained score is higher' do
            it 'replaces the students obtained score' do
              result =
                aggregator.record(
                  {
                    'mcq-test-results': {
                      'mcq-test-result': [
                        { 'scanned-on': '2017-12-04T12:12:10+11:00' },
                        { 'first-name': 'Jane' },
                        { 'last-name': 'Austen' },
                        { 'student-number': '521585128' },
                        { 'test-id': '1234' },
                        {
                          'summary-marks': [
                            { available: '20', obtained: '15' },
                          ],
                        },
                      ],
                    },
                  },
                )

              expect(result.count).to eq(1)
              expect(DB[:results_summary].all).to match [
                      a_hash_including(
                        first_name: 'Jane',
                        last_name: 'Austen',
                        student_number: 521_585_128,
                        test_id: 1234,
                        available: 20,
                        obtained: 15,
                      ),
                    ]
            end
          end

          context 'when the new obtained score is lower' do
            it 'does not replace the students obtained score' do
              result =
                aggregator.record(
                  {
                    'mcq-test-results': {
                      'mcq-test-result': [
                        { 'scanned-on': '2017-12-04T12:12:10+11:00' },
                        { 'first-name': 'Jane' },
                        { 'last-name': 'Austen' },
                        { 'student-number': '521585128' },
                        { 'test-id': '1234' },
                        {
                          'summary-marks': [
                            { available: '20', obtained: '11' },
                          ],
                        },
                      ],
                    },
                  },
                )

              expect(result.count).to eq(0)
              expect(DB[:results_summary].all).to match [
                      a_hash_including(
                        first_name: 'Jane',
                        last_name: 'Austen',
                        student_number: 521_585_128,
                        test_id: 1234,
                        available: 20,
                        obtained: 13,
                      ),
                    ]
            end
          end
        end
      end

      context 'when the results data lacks top level mcq-test-results element' do
        it 'rejects the results data as invalid' do
          result = aggregator.record({})

          expect(result).not_to be_success
          expect(result.count).to eq(0)
          expect(result.error_message).to include('invalid xml')
        end
      end

      context 'when the results data lacks mcq-test-result elements do' do
        it 'rejects the results data as invalid' do
          result = aggregator.record({ 'mcq-test-results': {} })

          expect(result).not_to be_success
          expect(result.count).to eq(0)
          expect(result.error_message).to include('invalid xml')
        end
      end

      context 'when the results data lacks a student-number' do
        it 'rejects the results data as invalid' do
          result =
            aggregator.record(
              {
                'mcq-test-results': {
                  'mcq-test-result': [
                    { 'first-name': 'Jane' },
                    { 'last-name': 'Austen' },
                    { 'test-id': '1234' },
                    { 'summary-marks': [{ available: '20', obtained: '13' }] },
                  ],
                },
              },
            )
          expect(result).not_to be_success
          expect(result.count).to eq(0)
        end
      end

      context 'when the results data lacks a first name' do
        it 'rejects the results data as invalid' do
          result =
            aggregator.record(
              {
                'mcq-test-results': {
                  'mcq-test-result': [
                    { 'last-name': 'Austen' },
                    { 'student-number': '521585128' },
                    { 'test-id': '1234' },
                    { 'summary-marks': [{ available: '20', obtained: '13' }] },
                  ],
                },
              },
            )
          expect(result).not_to be_success
          expect(result.count).to eq(0)
        end
      end

      context 'when the results data lacks a last_name' do
        it 'rejects the results data as invalid' do
          result =
            aggregator.record(
              {
                'mcq-test-results': {
                  'mcq-test-result': [
                    { 'first-name': 'Jane' },
                    { 'student-number': '521585128' },
                    { 'test-id': '1234' },
                    { 'summary-marks': [{ available: '20', obtained: '13' }] },
                  ],
                },
              },
            )
          expect(result).not_to be_success
          expect(result.count).to eq(0)
        end
      end

      context 'when the results data lacks test-id' do
        it 'rejects the results data as invalid' do
          result =
            aggregator.record(
              {
                'mcq-test-results': {
                  'mcq-test-result': [
                    { 'student_number': '521585128' },
                    { 'summary-marks': [{ available: '20', obtained: '13' }] },
                  ],
                },
              },
            )
          expect(result).not_to be_success
          expect(result.count).to eq(0)
        end
      end

      context 'when the results data lacks summary-marks' do
        it 'rejects the results data as invalid' do
          result =
            aggregator.record(
              {
                'mcq-test-results': {
                  'mcq-test-result': [
                    { 'student-number': '521585128' },
                    { 'test-id': '1234' },
                  ],
                },
              },
            )
          expect(result).not_to be_success
          expect(result.count).to eq(0)
          expect(result.error_message).to eq('invalid xml')
        end
      end

      context 'when the results data lacks summary-marks available' do
        it 'rejects the results data as invalid' do
          result =
            aggregator.record(
              {
                'mcq-test-results': {
                  'mcq-test-result': [
                    { 'student-number': '521585128' },
                    { 'test-id': '1234' },
                    { 'summary-marks': [{ obtained: '13' }] },
                  ],
                },
              },
            )
          expect(result).not_to be_success
          expect(result.count).to eq(0)
          expect(result.error_message).to eq('invalid values')
        end
      end
    end

    describe '#aggregate' do
      it 'returns aggregate results for the provided test-id' do
        aggregator.record(
          {
            'mcq-test-results': {
              'mcq-test-result': [
                [
                  { 'first-name': 'Tom' },
                  { 'last-name': 'Riddle' },
                  { 'student-number': '1' },
                  { 'test-id': '1234' },
                  { 'summary-marks': [{ obtained: '7', available: '10' }] },
                ],
                [
                  { 'first-name': 'Tom' },
                  { 'last-name': 'Jones' },
                  { 'student-number': '2' },
                  { 'test-id': '1234' },
                  { 'summary-marks': [{ obtained: '8', available: '10' }] },
                ],
                [
                  { 'first-name': 'Peter' },
                  { 'last-name': 'Piper' },
                  { 'student-number': '3' },
                  { 'test-id': '1234' },
                  { 'summary-marks': [{ obtained: '9', available: '10' }] },
                ],
              ],
            },
          },
        )

        result = aggregator.aggregate('1234')

        expect(result.mean).to eq(80.0)
        expect(result.stddev).to eq(8.16)
        expect(result.min).to eq(70.0)
        expect(result.max).to eq(90.0)
        expect(result.p25).to eq(75.0)
        expect(result.p50).to eq(80.0)
        expect(result.p75).to eq(85.0)
        expect(result.count).to eq(3)
      end
    end
  end
end
