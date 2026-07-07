import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ControleIndicadores(),
      child: const AplicativoDashboard(),
    ),
  );
}

// Modelo de dados de cada indicador econômico
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

// Provider responsável pelo controle dos indicadores
class ControleIndicadores extends ChangeNotifier {
  final List<IndicadorEconomico> _dadosIndicadores = [
    IndicadorEconomico(
      titulo: 'IPCA',
      valor: '4,5%',
      corTema: Colors.pink.shade700,
      icone: Icons.trending_up,
      descricao: 'Índice oficial da inflação.',
    ),
    IndicadorEconomico(
      titulo: 'Taxa SELIC',
      valor: '10,5%',
      corTema: const Color(0xFFD2143A),
      icone: Icons.account_balance,
      descricao: 'Taxa básica de juros.',
    ),
    IndicadorEconomico(
      titulo: 'Dólar',
      valor: 'R\$ 5,25',
      corTema: const Color(0xFFE05275),
      icone: Icons.attach_money,
      descricao: 'Cotação comercial simulada.',
    ),
  ];

  String _mensagemStatus = 'Dados atualizados com informações simuladas.';
  bool _exportando = false;

  List<IndicadorEconomico> get listaIndicadores => _dadosIndicadores;

  String get mensagemStatus => _mensagemStatus;

  bool get exportando => _exportando;

  void exportarRelatorioCSV() {
    _exportando = true;
    _mensagemStatus = 'Gerando relatório mensal em CSV...';
    notifyListeners();

    Future.delayed(const Duration(seconds: 1), () {
      _exportando = false;
      _mensagemStatus = 'Relatório CSV exportado com sucesso!';
      notifyListeners();
    });
  }

  void atualizarDados() {
    _mensagemStatus = 'Indicadores atualizados com sucesso!';
    notifyListeners();
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

  void _notificarExportacao(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exportação para CSV concluída com sucesso!'),
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
            onPressed: provedorDados.atualizarDados,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exportar CSV',
            onPressed: () {
              provedorDados.exportarRelatorioCSV();
              _notificarExportacao(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
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
              'Análise econômica dos últimos 12 meses',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: provedorDados.listaIndicadores
                  .map(
                    (item) => SizedBox(
                      width: 170,
                      child: CartaoIndicador(indicador: item),
                    ),
                  )
                  .toList(),
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
                    provedorDados.exportando
                        ? Icons.hourglass_top
                        : Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      provedorDados.mensagemStatus,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Histórico de Variação',
              style: TextStyle
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFCCD5),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.show_chart,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Gráfico Histórico Interativo',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Área preparada para integração futura com a API.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
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
                onPressed: provedorDados.exportando
                    ? null
                    : () {
                        provedorDados.exportarRelatorioCSV();
                        _notificarExportacao(context);
                      },
                icon: provedorDados.exportando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.file_download),
                label: Text(
                  provedorDados.exportando
                      ? 'Exportando relatório...'
                      : 'Exportar Relatório Mensal (CSV)',
                ),
              ),
            ),
          ],
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
        color: indicador.corTema.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: indicador.corTema.withValues(alpha: 0.4),
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
          const SizedBox(height: 5),
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