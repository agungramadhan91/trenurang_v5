import Config
import Dotenvy

source!([
  Path.absname(".env", File.cwd!()),
  System.get_env()
])

config :trenurang_engine,
  gemini_api_key: env!("GEMINI_API_KEY", :string, nil),
  openrouter_api_key: env!("OPENROUTER_API_KEY", :string, nil),
  groq_api_key: env!("GROQ_API_KEY", :string, nil)
