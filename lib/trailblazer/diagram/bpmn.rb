require "representable"
require "representable/xml"

require "trailblazer/developer/circuit"

module Trailblazer
  module Diagram
    module BPMN
        Shape = Struct.new(:id, :element, :bounds)
        Bounds = Struct.new(:x, :y, :width, :height)

      # Render an `Activity`'s circuit to a BPMN 2.0 XML `<process>` structure.
      def self.to_xml(activity, railway, *args)
        # convert circuit to representable data structure.
        model = Trailblazer::Developer::Circuit.bla(activity, *args)

        raise "something wrong!" if model.task.size != railway.size
        # raise railway[0].last[:name].inspect

        linear_tasks = railway.collect { |row| row.last[:name] } # [:a, :b, :bb, :c, :d, :e, :f]

        start_x = 200
        y_right = 200
        y_left  = 300

        shape_width = 33
        shape_to_shape = 18

        # steps_total_width = railway.size * (shape_width + shape_to_shape)

        current = start_x
        shapes = []

        shapes << Shape.new("Shape_#{model.start_events[0].id}", model.start_events[0].id, Bounds.new(current, y_right, shape_width, shape_width))
        current += shape_width+shape_to_shape

        linear_tasks.each do |name| # DISCUSS: assuming that task is in correct linear order.
          task = model.task.find { |t| t.name == name } or raise "unfixable"

          is_right = task.incoming[0].direction == Trailblazer::Circuit::Right

          shapes << Shape.new("Shape_#{task.id}", task.id, Bounds.new(current, is_right ? y_right : y_left , shape_width, shape_width))
          current += shape_width+shape_to_shape
        end



        pplane = Struct.new(:shapes)

        # shapes = [sshape.new(1, "bla", bbounds.new(1,2,3,4))]
        diagram = Struct.new(:plane).new(pplane.new(shapes))

        # render XML.
        Representer::Definitions.new(Definitions.new(model, diagram)).to_xml
      end

      Definitions = Struct.new(:process, :diagram)

      # Representers for BPMN XML.
      module Representer
        class Task < Representable::Decorator
          include Representable::XML
          include Representable::XML::Namespace
          namespace "http://www.omg.org/spec/BPMN/20100524/MODEL"

          self.representation_wrap = :task # overridden via :as.

          property :id,   attribute: true
          property :name, attribute: true

          collection :outgoing, exec_context: :decorator
          collection :incoming, exec_context: :decorator

          def outgoing
            represented.outgoing.map(&:id)
          end

          def incoming
            represented.incoming.map(&:id)
          end
        end

        class SequenceFlow < Representable::Decorator
          include Representable::XML
          include Representable::XML::Namespace
          self.representation_wrap = :sequenceFlow
          namespace "http://www.omg.org/spec/BPMN/20100524/MODEL"

          property :id,   attribute: true
          property :sourceRef, attribute: true, exec_context: :decorator
          property :targetRef, attribute: true, exec_context: :decorator
          property :direction, as: :conditionExpression

          def sourceRef
            represented.sourceRef.id
          end

          def targetRef
            represented.targetRef.id
          end
        end

        class Process < Representable::Decorator
          include Representable::XML
          include Representable::XML::Namespace
          self.representation_wrap = :process

          namespace "http://www.omg.org/spec/BPMN/20100524/MODEL"

          collection :start_events, as: :startEvent, decorator: Task
          collection :end_events, as: :endEvent, decorator: Task
          collection :task, decorator: Task
          collection :sequence_flow, decorator: SequenceFlow, as: :sequenceFlow
        end


        module Diagram
          class Bounds < Representable::Decorator
            include Representable::XML
            include Representable::XML::Namespace
            self.representation_wrap = :Bounds

            namespace "http://www.omg.org/spec/DD/20100524/DC"

            property :x,      attribute: true
            property :y,      attribute: true
            property :width,  attribute: true
            property :height, attribute: true
          end

          class Diagram < Representable::Decorator
            feature Representable::XML
            feature Representable::XML::Namespace
            self.representation_wrap = :BPMNDiagram

            namespace "http://www.omg.org/spec/BPMN/20100524/DI"

            property :plane, as: "BPMNPlane" do
              self.representation_wrap = :plane

              namespace "http://www.omg.org/spec/BPMN/20100524/DI"

              collection :shapes, as: "BPMNShape" do
                self.representation_wrap = :BPMNShape
                namespace "http://www.omg.org/spec/BPMN/20100524/DI"

                property :id,                        attribute: true
                property :element, as: :bpmnElement, attribute: true

                property :bounds, as: "Bounds", decorator: Bounds
              end
              # collection :edges,  as: "BPMNEdge"
            end

            # namespace "http://www.w3.org/2001/XMLSchema-instance" # xsi
          end
        end



        class Definitions < Representable::Decorator
          include Representable::XML
          include Representable::XML::Namespace
          self.representation_wrap = :definitions

          namespace "http://www.omg.org/spec/BPMN/20100524/MODEL"
          namespace_def bpmn: "http://www.omg.org/spec/BPMN/20100524/MODEL"
          namespace_def bpmndi: "http://www.omg.org/spec/BPMN/20100524/DI"

          namespace_def dc: "http://www.omg.org/spec/DD/20100524/DC"

          property :process, decorator: Process
          property :diagram, decorator: Diagram::Diagram, as: :BPMNDiagram
        end
      end
    end
  end
