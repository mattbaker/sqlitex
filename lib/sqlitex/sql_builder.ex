defmodule Sqlitex.SqlBuilder do
  @moduledoc """
  This module contains functions for SQL creation. At the moment
  it is only used for `CREATE TABLE` statements.
  """
  
  # Supported table options
  defp table_opt(:temporary), do: {:temp, "TEMP"}
  defp table_opt(:temp), do: {:temp, "TEMP"}

  defp table_opt({:primary_key, cols}) when is_list(cols) do
    {:primary_key, ",PRIMARY KEY (" <> Enum.join(cols, ",") <> ")"}
  end

  defp table_opt({:primary_key, col}) when is_atom(col) do
    {:primary_key, ",PRIMARY KEY (" <> Atom.to_string(col) <> ")"}
  end

  # Catch invalid / unsupported table options
  defp table_opt(opt), do: raise "Unkown table option: #{IO.inspect(opt)}"

  # Supported column options
  defp column_opt(:primary_key), do: {:primary_key, "PRIMARY KEY"}
  defp column_opt(:not_null), do: {:not_null, "NOT NULL"}
  defp column_opt(:autoincrement), do: {:autoincrement, "AUTOINCREMENT"}

  # Catch invalid / unsupported column options
  defp column_opt(opt), do: raise "Unknown column option: #{IO.inspect(opt)}"

  # Helper function that creates a dictionary of option names
  # and their string representations
  defp get_opts_dict(opts, opt) do
    Enum.into(opts, %{}, &(opt.(&1)))
  end

  # Create the sql fragment for the column definitions from the
  # passed keyword list
  defp get_columns_block(cols) do
    Enum.reduce(cols, "", fn(col, acc) ->
      comma = if acc == "" do nil else "," end

      case col do
        # Column with name, type and constraint
        {name, {type, constraints}} ->
          col_options = get_opts_dict(constraints, &column_opt/1)
          get_opt = &(Dict.get(col_options, &1, nil))
          
          Enum.join([
            "#{acc}#{comma}", "#{name}", "#{type}",
            "#{get_opt.(:primary_key)}",
            "#{get_opt.(:not_null)}",
            "#{get_opt.(:autoincrement)}"
          ], " ")
        # Column with name and type
        {name, type} ->
          "#{acc}#{comma} #{name} #{type}"
      end
    end)
  end

  # Returns an SQL CREATE TABLE statement as a string. `name` is the name of the
  # table, and `table_opts` contains the table constraints (at the moment only
  # PRIMARY KEY is supported). `cols` is expected to be a keyword list in the
  # form of:
  #
  # column_name: :column_type, of
  # column_name: {:column_type, [column_constraints]}
  def create_table(name, table_opts, cols) do
    tbl_options = get_opts_dict(table_opts, &table_opt/1)
    get_opt = &(Dict.get(tbl_options, &1, nil))

    "CREATE #{get_opt.(:temp)} TABLE #{get_opt.(:if_not_exists)} #{name} (#{get_columns_block(cols)} #{get_opt.(:primary_key)})"
  end
end
