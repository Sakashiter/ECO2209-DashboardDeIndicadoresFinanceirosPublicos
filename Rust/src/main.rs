use serde::Deserialize; //transforma JSON em struct
use std::env;

#[derive(Debug, Deserialize)]//Debug permite mostrar no terminal
struct Registro{
    data: String,//recebe valores da API e transforma
    valor: String,//recebe valores da API e transforma
}
#[derive(Debug, Deserialize)]
struct Moeda{
    code: String,
    codein: String,
    name: String,
    bid: String,
    ask: String,
    create_date: String,
}
#[derive(Debug, Deserialize)]
struct RespostaMoeda{
    #[serde(rename = "USDBRL")]
    usdbrl: Moeda,
}
#[tokio::main]//permite usar async na main
async fn main() -> Result<(), Box<dyn std::error::Error>>{//async para acessar url
    dotenvy::dotenv().ok();

    let api_key = env::var("Awesome_API_Key")?;

    let url = "https://api.bcb.gov.br/dados/serie/bcdata.sgs.433/dados/ultimos/12?formato=json"; //busca os ultimos 12 valores IPCA
    let resposta = reqwest::get(url).await?;//pede os valores da url, await= espera, ?=encerra em caso de erro
    let dados = resposta.json::<Vec<Registro>>().await?;//vec cria lista registros, json converte em json

        for item in dados{
            println!("IPCA Data: {} | Valor: {}", item.data, item.valor)
        }

    let url = "https://api.bcb.gov.br/dados/serie/bcdata.sgs.432/dados/ultimos/12?formato=json"; //busca os 12 ultimos valores Selic
    let resposta = reqwest:: get(url).await?;
    let dados = resposta.json::<Vec<Registro>>().await?;

        for item in dados{
            println!("Selic Data: {} | Valor: {}", item.data, item.valor)
        }
    
    
    let url = format!(
        "https://economia.awesomeapi.com.br/json/last/USD-BRL?token={}", api_key
    );
    let resposta = reqwest::get(&url).await?;
    let dados_moeda = resposta.json::<RespostaMoeda>().await?;

    println!(
        "Moeda: {}/{} | Nome: {} | Compra: {} | Venda: {} | Atualizado em: {}",
        dados_moeda.usdbrl.code,
        dados_moeda.usdbrl.codein,
        dados_moeda.usdbrl.name,
        dados_moeda.usdbrl.bid,
        dados_moeda.usdbrl.ask,
        dados_moeda.usdbrl.create_date
    );
    Ok(())
}
