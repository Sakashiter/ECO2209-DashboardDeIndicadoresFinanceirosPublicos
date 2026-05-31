use serde:: Deserialize; //transforma JSON em struct

#[derive(Debug, Deserialize)]//Debug permite mostrar no terminal
struct Registro{
    data: String,//recebe valores da API e transforma
    valor: String,//recebe valores da API e transforma
}
struct Moeda{
    
}
#[tokio::main]//permite usar async na main
async fn main() -> Result<(), Box<dyn std::error::Error>>{//async para acessar url
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
    Ok(())
}
