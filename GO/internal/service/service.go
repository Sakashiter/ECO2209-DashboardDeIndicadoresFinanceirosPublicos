package service

import (
	"bytes"
	"context"
	"encoding/csv"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"

	"dashboard-financas-go/internal/cache"
	"dashboard-financas-go/internal/domain"
)

type Service struct {
	client  *http.Client
	cache   *cache.Store
	ttl     time.Duration
	rustURL string
}

func New(
	client *http.Client,
	store *cache.Store,
	ttl time.Duration,
	rustURL string,
) *Service {
	return &Service{
		client:  client,
		cache:   store,
		ttl:     ttl,
		rustURL: rustURL,
	}
}

func (s *Service) GetIndicators(
	ctx context.Context,
) (domain.IndicatorsResponse, error) {
	ipca, selic, dollar, err := s.loadAll(ctx)

	if err != nil {
		return domain.IndicatorsResponse{}, err
	}

	return domain.IndicatorsResponse{
		IPCA: makeIndicator(
			ipca,
			"Banco Central do Brasil",
			"ipca",
		),
		Selic: makeIndicator(
			selic,
			"Banco Central do Brasil",
			"selic",
		),
		Dolar: makeIndicator(
			dollar,
			"AwesomeAPI",
			"dolar",
		),
	}, nil
}

func (s *Service) GetHistory(
	ctx context.Context,
	indicator string,
) ([]domain.HistoricalPoint, error) {
	switch indicator {
	case "ipca":
		return s.getIPCA(ctx)
	case "selic":
		return s.getSelic(ctx)
	case "dolar":
		return s.getDollar(ctx)
	default:
		return nil, fmt.Errorf(
			"indicador inválido: %s",
			indicator,
		)
	}
}

func (s *Service) CSV(ctx context.Context) ([]byte, error) {
	ipca, selic, dollar, err := s.loadAll(ctx)

	if err != nil {
		return nil, err
	}

	var buffer bytes.Buffer

	buffer.Write([]byte{0xEF, 0xBB, 0xBF})

	writer := csv.NewWriter(&buffer)
	writer.Comma = ';'

	err = writer.Write([]string{
		"Indicador",
		"Data",
		"Valor",
		"Fonte",
	})

	if err != nil {
		return nil, err
	}

	writeRows := func(
		name string,
		source string,
		suffix string,
		prefix string,
		points []domain.HistoricalPoint,
	) error {
		for _, point := range points {
			value := strings.ReplaceAll(
				fmt.Sprintf("%.2f", point.Valor),
				".",
				",",
			)

			err := writer.Write([]string{
				name,
				point.Data,
				prefix + value + suffix,
				source,
			})

			if err != nil {
				return err
			}
		}

		return nil
	}

	if err := writeRows(
		"IPCA",
		"Banco Central do Brasil",
		"%",
		"",
		ipca,
	); err != nil {
		return nil, err
	}

	if err := writeRows(
		"Taxa Selic",
		"Banco Central do Brasil",
		"%",
		"",
		selic,
	); err != nil {
		return nil, err
	}

	if err := writeRows(
		"Dólar",
		"AwesomeAPI",
		"",
		"R$ ",
		dollar,
	); err != nil {
		return nil, err
	}

	writer.Flush()

	if err := writer.Error(); err != nil {
		return nil, err
	}

	return buffer.Bytes(), nil
}

func (s *Service) loadAll(
	ctx context.Context,
) (
	[]domain.HistoricalPoint,
	[]domain.HistoricalPoint,
	[]domain.HistoricalPoint,
	error,
) {
	type result struct {
		name   string
		points []domain.HistoricalPoint
		err    error
	}

	results := make(chan result, 3)

	var group sync.WaitGroup

	load := func(
		name string,
		fn func(context.Context) ([]domain.HistoricalPoint, error),
	) {
		group.Add(1)

		go func() {
			defer group.Done()

			points, err := fn(ctx)

			results <- result{
				name:   name,
				points: points,
				err:    err,
			}
		}()
	}

	load("ipca", s.getIPCA)
	load("selic", s.getSelic)
	load("dolar", s.getDollar)

	go func() {
		group.Wait()
		close(results)
	}()

	var ipca []domain.HistoricalPoint
	var selic []domain.HistoricalPoint
	var dollar []domain.HistoricalPoint
	var failures []string

	for item := range results {
		if item.err != nil {
			failures = append(failures, item.name)
			continue
		}

		switch item.name {
		case "ipca":
			ipca = item.points
		case "selic":
			selic = item.points
		case "dolar":
			dollar = item.points
		}
	}

	if len(failures) > 0 {
		return nil, nil, nil, fmt.Errorf(
			"falha ao consultar: %s",
			strings.Join(failures, ", "),
		)
	}

	return ipca, selic, dollar, nil
}

