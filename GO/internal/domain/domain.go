package domain

type HistoricalPoint struct {
	Data  string  `json:"data"`
	Valor float64 `json:"valor"`
}

type Alert struct {
	Nivel    string `json:"nivel"`
	Mensagem string `json:"mensagem"`
}

type Indicator struct {
	Valor  float64 `json:"valor"`
	Data   string  `json:"data"`
	Fonte  string  `json:"fonte"`
	Alerta Alert   `json:"alerta"`
}

type IndicatorsResponse struct {
	IPCA  Indicator `json:"ipca"`
	Selic Indicator `json:"selic"`
	Dolar Indicator `json:"dolar"`
}
