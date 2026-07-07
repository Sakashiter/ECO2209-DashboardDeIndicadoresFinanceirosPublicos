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
