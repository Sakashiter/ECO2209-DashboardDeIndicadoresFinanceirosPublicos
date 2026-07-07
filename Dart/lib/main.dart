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

class IndicadorEconomico {
  final String titulo;
  final String valor;
  final Color corTema;
  final IconData icone;
  final String descricao;

  IndicadorEconomico({
    required this.titulo,
    required this.valor,
    required this.corTema,
    required this.icone,
    required this.descricao,
  });
}

class ApiService {
  static const String urlIpca =
      'https://api.bcb.gov.br/dados/serie/bcdata.sgs.433/dados/ultimos/12?formato=json';

  static String criarUrlSelic() {
    final hoje = DateTime.now();
    final inicio = DateTime(hoje.year - 2, hoje.month, hoje.day);

    String formatarData(DateTime data) {
      final dia = data.day.toString().padLeft(2, '0');
      final mes = data.month.toString().padLeft(2, '0');
      return '$dia/$mes/${data.year}';
    }

    return 'https://api.bcb.gov.br/dados/serie/bcdata.sgs.1178/dados?formato=json&dataInicial=${formatarData(inicio)}&dataFinal=${formatarData(hoje)}';
  }

  static const String urlDolar =
      'https://economia.awesomeapi.com.br/json/daily/USD-BRL/12';

  Future<List<PontoHistorico>> buscarHistoricoBcb(
    String url, {
    bool usarUltimoValorDoMes = false,
  }) async {
    final resposta = await http.get(Uri.parse(url));

    if (resposta.statusCode != 200) {
      throw Exception('Não foi possível obter os dados do Banco Central.');
    }

    final dados = jsonDecode(resposta.body) as List<dynamic>;

    final resultado = dados.map((item) {
      final partesData = item['data'].toString().split('/');

      return PontoHistorico(
        data: DateTime(
          int.parse(partesData[2]),
          int.parse(partesData[1]),
          int.parse(partesData[0]),
        ),
        valor: double.parse(
          item['valor'].toString().replaceAll(',', '.'),
        ),
      );
    }).toList();

    resultado.sort((a, b) => a.data.compareTo(b.data));

    if (!usarUltimoValorDoMes) {
      return resultado;
    }

    final valoresMensais = <String, PontoHistorico>{};

    for (final ponto in resultado) {
      final chave = '${ponto.data.year}-${ponto.data.month}';
      valoresMensais[chave] = ponto;
    }

    return valoresMensais.values.toList();
  }

  Future<List<PontoHistorico>> buscarHistoricoDolar() async {
    final resposta = await http.get(Uri.parse(urlDolar));

    if (resposta.statusCode != 200) {
      throw Exception('Não foi possível obter os dados da AwesomeAPI.');
    }

    final dados = jsonDecode(resposta.body) as List<dynamic>;

    final resultado = dados.map((item) {
      final timestamp = int.parse(item['timestamp'].toString());

      return PontoHistorico(
        data: DateTime.fromMillisecondsSinceEpoch(timestamp * 1000),
        valor: double.parse(item['bid'].toString()),
      );
    }).toList();

    resultado.sort((a, b) => a.data.compareTo(b.data));

    return resultado;
  }
}

