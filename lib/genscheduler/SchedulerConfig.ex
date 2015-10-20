defmodule SchedulerConfig do

  defstruct interval: 5000, max_runs: :infinity, nth_run: 0, start_time: :erlang.time, status: :enabled, async: false, stash: nil, module_name: nil, scheduler_state: nil
  
end