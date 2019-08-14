require "test_helper"
require "trailblazer/developer/client"

class ClientTest < Minitest::Spec
  it do
    skip "we need to mock the server, first"

    # puts token = Dev::Client.retrieve_token(email: "apotonick@gmail.com", password: "nickitito123", host: "https://api.trailblazer.to")
    json = Dev::Client.import(id: 3, email: "apotonick@gmail.com", password: "nickitito123", host: "https://api.trailblazer.to", query: "?labels=validate%3Einvalid!%3E:failure")

    File.write("sip-#{Time.now}.json", json)

    duplicate = Dev::Client.duplicate(id: 2, email: "apotonick@gmail.com", password: "nickitito123", host: "https://api.trailblazer.to")
    puts "@@@@@ #{duplicate.id.inspect}"

  end

  it do
    skip "we need to mock the server, first"

# Client.new_diagram
    diagram = Dev::Client.new_diagram(token:"eyJhbGciOiJIUzI1NiJ9.eyJleHAiOjE1NjU5MzU5MjYsImlzcyI6IlRyYWlsYmxhemVyIiwiYXVkIjoicHJvIiwidXNlcl9pZCI6MX0.FngxHBgZd094o4-9wa4QXlpOl1lxOu-eyCLMVRIzHYg" , email: "apotonick@gmail.com", password: "blabla!", host: "http://localhost:3000")

    assert diagram.id > 0
    diagram.body.must_equal [] # the JSON is already parsed?

# Client.import
    json = Dev::Client.import(id: diagram.id, email: "apotonick@gmail.com", password: "blabla!", host: "http://localhost:3000")



  # Currently, this brings you a *formatted* JSON document and additionally added data, such as labels for connections.
    json.must_equal %{{
  "elements": [

  ]
}}

# Client.duplicate
    duplicate = Dev::Client.duplicate(id: diagram.id, email: "apotonick@gmail.com", password: "blabla!", host: "http://localhost:3000")

    assert duplicate.id > diagram.id
    assert duplicate.body.must_equal([]) # FIXME: better test!
  end
end
