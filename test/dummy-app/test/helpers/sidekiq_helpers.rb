# frozen_string_literal: true

module SidekiqHelpers
  def execute_job
    opts = { concurrency: 1, queues: ['default'] }
    boss = Sidekiq::Manager.new(opts)
    processor = Sidekiq::Processor.new(boss)

    processor.process_one
  end
end
