use axum::{extract::State, http::StatusCode, routing::get, Json, Router};
use chrono::Local;
use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::{env, sync::Arc, time::Duration};

#[derive(Debug, Deserialize, Serialize, Clone)]
struct BcbRow {
    data: String,
    valor: String,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
struct AwesomeRow {
    timestamp: String,
    bid: String,
}

#[derive(Debug, Serialize)]
struct DadosFinanceiros {
    ipca: Vec<BcbRow>,
    selic: Vec<BcbRow>,
    dolar: Vec<AwesomeRow>,
}

struct AppState {
    client: Client,
    api_key: Option<String>,
}

async fn health() -> Json<serde_json::Value> {
    Json(serde_json::json!({
        "status": "ok",
        "service": "rust-fetcher"
    }))
}

async fn get_dados(
    State(state): State<Arc<AppState>>,
) -> Result<Json<DadosFinanceiros>, (StatusCode, String)> {
    let today = Local::now();
    let two_years_ago = today - chrono::Duration::days(730);
    let selic_url = format!(
        "https://api.bcb.gov.br/dados/serie/bcdata.sgs.1178/dados?formato=json&dataInicial={}&dataFinal={}",
        two_years_ago.format("%d/%m/%Y"),
        today.format("%d/%m/%Y"),
    );

    let dolar_url = match &state.api_key {
        Some(key) => format!(
            "https://economia.awesomeapi.com.br/json/daily/USD-BRL/360?token={}",
            key
        ),
        None => "https://economia.awesomeapi.com.br/json/daily/USD-BRL/360".to_string(),
    };

    let (ipca, selic, dolar) = tokio::try_join!(
        fetch_bcb(
            &state.client,
            "https://api.bcb.gov.br/dados/serie/bcdata.sgs.433/dados/ultimos/12?formato=json",
        ),
        fetch_bcb(&state.client, &selic_url),
        fetch_awesome(&state.client, &dolar_url),
    )
    .map_err(|e| (StatusCode::BAD_GATEWAY, e.to_string()))?;

    Ok(Json(DadosFinanceiros { ipca, selic, dolar }))
}

async fn fetch_bcb(client: &Client, url: &str) -> Result<Vec<BcbRow>, reqwest::Error> {
    client.get(url).send().await?.json::<Vec<BcbRow>>().await
}

async fn fetch_awesome(client: &Client, url: &str) -> Result<Vec<AwesomeRow>, reqwest::Error> {
    client.get(url).send().await?.json::<Vec<AwesomeRow>>().await
}

#[tokio::main]
async fn main() {
    dotenvy::dotenv().ok();

    let port = env::var("PORT").unwrap_or_else(|_| "3000".to_string());

    let api_key = env::var("Awesome_API_Key").ok();

    let state = Arc::new(AppState {
        client: Client::builder()
            .timeout(Duration::from_secs(30))
            .build()
            .unwrap(),
        api_key,
    });

    let app = Router::new()
        .route("/health", get(health))
        .route("/dados", get(get_dados))
        .with_state(state);

    let addr = format!("0.0.0.0:{}", port);
    println!("Rust fetcher escutando em {}", addr);

    let listener = tokio::net::TcpListener::bind(&addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
