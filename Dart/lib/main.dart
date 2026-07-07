import 'dart:convert';
import 'dart:html' as html;
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ControleIndicadores()..atualizarIndicadores(),
      child: const AplicativoDashboard(),
    ),
  );
}

enum TipoGrafico {
  ipca,
  selic,
  dolar,
}

class PontoHistorico {
  final DateTime data;
  final double valor;

  PontoHistorico({
    required this.data,
    required this.valor,
  });
}

double converterParaDouble(dynamic valor) {
  if (valor is num) {
    return valor.toDouble();
  }

  return double.parse(
    valor.toString().replaceAll(',', '.'),
  );
}

class AlertaIndicador {
  final String nivel;
  final String mensagem;

  AlertaIndicador({
    required this.nivel,
    required this.mensagem,
  });

  factory AlertaIndicador.fromJson(Map<String, dynamic> json) {
    return AlertaIndicador(
      nivel: json['nivel']?.toString() ?? 'normal',
      mensagem: json['mensagem']?.toString() ??
          'Indicador dentro do limite definido.',
    );
  }
}

class IndicadorAtual {
  final double valor;
  final DateTime data;
  final String fonte;
  final AlertaIndicador alerta;

  IndicadorAtual({
    required this.valor,
    required this.data,
    required this.fonte,
    required this.alerta,
  });

  factory IndicadorAtual.fromJson(Map<String, dynamic> json) {
    final alertaJson = json['alerta'] is Map
        ? Map<String, dynamic>.from(json['alerta'] as Map)
        : <String, dynamic>{};

    return IndicadorAtual(
      valor: converterParaDouble(json['valor']),
      data: DateTime.parse(json['data'].toString()),
      fonte: json['fonte']?.toString() ?? 'Fonte não informada',
      alerta: AlertaIndicador.fromJson(alertaJson),
    );
  }
}

class IndicadoresAtuais {
  final IndicadorAtual ipca;
  final IndicadorAtual selic;
  final IndicadorAtual dolar;

  IndicadoresAtuais({
    required this.ipca,
    required this.selic,
    required this.dolar,
  });

  factory IndicadoresAtuais.fromJson(Map<String, dynamic> json) {
    return IndicadoresAtuais(
      ipca: IndicadorAtual.fromJson(
        Map<String, dynamic>.from(json['ipca'] as Map),
      ),
      selic: IndicadorAtual.fromJson(
        Map<String, dynamic>.from(json['selic'] as Map),
      ),
      dolar: IndicadorAtual.fromJson(
        Map<String, dynamic>.from(json['dolar'] as Map),
      ),
    );
  }
}

class IndicadorEconomico {
  final String titulo;
  final String valor;
  final Color corTema;
  final IconData icone;
  final String descricao;
  final String nivelAlerta;

  IndicadorEconomico({
    required this.titulo,
    required this.valor,
    required this.corTema,
    required this.icone,
    required this.descricao,
    required this.nivelAlerta,
  });
}

Color corDoAlerta(String nivel) {
  switch (nivel.toLowerCase()) {
    case 'critico':
      return const Color(0xFFC62828);
    case 'atencao':
      return const Color(0xFFEF6C00);
    default:
      return const Color(0xFF2E7D32);
  }
}

String textoDoAlerta(String nivel) {
  switch (nivel.toLowerCase()) {
    case 'critico':
      return 'CRÍTICO';
    case 'atencao':
      return 'ATENÇÃO';
    default:
      return 'NORMAL';
  }
}

class ApiService {
  static const String baseUrl = 'http://localhost:8080/api';

  Future<IndicadoresAtuais> buscarIndicadores() async {
    final resposta = await http.get(
      Uri.parse('$baseUrl/indicadores'),
    );

    if (resposta.statusCode != 200) {
      throw Exception('Não foi possível buscar os indicadores.');
    }

    final dados = jsonDecode(resposta.body) as Map<String, dynamic>;

    return IndicadoresAtuais.fromJson(dados);
  }

