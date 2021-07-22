Sequel.migration do
  change do
    create_table :results_summary do
      primary_key :id, null: false
      String :first_name, null: false
      String :last_name, null: false
      Integer :student_number, null: false
      Integer :test_id, null: false
      Integer :available, null: false
      Integer :obtained, null: false
      index %i[test_id student_number first_name last_name], unique: true
      constraint(:'student-number-non-zero') { student_number > 0 }
      constraint(:'test-id-none-zero') { test_id > 0 }
      constraint(:'available-non-zero') { available > 0 }
      constraint(:'obtained-at-most-available') { obtained <= available }
    end
  end
end
