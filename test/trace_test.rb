require "test_helper"

class TraceTest < Minitest::Spec
  it do
    nested_activity.([{seq: []}])
  end

  it "traces flat activity" do
    stack, signal, (options, flow_options), _ = Dev::Trace.invoke( bc,
      [
        { seq: [] },
        { flow: true }
      ]
    )

    signal.class.inspect.must_equal %{Trailblazer::Activity::End}
    options.inspect.must_equal %{{:seq=>[:b, :c]}}
    flow_options[:flow].inspect.must_equal %{true}

    output = Dev::Trace::Present.(stack)
    output = output.gsub(/0x\w+/, "").gsub(/0x\w+/, "").gsub(/@.+_test/, "")

    output.must_equal %{`-- #<Trailblazer::Activity:>
   |-- Start.default
   |-- B
   |-- C
   `-- End.success}
  end

  it "allows nested tracing" do
    stack, _ = Dev::Trace.invoke( nested_activity,
      [
        { seq: [] },
        {}
      ]
    )

    output = Dev::Trace::Present.(stack)

    puts output = output.gsub(/0x\w+/, "").gsub(/0x\w+/, "").gsub(/@.+_test/, "")

    output.must_equal %{`-- #<Trailblazer::Activity:>
   |-- Start.default
   |-- B
   |-- D
   |   |-- Start.default
   |   |-- B
   |   |-- C
   |   `-- End.success
   |-- E
   `-- End.success}
  end

  it "Present allows to inject :renderer and pass through additional arguments to the renderer" do
    stack, _ = Dev::Trace.invoke( nested_activity,
      [
        { seq: [] },
        {}
      ]
    )

    renderer = ->(task_node:, position:, tree:) do
      assert tree[position] == task_node

      [
        task_node[:level],
        %{#{task_node[:level]}/#{task_node[:input].task}/#{task_node[:output].data}/#{task_node[:name]}/#{task_node[:color]}}
      ]
    end

    output = Dev::Trace::Present.(stack, renderer: renderer,
      color: "pink" # additional options.
    )

    output = output.gsub(/0x\w+/, "").gsub(/0x\w+/, "").gsub(/@.+_test/, "")

    output.must_equal %{`-- 1/#<Trailblazer::Activity:>/#<Trailblazer::Activity::End semantic=:success>/#<Trailblazer::Activity:>/pink
   |-- 2/#<Trailblazer::Activity::Start semantic=:default>/Trailblazer::Activity::Right/Start.default/pink
   |-- 2/#<Method: Trailblazer::Activity::Testing::Assertions::Implementing.b>/Trailblazer::Activity::Right/B/pink
   `-- 2/#<Trailblazer::Activity:>/#<Trailblazer::Activity::End semantic=:success>/D/pink
   |   |-- 3/#<Trailblazer::Activity::Start semantic=:default>/Trailblazer::Activity::Right/Start.default/pink
   |   |-- 3/#<Method: Trailblazer::Activity::Testing::Assertions::Implementing.b>/Trailblazer::Activity::Right/B/pink
   |   |-- 3/#<Method: Trailblazer::Activity::Testing::Assertions::Implementing.c>/Trailblazer::Activity::Right/C/pink
   |   `-- 3/#<Trailblazer::Activity::End semantic=:success>/#<Trailblazer::Activity::End semantic=:success>/End.success/pink
   |-- 2/#<Method: Trailblazer::Activity::Testing::Assertions::Implementing.f>/Trailblazer::Activity::Right/E/pink
   `-- 2/#<Trailblazer::Activity::End semantic=:success>/#<Trailblazer::Activity::End semantic=:success>/End.success/pink}
  end

  it "allows to inject custom :stack" do
    skip "this test goes to the developer gem"
    stack = Dev::Trace::Stack.new

    begin
      returned_stack, _ = Dev::Trace.invoke( nested_activity,
        [
          { content: "Let's start writing" },
          { stack: stack }
        ]
      )
    rescue
      # pp stack
      puts Dev::Trace::Present.(stack)
    end

    returned_stack.must_equal stack
  end
end
