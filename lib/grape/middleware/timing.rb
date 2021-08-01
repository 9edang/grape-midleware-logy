module Grape
  module Middleware
    class Timing
      class << self
        def db_runtime=(value)
          Thread.current[:grape_db_runtime] = value
        end
    
        def db_runtime
          Thread.current[:grape_db_runtime] ||= 0
        end
    
        def reset_db_runtime
          self.db_runtime = 0
        end
    
        def append_db_runtime(event)
          self.db_runtime += event.duration
        end
    
        def ms_to_round_sec(ms)
          (ms.to_f / 1000).round(4)
        end
      end
    end
  end
end