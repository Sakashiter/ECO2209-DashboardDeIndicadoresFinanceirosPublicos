ECO12209 - Dashboard de Indicadores Financeiros Públicos 

# Eduardo Antônio Lameira dos Anjos - 2024014417 - d2024014417@unifei.edu.br
# Gabriela Portugal Rocha Lopes - 2024009471 - d2024009471@unifei.edu.br
# Felipe Scannavino Sakashita - 2024013278 - d2024013278@unifei.edu.br
# Otávio Limade Andrade - 2024003487 - d2024003487@unifei.edu.br

## 🎯 Objetivo do Projeto

Este projeto foi desenvolvido como trabalho prático para a disciplina **ECO12209 - Linguagens de Programação** no curso de **Engenharia de Computação** da **UNIFEI (Universidade Federal de Itajubá) - Campus Itabira** , sob a orientação do Prof. Walter Aoiama Nagai.

O propósito fundamental é a criação de uma aplicação funcional poliglota que integra três linguagens de programação diferentes — **Rust**, **Go** e **Dart** — para solucionar um problema real utilizando APIs abertas com dados atualizados em tempo real ou quase real. O sistema funciona como um painel analítico gerencial focado em indicadores macroeconômicos, auxiliando na transparência, agilidade e fundamentação de decisões administrativas no setor público.

---

## 🏗️ Arquitetura e Divisão por Linguagem

O ecossistema segue uma separação rigorosa de responsabilidades técnicas por camadas:

* 
**Módulo de Coleta (Rust):** Responsável pela extração periódica e assíncrona de dados brutos diretamente das APIs públicas do Banco Central e AwesomeAPI. A linguagem foi escolhida pelo alto desempenho e segurança de memória em tempo de compilação.


* 
**API Gateway e Orquestração (Go):** Atua como o servidor back-end encarregado de gerenciar as rotas, estruturar regras de cache local, controlar acessos e expor os dados tratados em formato RESTful para o cliente. Também suporta a exportação de relatórios em formato CSV.


* 
**Interface Gráfica (Dart / Flutter):** Responsável pela camada de apresentação e experiência visual do usuário. Renderiza gráficos interativos de séries temporais correspondentes aos últimos 12 meses e exibe alertas coloridos baseados em thresholds de variação crítica.


---

## 📁 Estrutura do Repositório

A organização de pastas do repositório foi padronizada conforme a seguinte árvore de diretórios:

```text
[cite_start]├── Dart/               # Aplicação Flutter para visualização e interface gráfica [cite: 509]
│   ├── lib/main.dart   # Ponto de entrada do frontend
│   └── pubspec.yaml    # Gerenciador de dependências do Dart
[cite_start]├── GO/                 # Servidor de orquestração e API REST em Go [cite: 509]
│   └── Documentação/   # Notas de especificação das rotas e endpoints
[cite_start]├── Rust/               # Módulo de ingestão e parsing de dados em Rust [cite: 508]
│   ├── src/main.rs     # Script assíncrono de coleta das APIs
│   ├── Cargo.toml      # Manifesto de configuração do Cargo
│   └── Cargo.lock      # Travamento de versões de dependências
[cite_start]├── docs/               # Documentos e apresentações do projeto (LaTeX, PDFs) [cite: 510]
[cite_start]└── .gitignore          # Arquivo de omissão de artefatos de compilação e chaves locais [cite: 192]

```

---

## 🌐 Fontes de Dados e APIs Mapeadas

O protótipo inicial realiza chamadas estáveis para capturar métricas reais das seguintes fontes governamentais gratuitas:

1. 
**Dólar Comercial (AwesomeAPI):** Endpoint público de consulta de cotações de moedas cambiais (`/json/last/USD-BRL`).


2. 
**Meta SELIC (SGS / Banco Central do Brasil):** Série temporal oficial de número **432** que monitora a taxa básica de juros determinada pelo COPOM.


3. 
**IPCA Mensal (SGS / Banco Central do Brasil):** Série temporal oficial de número **433** utilizada como o indexador oficial da inflação do país.

---

## 🚀 Como Executar o Protótipo Inicial

A inicialização e execução dos módulos locais do projeto devem respeitar a ordem lógica apresentada abaixo:

### 1. Iniciar o Coletor (Rust)

Navegue até a pasta raiz do submódulo Rust e execute as rotinas de compilação e ingestão:

```bash
cd Rust
cargo run

```

### 2. Inicializar o Servidor de API (Go)

Acesse a pasta de backend para disponibilizar os endpoints locais de orquestração:

```bash
cd GO
go run main.go

```

### 3. Executar o Frontend (Flutter/Dart)

Com o ambiente cliente ativo e um dispositivo ou emulador conectado, carregue a interface visual:

```bash
cd Dart
flutter run

```

---

## 🤖 Uso Ético de IA

O uso de ferramentas de Inteligência Artificial Generativa no escopo do projeto obedeceu estritamente aos princípios de integridade acadêmica estipulados pela universidade:

* 
**Transparência:** A IA foi utilizada de modo responsável unicamente como suporte auxiliar para a aceleração de boilerplates estruturais, sintaxe de manifestos de compilação e esquemas de configuração de ambientes.


* 
**Autonomia e Autoria:** Toda a lógica de comunicação inter-processos, o mapeamento arquitetural e o fluxo de regras de negócio foram projetados integralmente de forma original pelo grupo.



---

## 🛠️ Boas Práticas de Governança (Git)

O controle de versão e os commits no repositório utilizam critérios padronizados de engenharia de software:

* 
**Conventional Commits:** Mensagens padronizadas no formato `tipo(escopo): descrição` com verbos descritos no imperativo (ex: `feat(coleta): adiciona parsing de JSON`).


* 
**Atomicidade:** Commits frequentes contendo apenas uma única mudança lógica por modificação para blindar o histórico contra revisões massivas e mistas.


* 
**Isolamento de Arquivos (.gitignore):** Omissão obrigatória de pastas locais pesadas resultantes de builds (`/target/`, `/build/`) e credenciais privadas (`.env`).



---

## 📄 Licença

Projeto estritamente acadêmico, pedagógico e sem fins lucrativos.