end


# <bpmndi:BPMNDiagram id="BPMNDiagram_1">
#   <bpmndi:BPMNPlane id="BPMNPlane_1">
#      <bpmndi:BPMNShape id="_BPMNShape_Task_2" bpmnElement="Task_2">
#         <dc:Bounds x="100" y="100" width="36" height="36" />
#      </bpmndi:BPMNShape>
#      <bpmndi:BPMNShape id="_BPMNShape_Task_3" bpmnElement="Task_3">
#         <dc:Bounds x="236" y="78" width="100" height="80" />
#      </bpmndi:BPMNShape>
#      <bpmndi:BPMNEdge id="_BPMNConnection_Flow_4" bpmnElement="Flow_4">
#         <di:waypoint xsi:type="dc:Point" x="136" y="118" />
#         <di:waypoint xsi:type="dc:Point" x="236" y="118" />
#      </bpmndi:BPMNEdge>
#      <bpmndi:BPMNShape id="_BPMNShape_Task_5" bpmnElement="Task_5">
#         <dc:Bounds x="436" y="78" width="100" height="80" />
#      </bpmndi:BPMNShape>
#      <bpmndi:BPMNEdge id="_BPMNConnection_Flow_6" bpmnElement="Flow_6">
#         <di:waypoint xsi:type="dc:Point" x="336" y="118" />
#         <di:waypoint xsi:type="dc:Point" x="436" y="118" />
#      </bpmndi:BPMNEdge>
#      <bpmndi:BPMNShape id="_BPMNShape_Task_1" bpmnElement="Task_1">
#         <dc:Bounds x="636" y="100" width="36" height="36" />
#      </bpmndi:BPMNShape>
#      <bpmndi:BPMNShape id="_BPMNShape_Task_8" bpmnElement="Task_8">
#         <dc:Bounds x="636" y="266" width="100" height="80" />
#      </bpmndi:BPMNShape>
#      <bpmndi:BPMNEdge id="_BPMNConnection_Flow_7" bpmnElement="Flow_7">
#         <di:waypoint xsi:type="dc:Point" x="536" y="118" />
#         <di:waypoint xsi:type="dc:Point" x="636" y="118" />
#      </bpmndi:BPMNEdge>
#      <bpmndi:BPMNEdge id="_BPMNConnection_Flow_9" bpmnElement="Flow_9">
#         <di:waypoint xsi:type="dc:Point" x="536" y="118" />
#         <di:waypoint xsi:type="dc:Point" x="586" y="118" />
#         <di:waypoint xsi:type="dc:Point" x="586" y="306" />
#         <di:waypoint xsi:type="dc:Point" x="636" y="306" />
#      </bpmndi:BPMNEdge>
#      <bpmndi:BPMNEdge id="_BPMNConnection_Flow_10" bpmnElement="Flow_10">
#         <di:waypoint xsi:type="dc:Point" x="686" y="266" />
#         <di:waypoint xsi:type="dc:Point" x="686" y="201" />
#         <di:waypoint xsi:type="dc:Point" x="654" y="201" />
#         <di:waypoint xsi:type="dc:Point" x="654" y="136" />
#      </bpmndi:BPMNEdge>
#   </bpmndi:BPMNPlane>
# </bpmndi:BPMNDiagram>
