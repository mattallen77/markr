# Markr -  marking as a service

Markr is a ruby web application for importing and aggregating test results.

## Installation

Use [docker](https://docs.docker.com/get-docker/) to install markr

```bash
docker-compose up
```

## Usage

```bash
# POST results
curl -X POST -H 'Content-Type: text/xml+markr' http://localhost:4567/import -d @- <<XML
    <mcq-test-results>
        <mcq-test-result scanned-on="2017-12-04T12:12:10+11:00">
            <first-name>Jane</first-name>
            <last-name>Austen</last-name>
            <student-number>521585128</student-number>
            <test-id>1234</test-id>
            <summary-marks available="20" obtained="13" />
        </mcq-test-result>
    </mcq-test-results>
XML

# Response body will contain a count of total inserts and updates
{"count":1}

# Response Codes

200  No error occurred
415  Content-Type is not text/xml+makr
422  Content was incomplete, none of the results have been recorded

# GET aggregates
curl http://localhost:4567/results/1234/aggregate

# Response body will contain the aggregates
{"mean":65.0,"stddev":0.0,"min":65.0,"max":65.0,"p25":65.0,"p50":65.0,"p
75":65.0,"count":1}

# Response codes
200 No error occurred
404 No results were found for the test-id

```

## Choices
Markr is written in [Ruby](https://www.ruby-lang.org) using the [Sinatra](http://sinatrarb.com/) web framework with a [SQLite](https://www.sqlite.org) database. 
XML parsing is done using [Ox](https://github.com/ohler55/ox) and the aggregates are calculated using [descriptive_statistics](https://github.com/thirtysixthspan/descriptive_statistics).

## Approach
- The data is structured so a relational database was chosen
- An embedded database was chosen for simplicity but could be replaced with client-server as the design evolves
- A denormalised single table is used for simplicity but could be normalised as the design evolves
- Indexes and constraints have been added to the database to ensure data integrity
- Sequel was chosen as a fast, simple model layer for this use case
- Ox was chosen as a fast xml processor
- SQLite was chosen as a fast embedded database
- A TDD approach was taken with acceptance, unit and integration tests

## Assumptions
- Students must be identified by the combination **student-number, first-name and last-name** (the provided xml file included duplicate student-numbers with different first-name and last-name)
- first-name and last-name must be present
- student-number and test-id must be present and are none-zero integers up to 4 bytes
- The obtained marks should always be less than the available marks
- With duplicate student records, both available marks and obtained marks should be updated independently to the highest values
- Available marks should be greater than zero
- Obtained marks should be less than or equal to available marks

## Further work
- Security should be added (SSL and authentication of the endpoint) based on what is supported by the grading machines
- More tests for invalid data could be added
- Database storage is currently pessimistic, checking for an existing entry before inserting/updating. If clashes are rare then an optimistic strategy, catching any UNIQUE constraint error would be more efficient
- If more detailed error responses are required then an explicit model with validation could be used
- If real-time dashboards are introduced then the retrievals will increase and need to be lower latency. The aggregates could be
cached in a separate table and independently refreshed or separated into another service entirely following a CQRS pattern
- Deployment (for example to AWS) should be considered taking into account the expected volume of import and aggregate calls for scaling and possible changes to the design to accommodate this
