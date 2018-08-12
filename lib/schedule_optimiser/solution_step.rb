# frozen_string_literal: true

module ScheduleOptimiser
  class SolutionStep
    attr_reader :machine_id
    attr_reader :task

    def initialize(machine_id: nil, task:)
      @machine_id = machine_id
      @task = task
    end

    def auto_end_at
      task.auto_end_at
    end

    def manual_end_at
      task.auto_end_at
    end
  end
end
