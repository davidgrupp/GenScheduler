defmodule GenScheduler do
  use Behaviour
  use GenServer
  @callback handle_execute(state :: term) ::
    {:ok, state} |
    {:stop, reason :: any} when state: any
	
  @callback init(args :: term) ::
    {:ok, state} |
    {:ok, state, timeout | :hibernate} |
    :ignore |
    {:stop, reason :: any} when state: any

  @callback terminate(reason, state :: term) ::
    term when reason: :normal | :shutdown | {:shutdown, term} | term
	
  def start_link(module_name, args) do
    {:ok, stash_pid} = Agent.start(fn ->{} end)
	config = %SchedulerConfig{ stash: stash_pid, module_name: module_name }
	Agent.update(stash_pid, fn _ -> config end)
    GenServer.start_link(__MODULE__, {stash_pid, args})
  end
  
  def init({stash_pid, args}) do
    GenServer.cast(self, :execute)
    
    sched_config = Agent.get(stash_pid, fn x -> x end)
    
    {:ok, scheduler_init_state} = sched_config.module_name.init(args)
    init_config = sched_config.module_name.initial_configuration
    config = init_config
				|> Map.put(:scheduler_state, scheduler_init_state)
				|> Map.put(:stash, sched_config.stash)
				|> Map.put(:module_name, sched_config.module_name)
    
    {:ok, config}
  end
	  
  def terminate(reason, config) do
	    config.module_name.terminate(reason, config.scheduler_state)
        Agent.update(config.stash, fn _ -> config end)
  end
  
  def handle_call(_,_,_) do
    raise "'Call' unsupported."
  end
	
  defmacro __using__([interval: interval]) do 
	setup(%SchedulerConfig{interval: interval})
  end
  defmacro __using__([interval: interval, max_runs: max_runs]) do
    setup(%SchedulerConfig{interval: interval,max_runs: max_runs})
  end
  
  def setup(init_config) do
    quote location: :keep do
      
	  @behaviour GenScheduler
      
      def initial_configuration do
		unquote(Macro.escape(init_config))
	  end
  
      def init(args) do
        {:ok, args}
      end
	  
	  @doc false
      def terminate(_reason, _state) do
        :ok
      end
    	
      def handle_execute(state) do
        {:ok, state}
      end
      
      defoverridable [init: 1, terminate: 2, handle_execute: 1]	  
    end
  end
  
  def execute(pid), do: GenServer.cast(pid, :execute)
    def handle_cast(:execute, config) do
        
    #check if we run the max number of runs
    if config.max_runs == 0 or config.max_runs > config.nth_run do
    
       #check if we are enabled
       case config.status do
      
         :enabled ->
          
           new_config = config
           |> run #execute scheduled function
           |> sleep #sleep interval
           
           #send loop message
           execute(self)
          
            #return state
            inc_config = Map.put(new_config, :nth_run, new_config.nth_run + 1)
			  
            {:noreply, inc_config}
            
          :disabled ->
            
            #sleep temp interval
            sleep(5000)
          
            #send loop message
            execute(self)
          
            #return state
            {:noreply, config}
            
          end
        else
      #{:stop, :normal, config}
      {:noreply, config}
    end  
  end
      
  def sleep(config) when is_map(config) do
	sleep(config.interval)
    config
  end
  def sleep(interval) do
    #TODO: add logic to only sleep for time required to get to the n+1 run from the start time
    :timer.sleep(interval)
  end
      
  def run(config) do
    result = config.module_name.handle_execute(config.scheduler_state)
		
    case result do
      {:ok, new_state} -> config = Map.put(config, :scheduler_state, new_state)
      {:stop, reason} -> {:stop, reason}
      _ -> raise "Invalid return result."
    end
		
    config
  end

end