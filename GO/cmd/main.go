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
