import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


//iniciando
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ControleIndicadores(),
      builder: (context, child) => const AplicativoDashboard(),
    ),
  );
}

//Modelo (ficha em branco)

class IndicadorEconomico {
  final String titulo;
  final String valor;
  final Color corTema;

  IndicadorEconomico({
    required this.titulo, 
    required this.valor, 
    required this.corTema,
  });
}

//Provider e Observer

class ControleIndicadores extends ChangeNotifier {
  // Lista de dados simulados com paleta de cores
  final List<IndicadorEconomico> _dadosIndicadores = [
    IndicadorEconomico(titulo: 'IPCA (Inflação)', valor: '4,5%', corTema: Colors.pink.shade700),
    IndicadorEconomico(titulo: 'Taxa SELIC', valor: '10,5%', corTema: const Color(0xFFD2143A)), // Rosa Escuro / Carmim
    IndicadorEconomico(titulo: 'Dólar (Câmbio)', valor: 'R\$ 5,25', corTema: const Color(0xFFE05275)), // Rosa Médio
  ];

  //Getter (protege o encapsulamento da original)
  List<IndicadorEconomico> get listaIndicadores => _dadosIndicadores; //porta trancada, ninguém de fora pode alterar o valor

  //Método simulado (Vou implementar o http para a api)
  void exportarRelatorioCSV() {
    notifyListeners();
  }
}


// Iniciação da interface (escolha de cor(rosa))

class AplicativoDashboard extends StatelessWidget {
  const AplicativoDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE05275),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const TelaDashboard(),
    );
  }
}

// Tela principal

class TelaDashboard extends StatelessWidget {
  const TelaDashboard({super.key});

  // Função que mostra o feedback visual
  void _notificarExportacao(BuildContext contexto) {
    ScaffoldMessenger.of(contexto).showSnackBar(
      const SnackBar(
        content: Text(' Bars Exportação para CSV concluída com sucesso!'), 
        backgroundColor: Color(0xFFD2143A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Consumindo o estado global através do Provider (Injeção de Dependência)
    final provedorDados = Provider.of<ControleIndicadores>(context); //tela não cria os dados, ela só "pede emprestado"

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard de Indicadores Públicos', 
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        // Colocar cor rosa
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exportar CSV',
            onPressed: () => _notificarExportacao(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bem-vinda, Mariana', 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Análise econômica dos últimos 12 meses', 
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            
            // Renderização dinâmica (map) 
            Row(
              children: provedorDados.listaIndicadores
                  .map<Widget>((item) => CartaoIndicador(indicador: item)) 
                  .toList(),
            ),
//pega a sua lista do estoque e lê item por item            
            const SizedBox(height: 30),
            const Text(
              'Histórico de Variação', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            
            //onde o gráfico real vai ficar quando o sistema estiver pronto
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F3), 
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFCCD5)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.show_chart, size: 64, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 8),
                    Text(
                      'Gráfico Histórico Interativo', 
                      style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                    ),
                    const Text(
                      'Dados simulados das APIs BACEN / AwesomeAPI', 
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30), //visual caixa
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                onPressed: () => _notificarExportacao(context),
                icon: const Icon(Icons.file_download),
                label: const Text('Exportar Relatório Mensal (CSV)'),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// (componente reutilizável - desenho dos quadradinhos)

class CartaoIndicador extends StatelessWidget {
  final IndicadorEconomico indicador;

  const CartaoIndicador({super.key, required this.indicador});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          // Opacidade da cor
          color: indicador.corTema.withValues(alpha: 0.08),
borderRadius: BorderRadius.circular(12),
border: Border.all(color: indicador.corTema.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              indicador.titulo, 
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: indicador.corTema),
            ),
            const SizedBox(height: 8),
            Text(
              indicador.valor, 
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}