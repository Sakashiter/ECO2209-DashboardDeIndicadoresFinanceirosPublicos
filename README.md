# 📊 Dashboard de Indicadores Financeiros Públicos

Este repositório contém o código-fonte do projeto prático (Tema 5) da disciplina **ECO12209 - Linguagens de Programação** da Universidade Federal de Itajubá (UNIFEI - Campus Itabira).

O objetivo central do sistema é fornecer uma ferramenta consolidada para o acompanhamento ágil de índices econômicos críticos (como IPCA, Selic e Câmbio), auxiliando a tomada de decisão técnica na gestão pública e promovendo a transparência por meio de dados abertos.

---

## 🏗️ Arquitetura Poliglota

O projeto foi desenvolvido sob uma arquitetura de serviços descentralizados, explorando três paradigmas distintos e complementares para extrair o máximo de desempenho de cada tecnologia:

* **Módulo de Coleta (Rust):** Responsável pelo "trabalho pesado" de consumo de APIs externas. Utiliza rotinas assíncronas (`reqwest`, `tokio`) para buscar variações cambiais e indexadores em tempo real, garantindo velocidade, tolerância a falhas e segurança de memória.
* **Servidor e API RESTful (Go):** Atua como a camada central de orquestração. Expõe rotas para a aplicação cliente, processa requisições em alta concorrência (usando *goroutines*) e fornece os dados consolidados em formato JSON.
* **Interface Gráfica (Dart/Flutter):** Focado na experiência do usuário (Frontend). Apresenta um painel visual responsivo e dinâmico, exibindo gráficos de variação temporal e painéis de métricas atualizados via requisições HTTP à API Go.

---

## 📡 Fontes de Dados (APIs Públicas)

O sistema consome dados verídicos em tempo real através dos seguintes *endpoints*:

| Indicador | Provedor / API | Justificativa |
| :--- | :--- | :--- |
| **Dólar (USD-BRL)** | AwesomeAPI | Métrica global crítica para transações e importações. |
| **Taxa Selic** | SGS / Banco Central | Principal instrumento de controle inflacionário. |
| **IPCA Mensal** | SGS / Banco Central | Indexador essencial para contratos públicos e de mercado. |

---

## 📁 Estrutura do Repositório

O código está organizado em domínios isolados para facilitar a manutenção:

* `/Rust/`: Aplicação de coleta de dados e manifestos Cargo.
* `/GO/`: Lógica de roteamento web e serviços REST.
* `/Dart/`: Componentes visuais, controle de estado do aplicativo Flutter e configurações do servidor web (Nginx).

---

## 🐳 Como Executar o Projeto

Todo o ecossistema do projeto (Rust, Go e Dart) foi inteiramente conteinerizado utilizando **Docker**. Isso garante que o ambiente de execução seja idêntico para qualquer desenvolvedor ou servidor, dispensando a instalação local de compiladores ou SDKs.

**Pré-requisitos:**
* [Docker](https://docs.docker.com/get-docker/) e [Docker Compose](https://docs.docker.com/compose/install/) instalados na sua máquina.

**Passo a passo:**

1. Clone este repositório para sua máquina local.
2. Navegue até a raiz do projeto (onde está localizado o arquivo `docker-compose.yml`).
3. Suba todos os serviços executando o comando abaixo:
   
   ```bash
   docker compose up -d --build
   
4. Aguarde a construção das imagens e a inicialização dos containers.
5. Abra o seu navegador e acesse:
**[http://localhost:80](https://www.google.com/search?q=http://localhost:80)**

---

## 👥 Equipe Discente

* Eduardo Antônio Lameira dos Anjos
* Felipe Scannavino Sakashita
* Gabriela Portugal Rocha Lopes
* Otávio Lima de Andrade

**Docente responsável:** Prof. Walter Aoiama Nagai
