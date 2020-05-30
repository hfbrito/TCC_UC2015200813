public class Cripto {
    /* FUNÇÕES PRINCIPAIS =============================================================================================
		getCoinInitialInfo: função assincrona chamada por trigger quando nova moeda é inserida;
		getCoinInitialStats: chamada ao inserir moeda e ao atualizar dados da moeda;
		getAllCoinsMarketData: chamado ao atualizar dados pelo list view
		CallApi_AllCoinsMarketData: função auxiliar de getAllCoinsMarketData
	*/
    
    // Execucao assincrona
	@future(callout=true)
    public static void getCoinInitialInfo (String coinSymbol){

        // Obtem por API a lista completa de moedas
        HttpResponse response = callRestApi('https://api.coingecko.com/api/v3/coins/list');
        
        // Converte o JSON recebido em uma lista
        List<Object> results = (List<Object>) JSON.deserializeUntyped(response.getBody());
        
        for ( Object obj : results ) {

            // Transforma o objeto atual em um Map (chave, valor);
            Map<String, Object> coin = (Map<String, Object>)obj;

            // Se a chave symbol possuir valor igual a sigla passada pra funcao
            if( coin.get('symbol') == coinSymbol ){
                
                // Busca a nova moeda inserida
                Coin__c objCoin = [SELECT  ID, Name FROM Coin__c WHERE Name=:coinSymbol LIMIT 1];
                
                // Converte valores em string
                String coinId = String.valueOf(coin.get('id'));
                String coinName = String.valueOf(coin.get('name'));

                // Atualiza moeda com campos retornados na API
                objCoin.id_api__c = coinId;
                objCoin.Nome_da_Moeda__c = coinName;
                objCoin.Name = objCoin.Name.toUpperCase();

                // Chama outra API para retornar dados especificos da moeda
                objCoin = getCoinInitialStats(objCoin);

                // Atualiza registro e sai do loop
                update objCoin;
                break;
            }
        }
    }
    

    public static Coin__c getCoinInitialStats (Coin__c coin){
        // Obtem por API as demais informacoes da moeda
        HttpResponse response = callRestApi('https://api.coingecko.com/api/v3/coins/'+coin.id_api__c+
                                            '?localization=false&tickers=false&market_data=true&community_data=false&developer_data=false&sparkline=false');
        
        // Converte o resultado em map e salva as informacoes em variaveis
        Map<String,Object> results = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
        
        String nome = (String) results.get('name');
        String rDesc = (String) ((Map<String,Object>) results.get('description')).get('en');
        String imgURL = (String) ((Map<String,Object>) results.get('image')).get('large');
        Map<String,Object> mapMarket_data = (Map<String,Object>) results.get('market_data');
            Decimal current_price = (Decimal) ((Map<String,Object>) mapMarket_data.get('current_price')).get('brl');
            Decimal ath = (Decimal) ((Map<String,Object>) mapMarket_data.get('ath')).get('brl');
            Date ath_date = Date.valueOf( jsonToDatetime(((Map<String,Object>) mapMarket_data.get('ath_date')).get('brl')) );
            Decimal atl = (Decimal) ((Map<String,Object>) mapMarket_data.get('atl')).get('brl');
            Date atl_date = Date.valueOf( jsonToDatetime(((Map<String,Object>) mapMarket_data.get('atl_date')).get('brl')) );
            Decimal var24hs = (Decimal) mapMarket_data.get('price_change_percentage_24h');
            Decimal var7d = (Decimal) mapMarket_data.get('price_change_percentage_7d');
            Decimal var30d = (Decimal) mapMarket_data.get('price_change_percentage_30d');
            Decimal var1ano = (Decimal) mapMarket_data.get('price_change_percentage_1y');
        String website = (String) ((List<Object>) ((Map<String,Object>) results.get('links')).get('homepage')).get(0);
        
        // Atualiza os campos na moeda passada como parametro e a retorna
        coin.Nome_da_Moeda__c = nome;
        coin.Descricao__c = rDesc;
        coin.Preco__c = current_price;
        coin.ath__c = ath;
        coin.ath_date__c = ath_date;
        coin.atl__c = atl;
        coin.atl_date__c = atl_date;
        
        coin.Custom_Icon_URL__c = imgURL;
        coin.Website__c = website;
        coin.Var_24hs__c = var24hs;
        coin.Var_7d__c = var7d;
        coin.Var_30d__c = var30d;
        coin.Var_1Ano__c = var1ano;
        coin.last_updated__c = System.now();
        
        return coin;
    }
    

    public static void getAllCoinsMarketData (List<Coin__c> coinList){
        
        Integer count = 0;    
        String apiParams = '';
        List<Coin__c> newCoinList = new List<Coin__c>();
        Map<String, Coin__c> oldCoinsMap = new Map<String, Coin__c>();

        // Converte a lista passada como parametro em map ('Id da Api', 'objeto Moeda')
        for ( Coin__c coin : coinList ) {
            oldCoinsMap.put(coin.id_api__c, coin);
        }
        
        // Prepara variavel com moedas e chama API
        for ( Coin__c coin : coinList ) {
            
            // Adiciona moeda na string usada como argumento para a chamada a API
            apiParams += coin.id_api__c +'%2C';
        	count++;
            
            // Se chegar no limite da API (100 moedas por vez) chama a API e reseta contador
            if (count >= 99){ 
                count = 0;
                // Remove ultimo '%2C', que nao deve estar presente na URL
                apiParams = apiParams.substring(0, apiParams.length()-3); 
                // Chama API passando as moedas na variavel e salva numa lista o retorno
                newCoinList.addAll( CallApi_AllCoinsMarketData(apiParams) );
                // Limpa string
                apiParams = '';
            }
        }

		// Se na ultima iteração houveram menos de 100 moedas, chama a API
        if(count > 0 && apiParams != null){
            // Remove ultimo '%2C', que nao deve estar presente na URL
            apiParams = apiParams.substring(0, apiParams.length()-3);
            // Chama API passando as moedas na variavel e salva numa lista o retorno
       		newCoinList.addAll( CallApi_AllCoinsMarketData(apiParams) );
        }

        // Atualiza moedas retornadas com o Id da moeda na base
        for (Coin__c newCoin : newCoinList){

            // Pra cada moeda retornada com atualizacoes, verifica se na lista passada ha chave correspondente a uma moeda no map
			if( oldCoinsMap.containsKey(newCoin.id_api__c) ) {

                // Se houver, insere Id da moeda na base para permitir a atualizacao 
				Coin__c oldCoin = oldCoinsMap.get(newCoin.id_api__c);
                newCoin.ID = oldCoin.id;

        	}  
        }

        // Atualiza na base todas as moedas presentes na lista
        update newCoinList;
    }
    

    public static List<Coin__c> CallApi_AllCoinsMarketData (String apiParams){
        // Inicializa lista para guardar moedas atualizadas
        List<Coin__c> updatedList = new List<Coin__c>();
        
        // Chama API para retornar as informacoes das moedas no parametro e converte o retorno em lista de objetos
        HttpResponse response = callRestApi('https://api.coingecko.com/api/v3/coins/markets?vs_currency=brl&ids='+apiParams+'&order=market_cap_desc&per_page=100&page=1&sparkline=false&price_change_percentage=24h%2C7d%2C30d%2C1y');

        List<Object> results = (List<Object>) JSON.deserializeUntyped(response.getBody());
        
        // Converte cada objeto retornado da API em moeda e o salva na lista
        for ( Object obj : results ) {
            // Converte este objeto em map
            Map<String, Object> coin = (Map<String, Object>) obj;

            // Inicializa objeto de moeda vazio e o preenche com os campos retornados
            Coin__c c = new Coin__c();
            c.Nome_da_Moeda__c = (String) coin.get('name');
            c.id_api__c = (String) coin.get('id');
            c.Preco__c = (Decimal) coin.get('current_price');
            c.Var_24hs__c = (Decimal) coin.get('price_change_percentage_24h_in_currency');
            c.Var_7d__c = (Decimal) coin.get('price_change_percentage_7d_in_currency');
            c.Var_30d__c = (Decimal) coin.get('price_change_percentage_30d_in_currency');
            c.Var_1Ano__c = (Decimal) coin.get('price_change_percentage_1y_in_currency');
            c.Custom_Icon_URL__c = (String) coin.get('image');
            c.last_updated__c = System.now();
            //c.Nome_da_Moeda__c = (String) coin.get('name'); //opcional
            
            // Guarda na lista a moeda atualizada
            updatedList.add(c);
        }
        
        // Retorna lista com todas as moedas retornadas pela API
    	return updatedList;
    }
    
    
    /* FUNÇÕES UTILITÁRIAS =============================================================================================
		callRestApi: recebe endpoint de API e retorna a resposta;
		jsonToDatetime: converte objeto em DateTime e o retorna;
    */
     
    public static HttpResponse callRestApi (String endpoint){
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        return response;
    }
     
    public static DateTime jsonToDatetime (Object jsonDt){
        String dtStr = (String) '"'+ jsonDt +'"';
        DateTime dt = Datetime.valueOf( JSON.deserialize(dtStr, DateTime.class) );
        return dt;
    }
}