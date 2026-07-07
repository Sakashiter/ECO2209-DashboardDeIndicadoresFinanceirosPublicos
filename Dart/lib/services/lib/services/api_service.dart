import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  Future<String> buscarDolar() async {
    final url = Uri.parse(
      'https://economia.awesomeapi.com.br/json/last/USD-BRL',
    );

    final resposta = await http.get(url);

    if (resposta.statusCode != 200) {
      throw Exception('Não foi possível buscar a cotação do dólar.');
    }

    final dados = jsonDecode(resposta.body);

    final valorDolar = double.parse(dados['USDBRL']['bid']);

    return 'R\$ ${valorDolar.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}