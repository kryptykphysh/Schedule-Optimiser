# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext'

module ScheduleOptimiser
  class Task
    attr_accessor :start_at

    attr_reader :auto_time
    attr_reader :id
    attr_reader :manual_time

    def initialize(id:, start_at: nil, auto_time: 0.0, manual_time: 0.0)
      @auto_time = auto_time
      @id = id
      @manual_time = manual_time
      @start_at = start_at
    end

    def auto_end_at
      return nil unless manual_end_at
      manual_end_at + auto_time
    end

    def manual_end_at
      return nil unless start_at
      start_at + manual_time
    end
  end
end
