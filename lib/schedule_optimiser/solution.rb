# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext'

require_relative 'machine'
require_relative 'solution_step'
require_relative 'task'

module ScheduleOptimiser
  class Solution
    attr_reader :current_runtime
    attr_reader :machine_order
    attr_reader :machine_tracker
    attr_reader :next_manual_available
    attr_reader :steps

    def initialize(machine_order:)
      @current_runtime = 0.0
      @machine_order = machine_order
      @machine_tracker = build_machine_tracker
      @next_manual_available = 0.0
      @steps = []

      add_steps
    end

    def total_runtime
      return nil if @steps.empty?
      ([0.0] + @steps.map(&:auto_end_at).compact).max
    end

    private

    def add_final_wait
      return if @steps.empty?
      final_wait_time = total_runtime - @current_runtime
      return unless final_wait_time.positive?
      wait_task = ScheduleOptimiser::Task.new(
        id: 'WAIT',
        start_at: @current_runtime,
        auto_time: final_wait_time
      )
      @current_runtime = wait_task.auto_end_at
      steps << ScheduleOptimiser::SolutionStep.new(task: wait_task)
    end

    def add_step(machine_id)
      return unless machine_steps_to_assign?(machine_id)

      add_wait_task(machine_id) if worker_unavailable? || machine_unavailable?(machine_id)
      create_and_add_next_task(machine_id)
      add_final_wait
    end

    def add_steps
      @machine_order.map(&:id).each do |machine_id|
        add_step(machine_id)
      end
    end

    def add_wait_task(machine_id)
      tracker = @machine_tracker[machine_id]
      start_at = [@next_manual_available, tracker[:next_auto_available]].max
      wait_task = ScheduleOptimiser::Task.new(
        id: 'WAIT',
        start_at: start_at,
        auto_time: start_at - @current_runtime
      )
      @steps << ScheduleOptimiser::SolutionStep.new(task: wait_task)
      @current_runtime = wait_task.auto_end_at
      tracker[:next_auto_available] = @current_runtime
    end

    def build_machine_tracker
      @machine_order.each_with_object({}) do |machine, result|
        result[machine.id] = {
          next_auto_available: 0.0,
          next_task_index: 0,
          tasks: machine.tasks.deep_dup
        }
      end
    end

    def create_and_add_next_task(machine_id)
      tracker = @machine_tracker[machine_id]
      task = tracker[:tasks][tracker[:next_task_index]]
      tracker[:next_task_index] += 1
      task.start_at = @current_runtime
      @current_runtime = task.manual_end_at
      tracker[:next_auto_available] = task.auto_end_at
      @steps << ScheduleOptimiser::SolutionStep.new(
        machine_id: machine_id,
        task: task
      )
    end

    def machine_available?(machine_id)
      @machine_tracker[machine_id][:next_auto_available] <= @current_runtime
    end

    def machine_unavailable?(machine_id)
      !machine_available?(machine_id)
    end

    def machine_steps_to_assign?(machine_id)
      machine = @machine_tracker[machine_id]
      machine[:tasks].count > machine[:next_task_index]
    end

    def worker_available?
      @next_manual_available <= @current_runtime
    end

    def worker_unavailable?
      !worker_available?
    end
  end
end