type rustDados struct {
	IPCA  []bcbRow     `json:"ipca"`
	Selic []bcbRow     `json:"selic"`
	Dolar []awesomeRow `json:"dolar"`
}

func (s *Service) fetchRustDados(ctx context.Context) (*rustDados, error) {
	if cached, ok := cache.Get[*rustDados](s.cache, "rust:dados"); ok {
		return cached, nil
	}

	request, err := http.NewRequestWithContext(
		ctx,
		http.MethodGet,
		s.rustURL+"/dados",
		nil,
	)

	if err != nil {
		return nil, err
	}

	response, err := s.client.Do(request)

	if err != nil {
		return nil, fmt.Errorf(
			"requisição ao serviço Rust: %w",
			err,
		)
	}

	defer response.Body.Close()

	if response.StatusCode != http.StatusOK {
		return nil, fmt.Errorf(
			"serviço Rust respondeu com status %d",
			response.StatusCode,
		)
	}

	body, err := io.ReadAll(
		io.LimitReader(response.Body, 4<<20),
	)

	if err != nil {
		return nil, err
	}

	var dados rustDados

	if err := json.Unmarshal(body, &dados); err != nil {
		return nil, fmt.Errorf(
			"JSON inválido do serviço Rust: %w",
			err,
		)
	}

	cache.Set(s.cache, "rust:dados", &dados, s.ttl)

	return &dados, nil
}

func (s *Service) getIPCA(
	ctx context.Context,
) ([]domain.HistoricalPoint, error) {
	if cached, ok := cache.Get[[]domain.HistoricalPoint](
		s.cache,
		"history:ipca",
	); ok {
		return cached, nil
	}

	dados, err := s.fetchRustDados(ctx)

	if err != nil {
		return nil, err
	}

	points := parseBCBRows(dados.IPCA)

	if len(points) == 0 {
		return nil, errors.New(
			"nenhum dado válido de IPCA recebido do serviço Rust",
		)
	}

	points = lastN(points, 12)

	cache.Set(s.cache, "history:ipca", points, s.ttl)

	return points, nil
}

func (s *Service) getSelic(
	ctx context.Context,
) ([]domain.HistoricalPoint, error) {
	if cached, ok := cache.Get[[]domain.HistoricalPoint](
		s.cache,
		"history:selic",
	); ok {
		return cached, nil
	}

	dados, err := s.fetchRustDados(ctx)

	if err != nil {
		return nil, err
	}

	points := parseBCBRows(dados.Selic)

	if len(points) == 0 {
		return nil, errors.New(
			"nenhum dado válido de Selic recebido do serviço Rust",
		)
	}

	points = lastValueByMonth(points)
	points = lastN(points, 12)

	cache.Set(s.cache, "history:selic", points, s.ttl)

	return points, nil
}

func (s *Service) getDollar(
	ctx context.Context,
) ([]domain.HistoricalPoint, error) {
	if cached, ok := cache.Get[[]domain.HistoricalPoint](
		s.cache,
		"history:dolar",
	); ok {
		return cached, nil
	}

	dados, err := s.fetchRustDados(ctx)

	if err != nil {
		return nil, err
	}

	points := parseAwesomeRows(dados.Dolar)

	if len(points) == 0 {
		return nil, errors.New(
			"nenhum dado válido de dólar recebido do serviço Rust",
		)
	}

	points = lastValueByMonth(points)
	points = lastN(points, 12)

	cache.Set(s.cache, "history:dolar", points, s.ttl)

	return points, nil
}

