public class getCoinStats_Controller {
    
    private final Coin__c coin {get; set;}
    
    // Construtor
    public getCoinStats_Controller (ApexPages.StandardController stdController) {
        this.coin = (Coin__c) stdController.getRecord();
    }
	
    // Codigo chamado ao carregar pagina
    public PageReference autoRun_getCoinStats() {

        // Armazena Id da moeda
        String recordId = ApexPages.currentPage().getParameters().get('id');

        try {
            // Se nao houver registro mostra pagina VF com msg de erro
            if (recordId == null) {            
                return null; 
            }
            
            // Busca moeda pelo Id
            Coin__c objCoin = [SELECT  ID, Name, id_api__c FROM Coin__c WHERE ID=:recordId LIMIT 1];
            
            // Chama funcao para atualizar informacoes da moeda e a salva
            objCoin = Cripto.getCoinInitialStats(objCoin);
            update objCoin;
        }
        catch(Exception e) {
            system.debug('ERROR: '+ e);
        }

        // Redireciona usuario pra pagina anterior
        PageReference pageRef = new PageReference('/' + recordId);
        pageRef.setRedirect(true);
        return pageRef;

    }
    
}