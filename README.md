GenScheduler
============

** TODO: Complete description **

Basic usage

    defmodule TestScheduler do
      use GenScheduler, interval: 1000, max_runs: 3
    
      def start_link, do: GenScheduler.start_link(__MODULE__, 1)
    
      def handle_execute(state) do
        IO.puts("Hello World #{state}")
        {:ok, state+1}
      end
    end
	
Prints:
    
	Hello World 1
    Hello World 2
    Hello World 3
	
Supervisable Usage

    defmodule TestScheduler do
      use GenScheduler, interval: 1000, max_runs: 3
      
      def start_link do
        GenScheduler.start_link(__MODULE__,{})
      end
      
      def init(_args) do
        #do something to read initial state
        {:ok, 1}
      end
      
      def terminate(_reason, _state) do
        #do something to stash initial state
        {:ok, 1}
      end
      
      def handle_execute(state) do
      	IO.puts("Hello World #{state}")
      	{:ok, state+1}
      end
    end

Prints:
    
	Hello World 1
    Hello World 2
    Hello World 3