require "test_helper"

class DocsDeveloperTest < Minitest::Spec
  #:constant
  # config/initializers/trailblazer.rb
  require "trailblazer/developer"
  Dev = Trailblazer::Developer
  #:constant end

  class Form
    def self.validate(input:)
      input
    end
  end

  Memo = Struct.new(:text) do
    def self.create(options)
      new(options)
    end
  end

  it do
    class Memo
      #:step
      class Create < Trailblazer::Activity::Path
        step :validate
        step :create
        #~mod
        def validate(ctx, params:, **)
          ctx[:input] = Form.validate(input: params)
        end

        def create(ctx, input:, **)
          Memo.create(input)
        end
        #~mod end
      end
      #:step end
    end

    ctx = {params: {text: "Hydrate!"}}

    #:wtf
    signal, (ctx, flow_options) = Dev.wtf?(Memo::Create, [ctx, {}])
    #:wtf end

    signal.inspect.must_equal %{#<Trailblazer::Activity::End semantic=:success>}
    ctx.inspect.must_equal %{{:params=>{:text=>\"Hydrate!\"}, :input=>{:text=>\"Hydrate!\"}}}

=begin
#:wtf-print
[Trailblazer] Exception tracing
#ArgumentError: missing keyword: input>
    /home/nick/projects/trailblazer-developer/test/docs/developer_test.rb:9:in `validate'
    /home/nick/projects/trailblazer-developer/test/docs/developer_test.rb:27:in `validate'

`-- DocsDeveloperTest::Memo::Create
    |-- Start.default
    `-- validate
#:wtf-print end
=end
  end

  it do
    class Bla < Trailblazer::Activity::Path
      step :a

      def a(ctx, **)
        true
      end
    end

    assert_raises TypeError do
      #:type-err
      ctx = {"message" => "Not gonna work!"} # bare hash.
      Bla.([ctx])
      #:type-err end
    end

=begin
#:type-exc
TypeError: wrong argument type String (expected Symbol)
#:type-exc end
=end

    #:type-ctx
    ctx = Trailblazer::Context({"message" => "Yes, works!"})

    signal, (ctx, _) = Bla.([ctx])
    #:type-ctx end
    signal.inspect.must_equal %{#<Trailblazer::Activity::End semantic=:success>}
  end

  it do
    module A
    #:wire-class
    class Update < Trailblazer::Activity::Railway
      class CheckAttribute < Trailblazer::Activity::Railway
        step :valid?
      end

      step :find_model
      step Subprocess(CheckAttribute), id: :a
      step Subprocess(CheckAttribute), id: :b # same task!
      step :save
    end
    #:wire-class end
    end

=begin
#:wire-puts
puts Trailblazer::Developer.render(Update)

#<Start/:default>
 {Trailblazer::Activity::Right} => #<Trailblazer::Activity::TaskBuilder::Task user_proc=find_model>
#<Trailblazer::Activity::TaskBuilder::Task user_proc=find_model>
 {Trailblazer::Activity::Left} => #<End/:failure>
 {Trailblazer::Activity::Right} => DocsDeveloperTest::Update::CheckAttribute
DocsDeveloperTest::Update::CheckAttribute
 {#<Trailblazer::Activity::End semantic=:failure>} => #<End/:failure>
 {#<Trailblazer::Activity::End semantic=:success>} => #<Trailblazer::Activity::TaskBuilder::Task user_proc=save>
#<Trailblazer::Activity::TaskBuilder::Task user_proc=save>
#:wire-puts end
=end

    #:wire-fix
    class class Update < Trailblazer::Activity::Railway
      class CheckAttribute < Trailblazer::Activity::Railway
        step :valid?
      end

      step :find_model
      step Subprocess(CheckAttribute), id: :a
      step Subprocess(Class.new(CheckAttribute)), id: :b # different task!
      step :save
    end
    #:wire-fix end
  end
end
