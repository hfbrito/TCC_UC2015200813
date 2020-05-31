public class getAllCoinStats_Controller {

    private List<Coin__c> coinList {get; set;}
    public ApexPages.StandardSetController stdControl{get; set;}
    
    // Construtor
    public getAllCoinStats_Controller(ApexPages.StandardSetController controller) {
        stdControl = controller;
        // Preenche lista somente com moedas que possuem id da API
        this.coinList = [SELECT Id, Name, id_api__c FROM Coin__c WHERE id_api__c != null];
    }

    // Codigo chamado ao carregar pagina.
    public PageReference autoRun_getAllCoinStats() {
        
        try {
            // Se nao houver registros mostra pagina VF com msg de erro
            if (this.coinList.isEmpty()) {            
                return null; 
            }
            
            // Chama funcao para atualizar informacoes das moedas
            Cripto.getAllCoinsMarketData(this.coinList);
        }
        catch(Exception e) {
            system.debug('ERROR: '+ e);
        }

        Schema.DescribeSObjectResult result = Coin__c.SObjectType.getDescribe(); 
        PageReference pageRef = new PageReference('/' + result.getKeyPrefix()); 
        pageRef.setRedirect(true); 
        return pageRef; 

        
    }
    
}