  Future<List<PontoHistorico>> buscarHistorico(
    String indicador,
  ) async {
    final resposta = await http.get(
      Uri.parse('$baseUrl/historico/$indicador'),
    );

    if (resposta.statusCode != 200) {
      throw Exception('Não foi possível buscar o histórico.');
    }

    final dados = jsonDecode(resposta.body) as List<dynamic>;

    final pontos = dados.map((item) {
      final json = Map<String, dynamic>.from(item as Map);

      return PontoHistorico(
        data: DateTime.parse(json['data'].toString()),
        valor: converterParaDouble(json['valor']),
      );
    }).toList();

    pontos.sort((a, b) => a.data.compareTo(b.data));

    return pontos;
  }

  Future<void> baixarCsv() async {
    final resposta = await http.get(
      Uri.parse('$baseUrl/relatorios/csv'),
    );

    if (resposta.statusCode != 200) {
      throw Exception('Não foi possível gerar o CSV.');
    }

    final arquivo = html.Blob(
      [resposta.bodyBytes],
      'text/csv;charset=utf-8',
    );

    final url = html.Url.createObjectUrlFromBlob(arquivo);

    html.AnchorElement(href: url)
      ..setAttribute(
        'download',
        'relatorio_indicadores_financeiros.csv',
      )
      ..click();

    html.Url.revokeObjectUrl(url);
  }
}

class ControleIndicadores extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<PontoHistorico> _historicoIpca = [];
  List<PontoHistorico> _historicoSelic = [];
  List<PontoHistorico> _historicoDolar = [];

  IndicadorAtual? _ipca;
  IndicadorAtual? _selic;
  IndicadorAtual? _dolar;

  bool _carregando = false;
  TipoGrafico _tipoGrafico = TipoGrafico.ipca;
  String _mensagemStatus = 'Aguardando atualização dos dados.';

  bool get carregando => _carregando;

  String get mensagemStatus => _mensagemStatus;

  TipoGrafico get tipoGrafico => _tipoGrafico;

  bool get linhaEmDegraus => _tipoGrafico == TipoGrafico.selic;

  List<PontoHistorico> get historicoSelecionado {
    switch (_tipoGrafico) {
      case TipoGrafico.ipca:
        return _historicoIpca;
      case TipoGrafico.selic:
        return _historicoSelic;
      case TipoGrafico.dolar:
        return _historicoDolar;
    }
  }

  String get tituloGrafico {
    switch (_tipoGrafico) {
      case TipoGrafico.ipca:
        return 'Histórico do IPCA';
      case TipoGrafico.selic:
        return 'Histórico da Taxa Selic';
      case TipoGrafico.dolar:
        return 'Histórico da Cotação do Dólar';
    }
  }

  Color get corGrafico {
    switch (_tipoGrafico) {
      case TipoGrafico.ipca:
        return const Color(0xFFD2143A);
      case TipoGrafico.selic:
        return const Color(0xFFE05275);
      case TipoGrafico.dolar:
        return const Color(0xFFAD1457);
    }
  }

  String get unidadeGrafico {
    switch (_tipoGrafico) {
      case TipoGrafico.ipca:
      case TipoGrafico.selic:
        return '%';
      case TipoGrafico.dolar:
        return 'R\$';
    }
  }

  List<IndicadorEconomico> get listaIndicadores {
    return [
      _montarIndicador(
        titulo: 'IPCA',
        indicador: _ipca,
        icone: Icons.trending_up,
        moeda: false,
      ),
      _montarIndicador(
        titulo: 'Taxa Selic',
        indicador: _selic,
        icone: Icons.account_balance,
        moeda: false,
      ),
      _montarIndicador(
        titulo: 'Dólar',
        indicador: _dolar,
        icone: Icons.attach_money,
        moeda: true,
      ),
    ];
  }

  IndicadorEconomico _montarIndicador({
    required String titulo,
    required IndicadorAtual? indicador,
    required IconData icone,
    required bool moeda,
  }) {
    if (indicador == null) {
      return IndicadorEconomico(
        titulo: titulo,
        valor: 'Indisponível',
        corTema: const Color(0xFF757575),
        icone: icone,
        descricao: 'Não foi possível receber esse dado pelo servidor Go.',
        nivelAlerta: 'indisponivel',
      );
    }

    final valor = moeda
        ? 'R\$ ${indicador.valor.toStringAsFixed(2).replaceAll('.', ',')}'
        : '${indicador.valor.toStringAsFixed(2)}%';

    return IndicadorEconomico(
      titulo: titulo,
      valor: valor,
      corTema: corDoAlerta(indicador.alerta.nivel),
      icone: icone,
      descricao: '${indicador.alerta.mensagem} Fonte: ${indicador.fonte}.',
      nivelAlerta: indicador.alerta.nivel,
    );
  }

  Future<void> atualizarIndicadores() async {
    _carregando = true;
    _mensagemStatus = 'Consultando os dados pelo servidor Go...';
    notifyListeners();

    try {
      final resultados = await Future.wait([
        _apiService.buscarIndicadores(),
        _apiService.buscarHistorico('ipca'),
        _apiService.buscarHistorico('selic'),
        _apiService.buscarHistorico('dolar'),
      ]);

      final indicadores = resultados[0] as IndicadoresAtuais;

      _ipca = indicadores.ipca;
      _selic = indicadores.selic;
      _dolar = indicadores.dolar;

      _historicoIpca = resultados[1] as List<PontoHistorico>;
      _historicoSelic = resultados[2] as List<PontoHistorico>;
      _historicoDolar = resultados[3] as List<PontoHistorico>;

      _mensagemStatus = 'Dados recebidos pelo API Gateway em Go.';
    } catch (_) {
      _mensagemStatus =
          'Não foi possível acessar o servidor Go. Verifique se ele está em execução.';
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  void alterarTipoGrafico(TipoGrafico tipo) {
    _tipoGrafico = tipo;
    notifyListeners();
  }

  Future<bool> exportarRelatorioCsv() async {
    _mensagemStatus = 'Solicitando o relatório ao servidor Go...';
    notifyListeners();

    try {
      await _apiService.baixarCsv();

      _mensagemStatus = 'Arquivo CSV baixado com sucesso.';
      return true;
    } catch (_) {
      _mensagemStatus =
          'Não foi possível gerar o arquivo CSV pelo servidor Go.';
      return false;
    } finally {
      notifyListeners();
    }
  }
}

class AplicativoDashboard extends StatelessWidget {
  const AplicativoDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dashboard Financeiro Público',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE05275),
          brightness: Brightness.light,
        ),
      ),
      home: const TelaDashboard(),
    );
  }
}

