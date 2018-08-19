# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext'

require_relative './machine'
require_relative './solution'

module ScheduleOptimiser
  class Solver
    attr_accessor :max_runtime_seconds

    attr_reader :best_solution
    attr_reader :machines
    attr_reader :run_start_at
    attr_reader :solutions

    def initialize(machines: [], data_hash: {}, max_runtime_seconds: 5)
      @machines = machines
      @max_runtime_seconds = max_runtime_seconds.second
      @run_start_at = nil
      @solutions = 0
      return if data_hash.empty?
      @machines = data_hash[:machines].map do |machine|
        Machine.new id: machine[:id],
                    tasks: machine[:tasks].map { |task| Task.new task }
      end
    end

    def solve
      @solutions = 0
      @run_start_at = Time.now
      machine_order_iterator = base_machine_order.permutation.each
      unique_machine_orders = []
      machine_id_map = @machines.each_with_object({}) do |machine, result|
        result[machine.id] = machine
      end
      loop do
        break unless within_max_runtime?
        next_machine_order = machine_order_iterator.next
        next if unique_machine_orders.include?(next_machine_order)
        solution = ScheduleOptimiser::Solution.new(
          machine_order: next_machine_order.map { |id| machine_id_map[id].deep_dup }
        )
        @solutions += 1
        if @best_solution.nil? || solution.total_runtime < @best_solution.total_runtime
          @best_solution = solution
        end
        unique_machine_orders << next_machine_order
      end
      pp "Solutions: #{@solutions}\nBest Solution: #{@best_solution.total_runtime}\n" \
        "Steps: #{@best_solution.steps}"
    end

    private

    def base_machine_order
      @machines.inject([]) do |result, machine|
        result + Array.new(machine.tasks.count, machine.id)
      end
    end

    def within_max_runtime?
      return false unless @max_runtime_seconds && @run_start_at
      Time.now < (@run_start_at + @max_runtime_seconds)
    end
  end
end
