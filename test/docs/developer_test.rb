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

  it 'wtf?' do
    #:step
    class Memo::Create < Trailblazer::Activity::Path
      step :validate
      step :create, id: :create_memo
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

    ctx = {params: {text: "Hydrate!"}}
    signal, (ctx, ) = Dev.wtf?(Memo::Create, [ctx, {}])

    _(signal.inspect).must_equal %{#<Trailblazer::Activity::End semantic=:success>}
    _(ctx.inspect).must_equal %{{:params=>{:text=>\"Hydrate!\"}, :input=>{:text=>\"Hydrate!\"}}}

    output, _ = capture_io do
      #:wtf-focus-steps
      Dev.wtf?(Memo::Create, [ctx, { focus_on: { steps: [:validate, :create_memo] } }])
      #:wtf-focus-steps end
    end

    _(output.gsub(/0x\w+/, "")).must_equal %{`-- DocsDeveloperTest::Memo::Create
    |-- \e[32mStart.default\e[0m
    |-- \e[32mvalidate\e[0m
    |   |-- \e[32m********* Input *********
             input: {:text=>\"\\\"Hydrate!\\\"\"}
            params: {:text=>\"\\\"Hydrate!\\\"\"}\e[0m
    |   `-- \e[32m********* Output *********
             input: {:text=>\"\\\"Hydrate!\\\"\"}
            params: {:text=>\"\\\"Hydrate!\\\"\"}\e[0m
    |-- \e[32mcreate_memo\e[0m
    |   |-- \e[32m********* Input *********
             input: {:text=>\"\\\"Hydrate!\\\"\"}
            params: {:text=>\"\\\"Hydrate!\\\"\"}\e[0m
    |   `-- \e[32m********* Output *********
             input: {:text=>\"\\\"Hydrate!\\\"\"}
            params: {:text=>\"\\\"Hydrate!\\\"\"}\e[0m
    `-- End.success
}

    output, _ = capture_io do
      #:wtf-focus-steps-with-variables
      Dev.wtf?(Memo::Create, [ctx, { focus_on: { variables: [:params], steps: :validate } }])
      #:wtf-focus-steps-with-variables end
    end

    _(output.gsub(/0x\w+/, "")).must_equal %{`-- DocsDeveloperTest::Memo::Create
    |-- \e[32mStart.default\e[0m
    |-- \e[32mvalidate\e[0m
    |   |-- \e[32m********* Input *********
            params: {:text=>\"\\\"Hydrate!\\\"\"}\e[0m
    |   `-- \e[32m********* Output *********
            params: {:text=>\"\\\"Hydrate!\\\"\"}\e[0m
    |-- \e[32mcreate_memo\e[0m
    `-- End.success
}

    output, _ = capture_io do
      #:wtf-default-inspector
      Dev.wtf?(
        Memo::Create,
        [
          { params: { text: 'Hydrate!', value: nil } },
          {
            focus_on: { steps: :validate, variables: :params },
            default_inspector: ->(value){ value.nil? ? 'UNKNOWN' : value.inspect }
          }
        ]
      )
      #:wtf-default-inspector end
    end

    _(output.gsub(/0x\w+/, "")).must_equal %{`-- DocsDeveloperTest::Memo::Create
    |-- \e[32mStart.default\e[0m
    |-- \e[32mvalidate\e[0m
    |   |-- \e[32m********* Input *********
            params: {:text=>\"\\\"Hydrate!\\\"\", :value=>\"UNKNOWN\"}\e[0m
    |   `-- \e[32m********* Output *********
            params: {:text=>\"\\\"Hydrate!\\\"\", :value=>\"UNKNOWN\"}\e[0m
    |-- \e[32mcreate_memo\e[0m
    `-- End.success
}
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
    _(signal.inspect).must_equal %{#<Trailblazer::Activity::End semantic=:success>}
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
    class Update < Trailblazer::Activity::Railway
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

  it 'IllegalSignalError' do
    assert_raises Trailblazer::Activity::Circuit::IllegalSignalError do
      #:illegal-signal-error
      class Create < Trailblazer::Activity::Railway
        def self.validate((ctx, flow_options), **circuit_options)
          return :invalid_signal, [ctx, flow_options], circuit_options
        end

        step task: method(:validate)
      end

      ctx = {"message" => "Not gonna work!"} # bare hash.
      Create.([ctx])

      # IllegalSignalError: Create:
      # Unrecognized Signal `:invalid_signal` returned from `Method: Create.validate`. Registered signals are,
      # - Trailblazer::Activity::Left
      # - Trailblazer::Activity::Right
      #:illegal-signal-error end
    end
  end
end
