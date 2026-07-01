defmodule Trenurang.Matching.DimensionProfile do
  @moduledoc """
  Struct representasi 9-dimensi yang menentukan topologi matching sebuah Intent.
  Dibuat dari Intent.dimension_profile (map/snapshot) sebelum masuk Router & Scoring.

  Tiga dimensi pertama (cardinality, divisibility, resolution_mode) adalah
  penentu topologi algoritma -- dipakai Router.select_pattern/1.
  Enam dimensi sisanya adalah pipeline modifier -- dipakai Router.pipeline_modifiers/1.
  """

  @enforce_keys [
    :cardinality,
    :divisibility,
    :resolution_mode,
    :temporality,
    :spatiality,
    :exchange_form,
    :visibility,
    :trust_level,
    :urgency
  ]

  defstruct [
    :cardinality,
    :divisibility,
    :resolution_mode,
    :temporality,
    :spatiality,
    :exchange_form,
    :visibility,
    :trust_level,
    :urgency
  ]

  @type cardinality :: :one_to_one | :many_to_one | :many_to_many
  @type divisibility :: :divisible | :indivisible
  @type resolution_mode :: :fuzzy_score | :exact_preference | :negotiated | :price_discovery
  @type temporality :: :one_time | :recurring | :deadline_bound | :flexible
  @type spatiality :: :location_bound | :remote
  @type exchange_form :: :monetary | :barter | :donation | :volunteer
  @type visibility :: :public | :private | :anonymous_until_match
  @type trust_level :: :open | :verified_required
  @type urgency :: :normal | :urgent | :emergency

  @type t :: %__MODULE__{
    cardinality: cardinality(),
    divisibility: divisibility(),
    resolution_mode: resolution_mode(),
    temporality: temporality(),
    spatiality: spatiality(),
    exchange_form: exchange_form(),
    visibility: visibility(),
    trust_level: trust_level(),
    urgency: urgency()
  }
end