class ControleIndicadores extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<PontoHistorico> _historicoIpca = [];
  List<PontoHistorico> _historicoSelic = [];
  List<PontoHistorico> _historicoDolar = [];

  bool _carregando = false;
  TipoGrafico _tipoGrafico = TipoGrafico.ipca;
  String _mensagemStatus = 'Aguardando atualização dos dados.';

  bool get carregando => _carregando;

  String get mensagemStatus => _mensagemStatus;

  TipoGrafico get tipoGrafico => _tipoGrafico;

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
    final ipca = _historicoIpca.isNotEmpty ? _historicoIpca.last.valor : null;
    final selic =
        _historicoSelic.isNotEmpty ? _historicoSelic.last.valor : null;
    final dolar =
        _historicoDolar.isNotEmpty ? _historicoDolar.last.valor : null;

    return [
      IndicadorEconomico(
        titulo: 'IPCA',
        valor: ipca == null ? 'Indisponível' : '${ipca.toStringAsFixed(2)}%',
        corTema: const Color(0xFFD2143A),
        icone: Icons.trending_up,
        descricao: ipca == null
            ? 'Dados não recebidos da API.'
            : 'Fonte: Banco Central.',
      ),
      IndicadorEconomico(
        titulo: 'Taxa Selic',
        valor:
            selic == null ? 'Indisponível' : '${selic.toStringAsFixed(2)}%',
        corTema: const Color(0xFFE05275),
        icone: Icons.account_balance,
        descricao: selic == null
            ? 'Dados não recebidos da API.'
            : 'Fonte: Banco Central.',
      ),
      IndicadorEconomico(
        titulo: 'Dólar',
        valor: dolar == null
            ? 'Indisponível'
            : 'R\$ ${dolar.toStringAsFixed(2).replaceAll('.', ',')}',
        corTema: const Color(0xFFAD1457),
        icone: Icons.attach_money,
        descricao: dolar == null
            ? 'Dados não recebidos da API.'
            : 'Fonte: AwesomeAPI.',
      ),
    ];
  }

  Future<void> atualizarIndicadores() async {
    _carregando = true;
    _mensagemStatus = 'Consultando APIs públicas...';
    notifyListeners();

    final erros = <String>[];

    try {
      _historicoIpca = await _apiService.buscarHistoricoBcb(ApiService.urlIpca);
    } catch (_) {
      _historicoIpca = [];
      erros.add('IPCA');
    }

    try {
      _historicoSelic = await _apiService.buscarHistoricoBcb(
        ApiService.criarUrlSelic(),
        usarUltimoValorDoMes: true,
      );
    } catch (_) {
      _historicoSelic = [];
      erros.add('Selic');
    }

    try {
      _historicoDolar = await _apiService.buscarHistoricoDolar();
    } catch (_) {
      _historicoDolar = [];
      erros.add('Dólar');
    }

    _carregando = false;

    if (erros.isEmpty) {
      _mensagemStatus = 'Dados atualizados diretamente pelas APIs.';
    } else if (erros.length == 3) {
      _mensagemStatus = 'Não foi possível acessar as APIs neste momento.';
    } else {
      _mensagemStatus =
          'Não foi possível atualizar: ${erros.join(', ')}.';
    }

    notifyListeners();
  }

  void alterarTipoGrafico(TipoGrafico tipo) {
    _tipoGrafico = tipo;
    notifyListeners();
  }

  void exportarRelatorioCsv() {
    final linhas = <String>[
      'Indicador;Data;Valor',
    ];

    for (final ponto in _historicoIpca) {
      linhas.add(
        'IPCA;${_formatarDataCsv(ponto.data)};${ponto.valor.toStringAsFixed(2)}%',
      );
    }

    for (final ponto in _historicoSelic) {
      linhas.add(
        'Taxa Selic;${_formatarDataCsv(ponto.data)};${ponto.valor.toStringAsFixed(2)}%',
      );
    }

    for (final ponto in _historicoDolar) {
      linhas.add(
        'Dólar;${_formatarDataCsv(ponto.data)};R\$ ${ponto.valor.toStringAsFixed(2).replaceAll('.', ',')}',
      );
    }

    if (linhas.length == 1) {
      _mensagemStatus = 'Não há dados de API disponíveis para exportação.';
      notifyListeners();
      return;
    }

    final conteudo = '\uFEFF${linhas.join('\n')}';
    final arquivo = html.Blob(
      [conteudo],
      'text/csv;charset=utf-8',
    );

    final url = html.Url.createObjectUrlFromBlob(arquivo);

    html.AnchorElement(href: url)
      ..setAttribute(
        'download',
        'indicadores_financeiros_${DateTime.now().millisecondsSinceEpoch}.csv',
      )
      ..click();

    html.Url.revokeObjectUrl(url);

    _mensagemStatus = 'Arquivo CSV baixado com sucesso.';
    notifyListeners();
  }

  String _formatarDataCsv(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
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

  void _notificarExportacao(
    BuildContext context,
    ControleIndicadores provedor,
  ) {
    provedor.exportarRelatorioCsv();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('O arquivo CSV foi gerado para download.'),
        backgroundColor: Color(0xFFD2143A),
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
                'Dados obtidos diretamente por APIs públicas.',
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
                    width: 175,
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
                  linhaEmDegraus:
                      provedorDados.tipoGrafico == TipoGrafico.selic,
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
                  label: const Text(
                    'Exportar Dados em CSV',
                  ),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: indicador.corTema.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: indicador.corTema.withOpacity(0.4),
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
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
    final menorValor = valores.reduce(math.min);
    final maiorValor = valores.reduce(math.max);
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
                reservedSize: 44,
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
                  final dia = ponto.data.day.toString().padLeft(2, '0');
                  final mes = ponto.data.month.toString().padLeft(2, '0');

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '$dia/$mes',
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