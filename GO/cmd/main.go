package main

import (
	"encoding/csv"
	"fmt"
	"net/http"
)

type IndicadorFinanceiro struct {
	ID    int     `json:"id"`
	Tipo  string  `json:"tipo"` // ex: "SELIC", "IPCA"
	Valor float64 `json:"valor"`
	Data  string  `json:"data"`
}

var indicadoresGlobais = []IndicadorFinanceiro{
	{1, "SELIC", 10.50, "2026-07-07"},
	{2, "IPCA", 0.45, "2026-06-30"},
	{3, "Dolar", 5.42, "2026-07-07"},
}

func getIndicadoresHandler(w http.ResponseWriter, r *http.Request) {
	// Apenas para fins de teste no terminal
	fmt.Println("Requisição recebida na rota /api/indicadores")

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`[{"id": 1, "tipo": "SELIC", "valor": 10.5, "data": "2026-07-07"}]`))
}

func exportCSVHandler(w http.ResponseWriter, r *http.Request) {
	// Define os headers para forçar o download no navegador
	w.Header().Set("Content-Type", "text/csv")
	w.Header().Set("Content-Disposition", "attachment;filename=indicadores.csv")

	writer := csv.NewWriter(w)
	defer writer.Flush()

	// Escreve o cabeçalho
	writer.Write([]string{"Tipo", "Valor", "Data"})

	// Itera sobre seus dados e escreve as linhas
	// writer.Write([]string{ind.Tipo, fmt.Sprintf("%f", ind.Valor), ind.Data})
	for _, ind := range indicadoresGlobais {
		linha := []string{
			fmt.Sprintf("%d", ind.ID),
			ind.Tipo,
			fmt.Sprintf("%.2f", ind.Valor), // Formata o float para 2 casas decimais
			ind.Data,
		}
		writer.Write(linha)
	}
}
