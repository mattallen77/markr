require_relative 'app/api'

Sequel.extension :migration
Sequel::Migrator.run(DB, 'db/migrations')

run MarkBook::API.new
