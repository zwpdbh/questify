defmodule Questify.Embeddings do
  def embed(text, opts \\ []) when is_binary(text) do
    embedding_url = Application.get_env(:questify, :doubao)[:embedding_url]
    embedding_model = Application.get_env(:questify, :doubao)[:embedding_model]
    api_key = Application.get_env(:questify, :doubao)[:api_key]

    response =
      HTTPoison.post(
        embedding_url,
        Jason.encode!(%{
          input: text,
          model: Keyword.get(opts, :model, embedding_model)
        }),
        [
          {"Content-Type", "application/json"},
          {"Authorization", "Bearer #{api_key}"}
        ]
      )

    case response do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok,
         %{
           text: text,
           embedding:
             body
             |> Jason.decode!()
             |> Map.get("data")
             |> List.first()
             |> Map.get("embedding")
         }}

      {:ok, %HTTPoison.Response{status_code: _status_code}} ->
        {:error, :bad_request}

      {:error, error} ->
        case error do
          %HTTPoison.Error{reason: :checkout_timeout, id: nil} ->
            {:error, :checkout_timeout}

          _ ->
            {:error, error}
        end
    end
  end

  def embed!(text, opts \\ []) when is_binary(text) do
    {:ok, %{embedding: embedding}} = embed(text, opts)
    embedding
  end
end
