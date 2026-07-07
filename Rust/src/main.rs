use serde::{Deserialize, Serialize}; // transforma JSON em struct
use std::env;
use std::fs;

#[derive(Debug, Deserialize, Serialize)]
struct Registro {
    data: String,
    valor: String,
}

#[derive(Debug, Deserialize, Serialize)]
struct Moeda {
    code: String,
    codein: String,
    name: String,
    bid: String,
    ask: String,
    create_date: String,
}

#[derive(Debug, Deserialize, Serialize)]
struct RespostaMoeda {
    #[serde(rename = "USDBRL")]
    usdbrl: Moeda,

    #[serde(rename = "EURBRL")]
    eurbrl: Moeda,

    #[serde(rename = "EURUSD")]
    eurusd: Moeda,
}

#[derive(Debug, Serialize)]
struct DadosFinanceiros {
    ipca: Vec<Registro>,
    selic: Vec<Registro>,
    moedas: RespostaMoeda,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    dotenvy::dotenv().ok();

    let api_key = env::var("Awesome_API_Key")?;

    let url_ipca = "https://api.bcb.gov.br/dados/serie/bcdata.sgs.433/dados/ultimos/12?formato=json";
    let resposta_ipca = reqwest::get(url_ipca).await?;
    let dados_ipca = resposta_ipca.json::<Vec<Registro>>().await?;

    for item in &dados_ipca {
        println!("IPCA Data: {} | Valor: {}", item.data, item.valor);
    }

    let url_selic = "https://api.bcb.gov.br/dados/serie/bcdata.sgs.432/dados/ultimos/12?formato=json";
    let resposta_selic = reqwest::get(url_selic).await?;
    let dados_selic = resposta_selic.json::<Vec<Registro>>().await?;

    for item in &dados_selic {
        println!("Selic Data: {} | Valor: {}", item.data, item.valor);
    }

    let url_moedas = format!(
        "https://economia.awesomeapi.com.br/json/last/USD-BRL,EUR-BRL,EUR-USD?token={}",
        api_key
    );

    let resposta_moedas = reqwest::get(&url_moedas).await?;
    let dados_moeda = resposta_moedas.json::<RespostaMoeda>().await?;

    println!(
        "Moeda: {}/{} | Nome: {} | Compra: {} | Venda: {} | Atualizado em: {}",
        dados_moeda.usdbrl.code,
        dados_moeda.usdbrl.codein,
        dados_moeda.usdbrl.name,
        dados_moeda.usdbrl.bid,
        dados_moeda.usdbrl.ask,
        dados_moeda.usdbrl.create_date
    );

    println!(
        "Moeda: {}/{} | Nome: {} | Compra: {} | Venda: {} | Atualizado em: {}",
        dados_moeda.eurbrl.code,
        dados_moeda.eurbrl.codein,
        dados_moeda.eurbrl.name,
        dados_moeda.eurbrl.bid,
        dados_moeda.eurbrl.ask,
        dados_moeda.eurbrl.create_date
    );

    println!(
        "Moeda: {}/{} | Nome: {} | Compra: {} | Venda: {} | Atualizado em: {}",
        dados_moeda.eurusd.code,
        dados_moeda.eurusd.codein,
        dados_moeda.eurusd.name,
        dados_moeda.eurusd.bid,
        dados_moeda.eurusd.ask,
        dados_moeda.eurusd.create_date
    );

    let dados_financeiros = DadosFinanceiros {
        ipca: dados_ipca,
        selic: dados_selic,
        moedas: dados_moeda,
    };

    let json = serde_json::to_string_pretty(&dados_financeiros)?;

    fs::write("dados.json", json)?;

    println!("Arquivo dados.json gerado com sucesso!");

    Ok(())
}