class TelaDashboard extends StatelessWidget {
  const TelaDashboard({super.key});

  Future<void> _notificarExportacao(
    BuildContext context,
    ControleIndicadores provedor,
  ) async {
    final exportado = await provedor.exportarRelatorioCsv();

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          exportado
              ? 'O arquivo CSV foi gerado para download.'
              : 'Não foi possível gerar o arquivo CSV.',
        ),
        backgroundColor: exportado
            ? const Color(0xFF2E7D32)
            : const Color(0xFFC62828),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provedorDados = Provider.of<ControleIndicadores>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard de Indicadores Públicos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar indicadores',
            onPressed: provedorDados.carregando
                ? null
                : provedorDados.atualizarIndicadores,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exportar CSV',
            onPressed: () => _notificarExportacao(
              context,
              provedorDados,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: provedorDados.atualizarIndicadores,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Visão geral dos indicadores',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Dados obtidos pelo servidor em Go.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              if (provedorDados.carregando)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: provedorDados.listaIndicadores.map((indicador) {
                  return SizedBox(
                    width: 220,
                    child: CartaoIndicador(indicador: indicador),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      provedorDados.carregando
                          ? Icons.hourglass_top
                          : Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        provedorDados.mensagemStatus,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Text(
                provedorDados.tituloGrafico,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TipoGrafico>(
                value: provedorDados.tipoGrafico,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Indicador exibido no gráfico',
                ),
                items: const [
                  DropdownMenuItem(
                    value: TipoGrafico.ipca,
                    child: Text('IPCA'),
                  ),
                  DropdownMenuItem(
                    value: TipoGrafico.selic,
                    child: Text('Taxa Selic'),
                  ),
                  DropdownMenuItem(
                    value: TipoGrafico.dolar,
                    child: Text('Dólar'),
                  ),
                ],
                onChanged: (tipo) {
                  if (tipo != null) {
                    provedorDados.alterarTipoGrafico(tipo);
                  }
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 300,
                width: double.infinity,
                child: GraficoHistorico(
                  pontos: provedorDados.historicoSelecionado,
                  cor: provedorDados.corGrafico,
                  unidade: provedorDados.unidadeGrafico,
                  linhaEmDegraus: provedorDados.linhaEmDegraus,
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => _notificarExportacao(
                    context,
                    provedorDados,
                  ),
                  icon: const Icon(Icons.file_download),
                  label: const Text('Exportar Dados em CSV'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CartaoIndicador extends StatelessWidget {
  final IndicadorEconomico indicador;

  const CartaoIndicador({
    super.key,
    required this.indicador,
  });

  @override
  Widget build(BuildContext context) {
    final indisponivel = indicador.nivelAlerta == 'indisponivel';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: indicador.corTema.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: indicador.corTema.withOpacity(0.5),
          width: 1.3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            indicador.icone,
            color: indicador.corTema,
          ),
          const SizedBox(height: 10),
          Text(
            indicador.titulo,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: indicador.corTema,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            indicador.valor,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          if (!indisponivel)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: indicador.corTema,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                textoDoAlerta(indicador.nivelAlerta),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            indicador.descricao,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class GraficoHistorico extends StatelessWidget {
  final List<PontoHistorico> pontos;
  final Color cor;
  final String unidade;
  final bool linhaEmDegraus;

  const GraficoHistorico({
    super.key,
    required this.pontos,
    required this.cor,
    required this.unidade,
    required this.linhaEmDegraus,
  });

  @override
  Widget build(BuildContext context) {
    if (pontos.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFFFCCD5),
          ),
        ),
        child: const Center(
          child: Text(
            'Não há dados disponíveis para gerar o gráfico.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final valores = pontos.map((ponto) => ponto.valor).toList();

    final menorValor = valores
        .reduce((atual, proximo) => math.min(atual, proximo))
        .toDouble();

    final maiorValor = valores
        .reduce((atual, proximo) => math.max(atual, proximo))
        .toDouble();

    final diferenca = maiorValor - menorValor;
    final margem = diferenca == 0 ? 1.0 : diferenca * 0.2;
    final minY = menorValor - margem;
    final maxY = maiorValor + margem;
    final intervaloY = (maxY - minY) / 4;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 18, 18, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFCCD5),
        ),
      ),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (pontos.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          gridData: const FlGridData(
            show: true,
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(
            show: true,
            border: const Border(
              left: BorderSide(color: Colors.grey),
              bottom: BorderSide(color: Colors.grey),
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                interval: intervaloY,
                getTitlesWidget: (valor, meta) {
                  return Text(
                    unidade == 'R\$'
                        ? 'R\$ ${valor.toStringAsFixed(2)}'
                        : '${valor.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (valor, meta) {
                  final indice = valor.toInt();

                  if (indice < 0 || indice >= pontos.length) {
                    return const SizedBox();
                  }

                  if (indice != 0 &&
                      indice != pontos.length - 1 &&
                      indice.isOdd) {
                    return const SizedBox();
                  }

                  final ponto = pontos[indice];
                  final mes = ponto.data.month.toString().padLeft(2, '0');
                  final ano = ponto.data.year.toString().substring(2);

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '$mes/$ano',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (pontosTocados) {
                return pontosTocados.map((pontoTocado) {
                  final ponto = pontos[pontoTocado.spotIndex];

                  final dia = ponto.data.day.toString().padLeft(2, '0');
                  final mes = ponto.data.month.toString().padLeft(2, '0');

                  final valor = unidade == 'R\$'
                      ? 'R\$ ${ponto.valor.toStringAsFixed(2).replaceAll('.', ',')}'
                      : '${ponto.valor.toStringAsFixed(2)}%';

                  return LineTooltipItem(
                    '$dia/$mes/${ponto.data.year}\n$valor',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                pontos.length,
                (indice) => FlSpot(
                  indice.toDouble(),
                  pontos[indice].valor,
                ),
              ),
              isCurved: !linhaEmDegraus,
              isStepLineChart: linhaEmDegraus,
              color: cor,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: cor.withOpacity(0.10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}