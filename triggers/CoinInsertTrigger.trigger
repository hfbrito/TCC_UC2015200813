trigger CoinInsertTrigger on Coin__c (before insert) {
    try {
        // Ao inserir nova moeda, chama função para preencher seus dados, passando a sigla como parametro
        Cripto.getCoinInitialInfo(Trigger.new[0].Name);
    }
    catch(Exception e) {
        system.debug('ERROR: '+ e);
    }
}