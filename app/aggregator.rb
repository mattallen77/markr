require 'sequel'
require 'descriptive_statistics/safe'
require_relative '../config/sequel'

module MarkBook
  RecordResult = Struct.new(:success?, :count, :error_message)
  Aggregates = Struct.new(:mean, :stddev, :min, :max, :p25, :p50, :p75, :count)

  class Aggregator
    def record(result_hash)
      begin
        count = 0
        DB.transaction do
          results = result_hash[:'mcq-test-results'][:'mcq-test-result']
          results = [results] unless results[0].kind_of?(Array)
          results.each do |result|
            flattened = Hash[*result.collect { |h| h.to_a }.flatten]
            result_summary = {
              'first_name': flattened[:'first-name'],
              'last_name': flattened[:'last-name'],
              'student_number': flattened[:'student-number'].to_i,
              'test_id': flattened[:'test-id'].to_i,
              'available': flattened[:'summary-marks'][:'available'].to_i,
              'obtained': flattened[:'summary-marks'][:'obtained'].to_i,
            }

            previous_result_summary =
              DB[:results_summary].where(
                first_name: result_summary[:first_name],
                last_name: result_summary[:last_name],
                test_id: result_summary[:test_id],
                student_number: result_summary[:student_number],
              ).first

            if !previous_result_summary
              DB[:results_summary].insert(result_summary)
              count += 1
            elsif result_summary[:obtained] >
                  previous_result_summary[:obtained] ||
                  result_summary[:available] >
                    previous_result_summary[:available]
              obtained = [
                result_summary[:obtained],
                previous_result_summary[:obtained],
              ].max
              available = [
                result_summary[:available],
                previous_result_summary[:available],
              ].max
              DB[:results_summary]
                .where(
                  test_id: result_summary[:test_id],
                  first_name: result_summary[:first_name],
                  last_name: result_summary[:last_name],
                  student_number: result_summary[:student_number],
                )
                .update(obtained: obtained, available: available)
              count += 1
            end
          end
        end
        RecordResult.new(true, count, nil)
      rescue NoMethodError => e
        return RecordResult.new(false, 0, 'invalid xml')
      rescue Sequel::Error => e
        return RecordResult.new(false, 0, 'invalid values')
      end
    end

    def aggregate(test_id)
      results = DB[:results_summary].where(test_id: test_id).all
      if results.empty?
        return Aggregates.new(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0)
      end
      percentages = results.map { |i| i[:obtained].to_f * 100 / i[:available] }
      percentages.extend(DescriptiveStatistics)
      Aggregates.new(
        percentages.mean.round(2),
        percentages.standard_deviation.round(2),
        percentages.min.round(2),
        percentages.max.round(2),
        percentages.percentile(25).round(2),
        percentages.percentile(50).round(2),
        percentages.percentile(75).round(2),
        results.length,
      )
    end
  end
end
