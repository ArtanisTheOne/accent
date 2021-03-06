defmodule Langue.Utils.Placeholders do
  def parse(entries, regex) when is_list(entries), do: Enum.map(entries, &parse(&1, regex))

  def parse(entry, :not_supported), do: entry

  def parse(entry = %Langue.Entry{}, regex) do
    placeholders =
      regex
      |> Regex.scan(entry.value, capture: :first)
      |> List.flatten()

    %{entry | placeholders: placeholders}
  end
end