type bcbRow struct {
	Data  string `json:"data"`
	Valor string `json:"valor"`
}

type awesomeRow struct {
	Timestamp string `json:"timestamp"`
	Bid       string `json:"bid"`
}

func parseBCBRows(rows []bcbRow) []domain.HistoricalPoint {
	points := make([]domain.HistoricalPoint, 0, len(rows))

	for _, row := range rows {
		date, err := time.Parse("02/01/2006", row.Data)

		if err != nil {
			continue
		}

		value, err := strconv.ParseFloat(
			strings.ReplaceAll(row.Valor, ",", "."),
			64,
		)

		if err != nil {
			continue
		}

		points = append(points, domain.HistoricalPoint{
			Data:  date.Format("2006-01-02"),
			Valor: value,
		})
	}

	sort.Slice(points, func(i, j int) bool {
		return points[i].Data < points[j].Data
	})

	return points
}

func parseAwesomeRows(rows []awesomeRow) []domain.HistoricalPoint {
	points := make([]domain.HistoricalPoint, 0, len(rows))

	for _, row := range rows {
		timestamp, err := strconv.ParseInt(row.Timestamp, 10, 64)

		if err != nil {
			continue
		}

		value, err := strconv.ParseFloat(row.Bid, 64)

		if err != nil {
			continue
		}

		points = append(points, domain.HistoricalPoint{
			Data:  time.Unix(timestamp, 0).UTC().Format("2006-01-02"),
			Valor: value,
		})
	}

	sort.Slice(points, func(i, j int) bool {
		return points[i].Data < points[j].Data
	})

	return points
}

func lastValueByMonth(
	points []domain.HistoricalPoint,
) []domain.HistoricalPoint {
	monthly := make(
		map[string]domain.HistoricalPoint,
	)

	for _, point := range points {
		if len(point.Data) < 7 {
			continue
		}

		monthly[point.Data[:7]] = point
	}

	result := make(
		[]domain.HistoricalPoint,
		0,
		len(monthly),
	)

	for _, point := range monthly {
		result = append(result, point)
	}

	sort.Slice(result, func(i, j int) bool {
		return result[i].Data < result[j].Data
	})

	return result
}

func lastN(
	points []domain.HistoricalPoint,
	n int,
) []domain.HistoricalPoint {
	if len(points) <= n {
		return points
	}

	return points[len(points)-n:]
}

func makeIndicator(
	points []domain.HistoricalPoint,
	source string,
	kind string,
) domain.Indicator {
	last := points[len(points)-1]

	return domain.Indicator{
		Valor:  last.Valor,
		Data:   last.Data,
		Fonte:  source,
		Alerta: alertFor(kind, last.Valor),
	}
}

func alertFor(
	kind string,
	value float64,
) domain.Alert {
	switch kind {
	case "ipca":
		if value >= 1 {
			return domain.Alert{
				Nivel:    "critico",
				Mensagem: "Variação mensal do IPCA acima de 1%.",
			}
		}

		if value >= 0.5 {
			return domain.Alert{
				Nivel:    "atencao",
				Mensagem: "Variação mensal do IPCA acima de 0,5%.",
			}
		}

	case "selic":
		if value >= 14 {
			return domain.Alert{
				Nivel:    "critico",
				Mensagem: "Taxa Selic elevada.",
			}
		}

		if value >= 12 {
			return domain.Alert{
				Nivel:    "atencao",
				Mensagem: "Taxa Selic em nível alto.",
			}
		}

	case "dolar":
		if value >= 6 {
			return domain.Alert{
				Nivel:    "critico",
				Mensagem: "Dólar acima de R$ 6,00.",
			}
		}

		if value >= 5.5 {
			return domain.Alert{
				Nivel:    "atencao",
				Mensagem: "Dólar em cotação elevada.",
			}
		}
	}

	return domain.Alert{
		Nivel:    "normal",
		Mensagem: "Indicador dentro do limite definido.",
	}
}
