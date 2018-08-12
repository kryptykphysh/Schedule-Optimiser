# frozen_string_literal: true

require_relative './task'

module ScheduleOptimiser
  class Machine
    attr_reader :id
    attr_reader :tasks

    def initialize(id:, tasks: [])
      @id = id
      @tasks = tasks
    end
  end
end
