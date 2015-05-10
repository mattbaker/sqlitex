defmodule Sqlitex.Server do
  use GenServer

  def start_link(db_path) do
    GenServer.start_link(__MODULE__, db_path)
  end

  ## GenServer callbacks

  def init(db_path) do
    case Sqlitex.open(db_path) do
      {:ok, db} -> {:ok, db}
      {:error, reason} -> {:stop, reason}
    end
  end

  def handle_call({:exec, sql}, _from, db) do
    result = Sqlitex.exec(db, sql)
    {:reply, result, db}
  end

  def handle_call({:query, sql, opts}, _from, db) do
    rows = Sqlitex.query(db, sql, opts)
    {:reply, rows, db}
  end

  def handle_call({:create_table, name, cols}, _from, db) do
    result = Sqlitex.create_table(db, name, cols)
    {:reply, result, db}
  end
  
  def handle_cast(:stop, db) do
    {:stop, :normal, db}
  end

  def terminate(_reason, db) do
    Sqlitex.close(db)
    :ok
  end

  ## Public API

  def exec(pid, sql) do
    GenServer.call(pid, {:exec, sql})
  end

  def query(pid, sql, opts \\ []) do
    GenServer.call(pid, {:query, sql, opts})
  end

  def create_table(pid, name, cols) do
    GenServer.call(pid, {:create_table, name, cols})
  end

  def stop(pid) do
    GenServer.cast(pid, :stop)
  end
end
